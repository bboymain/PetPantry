"""Run with Python + the already installed lupa (Lua 5.1 runtime)."""
from pathlib import Path
import unittest
import zipfile
import re

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parent
SOURCE = (ROOT.parent / "PetPantry.lua").read_text(encoding="utf-8-sig")
MOCK = (ROOT / "wow_mock.lua").read_text(encoding="utf-8")
LOCALES = ("enUS", "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW")


def client(setup="", source=SOURCE, translations=""):
    lua = LuaRuntime()
    lua.execute(MOCK)
    lua.execute(setup)
    namespace = lua.table()
    lua.globals().addonNS = namespace
    for name in LOCALES:
        lua.execute((ROOT.parent / f"Locales/{name}.lua").read_text(encoding="utf-8"), "PetPantry", namespace)
    lua.execute(translations)
    lua.execute(source, "PetPantry", namespace, name="@Interface/AddOns/PetPantry/PetPantry.lua")
    lua.execute('fire("PLAYER_LOGIN")')
    return lua


class ReleaseTests(unittest.TestCase):
    def test_published_bug_reproduces_exact_line(self):
        with zipfile.ZipFile(ROOT / "fixtures/PetPantry-1.0.0.zip") as archive:
            source = archive.read("PetPantry/PetPantry.lua").decode("utf-8-sig")
        lua = client(source=source)
        ok, error = lua.execute('return pcall(fire, "MERCHANT_SHOW")')
        self.assertFalse(ok)
        self.assertIn("PetPantry.lua:817: attempt to call", error)

    def test_vendor_modern_api_and_optional_results(self):
        for mode in ("price", "free", "missing", "noPrice"):
            with self.subTest(mode=mode):
                lua = client()
                lua.execute(f'state.merchant = "{mode}"; fire("MERCHANT_SHOW")')
                lua.execute('assert(hasText("Whiskers eats: item:117")); assert(hasText("item:2287"))')
                if mode in ("price", "free"):
                    self.assertTrue(lua.eval(f'hasText("copper:{25 if mode == "price" else 0}")'))
                else:
                    self.assertFalse(lua.eval('hasText("copper:")'))

    def test_vendor_disabled_or_pet_absent_or_dead(self):
        for setup in ('PetPantryDB.vendor = false', 'state.pet = false', 'state.dead = true'):
            with self.subTest(setup=setup):
                lua = client()
                lua.execute(setup + '; fire("MERCHANT_SHOW"); assert(not hasText("eats:"))')

    def test_settings_and_meals_survive_upgrade(self):
        lua = client('PetPantryDB = {foods = {2287, 117}, click = 3, theme = 2, meals = {Whiskers = 49}, share = 1}')
        lua.execute('''
            assert(PetPantryDB.foods[1] == 2287 and PetPantryDB.theme == 2)
            assert(PetFrame:GetAttribute("shift-type1") == "spell")
            assert(PetPantryButton:GetAttribute("target-slot1") == 2)
            fire("UNIT_SPELLCAST_SUCCEEDED", "player", "castGUID", 6991)
            assert(PetPantryDB.meals.Whiskers == 50)
            assert(hasText("Foodie"))
        ''')

    def test_combat_disarms_all_clicks_without_insecure_writes_and_rearms(self):
        for click, attr in ((1, "type1"), (2, "type2"), (3, "shift-type1"), (4, "ctrl-type1"), (5, "alt-type1")):
            with self.subTest(click=click):
                lua = client(f'PetPantryDB = {{foods = {{117}}, click = {click}}}')
                lua.execute(f'''
                    assert(PetFrame:GetAttribute("{attr}") == "spell")
                    combat(true)
                    assert(PetFrame:GetAttribute("{attr}") == nil)
                    assert(EllesmereUIUnitFrames_Pet:GetAttribute("{attr}") == nil)
                    assert(PetPantryButton:GetAttribute("type1") == nil)
                    assert(PetFrame:GetAttribute("*type1") == "target")
                    assert(PetFrame:GetAttribute("*type2") == "togglemenu")
                    fire("BAG_UPDATE_DELAYED")
                    PetPantryButton.scripts.PreClick(PetPantryButton, "LeftButton")
                    combat(false)
                    assert(PetFrame:GetAttribute("{attr}") == "spell")
                    assert(PetPantryButton:GetAttribute("type1") == "spell")
                ''')

    def test_happy_dead_missing_pet_or_locked_food_does_not_arm(self):
        for setup in ('state.mood = 3', 'state.pet = false', 'state.dead = true', 'state.locked = true'):
            with self.subTest(setup=setup):
                lua = client(setup + '; PetPantryDB = {foods = {117}}')
                lua.execute('assert(PetPantryButton:GetAttribute("type1") == nil)')
        lua = client('state.mood = 3; PetPantryDB = {foods = {117}, skipHappy = false}')
        lua.execute('assert(PetPantryButton:GetAttribute("type1") == "spell")')

    def test_loyalty_and_debug_use_modern_api(self):
        lua = client()
        lua.execute('''
            SlashCmdList.PETPANTRY("")
            assert(hasText("Faithful"))
            SlashCmdList.PETPANTRY("debug")
            assert(PetPantryDB.debug.loyalty == "Loyalty Level 3 (Faithful)")
            assert(PetPantryDB.debug.happiness == 2)
        ''')

    def test_xp_legacy_multiple_returns_and_unavailable(self):
        lua = client()
        lua.execute('SlashCmdList.PETPANTRY(""); assert(hasText("XP not available"))')
        lua = client('function GetPetExperience() return 250, 1000 end')
        lua.execute('SlashCmdList.PETPANTRY(""); assert(hasText("25%")); SlashCmdList.PETPANTRY("debug"); assert(PetPantryDB.debug.nextXP == 1000)')

    def test_chat_modern_api_throttle_and_default_off(self):
        lua = client()
        lua.execute('fire("MERCHANT_SHOW"); assert(#state.chat == 0)')
        lua.execute('''
            PetPantryDB.share = 2
            fire("MERCHANT_SHOW")
            assert(#state.chat == 1 and state.chat[1][2] == "EMOTE")
            fire("MERCHANT_SHOW"); assert(#state.chat == 1)
            state.now = state.now + 16
            PetPantryDB.share = 3
            function IsInGroup() return true end
            fire("MERCHANT_SHOW")
            assert(#state.chat == 2 and state.chat[2][2] == "INSTANCE_CHAT")
        ''')

    def test_unrelated_events_do_not_rescan_bags_or_rewrite_secure_bindings(self):
        lua = client('PetPantryDB = {foods = {117}}')
        lua.execute('''
            state.bagReads, state.attrWrites = 0, 0
            fire("GET_ITEM_INFO_RECEIVED", 99999, true)
            fire("UNIT_PET_EXPERIENCE")
            fire("UNIT_PORTRAIT_UPDATE", "pet")
            assert(state.bagReads == 0 and state.attrWrites == 0)
            fire("BAG_UPDATE_DELAYED")
            assert(state.bagReads > 0)
            assert(state.attrWrites == 0) -- same food/slot, no secure attribute churn
        ''')

    def test_xp_animation_does_not_run_forever(self):
        lua = client('function GetPetExperience() return 250, 1000 end')
        lua.execute('''
            SlashCmdList.PETPANTRY("")
            local bar
            for _, f in ipairs(state.frames) do
                if f.kind == "StatusBar" then bar = f end
            end
            assert(bar and bar.scripts.OnUpdate)
            for i = 1, 60 do
                if bar.scripts.OnUpdate then bar.scripts.OnUpdate(bar, 0.1) end
            end
            assert(bar.scripts.OnUpdate == nil)
            fire("UNIT_PET_EXPERIENCE")
            assert(bar.scripts.OnUpdate == nil) -- unchanged XP should stay idle
        ''')

    def test_non_hunter_stays_inactive(self):
        lua = client('state.class = "MAGE"')
        lua.execute('''
            assert(PetPantryDB == nil)
            assert(not PetPantryMinimapButton:IsShown())
            fire("MERCHANT_SHOW")
            for _, ticker in ipairs(state.tickers) do ticker() end
        ''')

    def test_health_chatter_handles_restricted_values(self):
        lua = client()
        lua.execute('''
            state.hp = 20
            fire("UNIT_HEALTH", "pet")
            state.hp = 80
            fire("UNIT_HEALTH", "pet")
            state.dead = true
            fire("UNIT_HEALTH", "pet")
            state.secret, state.hp = {}, nil
            state.hp = state.secret
            fire("UNIT_HEALTH", "pet")
            SlashCmdList.PETPANTRY("debug")
            assert(PetPantryDB.debug.health == "secret")
        ''')

    def test_idle_chatter_and_add_food_button(self):
        lua = client()
        lua.execute('''
            for _, f in ipairs(state.frames) do
                if f.text == "+ Add food from bags" then f.scripts.OnClick(f) end
            end
            assert(#PetPantryDB.foods == 2 and PetPantryDB.foods[1] == 2287)
            assert(PetPantryButton:GetAttribute("target-slot1") == 2)
            for _, fn in ipairs(state.tickers) do fn() end
            state.now = 10000
            for _, fn in ipairs(state.tickers) do fn() end
            assert(#state.chat == 0)
        ''')

    def test_locale_selection_and_untranslated_fallbacks(self):
        for locale in (*LOCALES, "enGB", "ptPT", "unknown"):
            with self.subTest(locale=locale):
                lua = client(f'state.locale = "{locale}"')
                lua.execute('SlashCmdList.PETPANTRY("")')
                self.assertEqual(lua.eval("addonNS.L.SETTINGS"), "EINSTELLUNGEN" if locale == "deDE" else "SETTINGS")
                self.assertTrue(lua.eval('hasText(addonNS.L.SETTINGS)'))
                self.assertEqual(lua.eval("addonNS.L.NO_FOOD"), "Kein aufgelistetes Begleiterfutter in deinen Taschen (/pfeed)" if locale == "deDE" else "No listed pet food in your bags (/pfeed)")
                self.assertEqual(lua.eval("addonNS.L.CHATTER[1][1]"), "Ich könnte einen Murloc fressen. Roh." if locale == "deDE" else "I could eat a murloc. Raw.")

    def test_english_fallback_for_omitted_german_entries(self):
        lua = LuaRuntime()
        lua.execute('function GetLocale() return "deDE" end')
        namespace = lua.table()
        lua.execute((ROOT.parent / "Locales/enUS.lua").read_text(encoding="utf-8"), "PetPantry", namespace)
        source = (ROOT.parent / "Locales/deDE.lua").read_text(encoding="utf-8")
        # Simulate a future untranslated label and dialogue line.
        source = re.sub(r'^L\.(?:NO_FOOD|CHATTER\[2\]\[2\]) = .*$', '', source, flags=re.MULTILINE)
        lua.execute(source, "PetPantry", namespace)
        self.assertEqual(namespace.L.NO_FOOD, "No listed pet food in your bags (/pfeed)")
        self.assertEqual(namespace.L.CHATTER[2][2], "I'm fine. Mostly.")
        self.assertEqual(namespace.L.RESET, "Zurücksetzen")

    def test_partial_dialogue_translation_and_german_family_sound(self):
        lua = client('state.locale = "deDE"; function UnitCreatureFamily() return "Katze" end', translations='''
            addonNS.L.NOISES.Cat = "*schnurrt*"
            addonNS.L.CHATTER[2][1] = "{noise} Ein Snack wäre gut."
            function math.random(n) return n and 1 or 0 end
        ''')
        lua.execute('''
            assert(hasText("*schnurrt* Ein Snack wäre gut."))
            assert(addonNS.L.CHATTER[2][2] == "Mir geht es gut. Meistens.")
            for _, family in pairs(addonNS.L.FAMILY_KEYS) do
                assert(addonNS.L.NOISES[family] and addonNS.L.FAMILY_IDLE[family])
            end
        ''')

    def test_translated_format_strings_reach_vendor_card_and_xp(self):
        lua = client('state.locale = "deDE"; function GetPetExperience() return 250, 1000 end', translations='''
            addonNS.L.LEVEL = "Stufe %d"
            addonNS.L.PET_INFO = "%s  Stufe %d %s  |cff808080%s|r"
            addonNS.L.VENDOR_FOOD = "|cffffd24dPet Pantry:|r %s frisst: %s"
            addonNS.L.MEAL_COUNT_MANY = "%d Mahlzeiten"
        ''')
        lua.execute('''
            SlashCmdList.PETPANTRY("")
            fire("MERCHANT_SHOW")
            assert(hasText("Stufe 20"))
            assert(hasText("0 Mahlzeiten"))
            assert(hasText("Whiskers frisst: item:117"))
            assert(hasText("25%"))
            assert(_G["BINDING_NAME_CLICK PetPantryButton:LeftButton"] == "Begleiter füttern")
        ''')

    def test_translation_template_completeness_and_format_safety(self):
        def flatten(table, path="L"):
            result = {}
            for key in table.keys():
                if path == "L" and key == "FAMILY_KEYS":
                    continue
                suffix = f"[{key}]" if isinstance(key, (int, float)) else (f".{key}" if key.isidentifier() else f'["{key}"]')
                value = table[key]
                if hasattr(value, "keys"):
                    result.update(flatten(value, path + suffix))
                else:
                    result[path + suffix] = value
            return result

        default = flatten(client().globals().addonNS.L)
        formatter = LuaRuntime().eval("string.format")
        for locale in LOCALES[1:]:
            catalog = flatten(client(f'state.locale = "{locale}"').globals().addonNS.L)
            self.assertEqual(set(default), set(catalog), locale)
            template = (ROOT.parent / f"Locales/{locale}.lua").read_text(encoding="utf-8")
            paths = set(re.findall(r"^(?:-- )?(L[^=\n]+?)\s*=", template, re.MULTILINE))
            for path, value in default.items():
                with self.subTest(locale=locale, path=path):
                    translated = catalog[path]
                    if isinstance(value, str):
                        self.assertIn(path, paths)
                        self.assertIsInstance(translated, str)
                        self.assertTrue(translated)
                        formats = re.findall(r"%[-+ #0]*\d*(?:\.\d+)?[cdeEfgGiouXxqs%]", value)
                        self.assertEqual(formats, re.findall(r"%[-+ #0]*\d*(?:\.\d+)?[cdeEfgGiouXxqs%]", translated))
                        self.assertEqual(value.count("{noise}"), translated.count("{noise}"))
                        self.assertEqual(re.findall(r"\|c[0-9a-fA-F]{8}|\|r", value), re.findall(r"\|c[0-9a-fA-F]{8}|\|r", translated))
                        if "%" in translated:
                            formatter(translated, *["sample" if token.endswith(("s", "q")) else 1 for token in formats if token != "%%"])
                    else:
                        self.assertEqual(value, translated)

            # Every supplied example must remain valid when a translator uncomments it.
            uncommented = re.sub(r"^-- (L[^\n]+ = )", r"\1", template, flags=re.MULTILINE)
            lua = LuaRuntime()
            lua.execute(f'function GetLocale() return "{locale}" end')
            namespace = lua.table()
            lua.execute((ROOT.parent / "Locales/enUS.lua").read_text(encoding="utf-8"), "PetPantry", namespace)
            lua.execute(uncommented, "PetPantry", namespace)
            self.assertEqual(set(default), set(flatten(namespace.L)), locale)

    def test_only_matching_locale_can_override_text(self):
        for active in (*LOCALES, "enGB", "unknown"):
            with self.subTest(locale=active):
                lua = LuaRuntime()
                lua.execute(f'function GetLocale() return "{active}" end')
                namespace = lua.table()
                lua.execute((ROOT.parent / "Locales/enUS.lua").read_text(encoding="utf-8"), "PetPantry", namespace)
                for locale in LOCALES[1:]:
                    source = (ROOT.parent / f"Locales/{locale}.lua").read_text(encoding="utf-8")
                    source += f'\nL.NEXT = "marker-{locale}"\n'
                    lua.execute(source, "PetPantry", namespace)
                self.assertEqual(namespace.L.NEXT, f"marker-{active}" if active in LOCALES[1:] else "NEXT")

    def test_feeding_and_combat_across_all_locales(self):
        for locale in LOCALES:
            with self.subTest(locale=locale):
                lua = client(f'state.locale = "{locale}"; PetPantryDB = {{foods = {{117}}, meals = {{Whiskers = 49}}}}')
                lua.execute('''
                    assert(PetPantryButton:GetAttribute("type1") == "spell")
                    assert(PetPantryButton:GetAttribute("target-slot1") == 1)
                    fire("MERCHANT_SHOW")
                    fire("UNIT_SPELLCAST_SUCCEEDED", "player", "castGUID", 6991)
                    assert(PetPantryDB.meals.Whiskers == 50)
                    combat(true)
                    fire("BAG_UPDATE_DELAYED")
                    assert(PetPantryButton:GetAttribute("type1") == nil)
                    assert(PetFrame:GetAttribute("*type1") == "target")
                    combat(false)
                    assert(PetPantryButton:GetAttribute("type1") == "spell")
                    assert(PetPantryDB.foods[1] == 117)
                ''')

    def test_toc_loads_locales_before_core(self):
        files = [line.strip().replace("\\", "/") for line in (ROOT.parent / "PetPantry.toc").read_text().splitlines() if line.strip() and not line.startswith("#")]
        self.assertEqual(files, [*(f"Locales/{locale}.lua" for locale in LOCALES), "PetPantry.lua"])
        for name in files:
            self.assertTrue((ROOT.parent / name).is_file())


if __name__ == "__main__":
    unittest.main(verbosity=2)
