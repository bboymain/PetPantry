"""Run with Python + the already installed lupa (Lua 5.1 runtime)."""
from pathlib import Path
import unittest
import zipfile

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parent
SOURCE = (ROOT.parent / "PetPantry.lua").read_text(encoding="utf-8-sig")
MOCK = (ROOT / "wow_mock.lua").read_text(encoding="utf-8")


def client(setup="", source=SOURCE):
    lua = LuaRuntime()
    lua.execute(MOCK)
    lua.execute(setup)
    lua.execute(source, name="@Interface/AddOns/PetPantry/PetPantry.lua")
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


if __name__ == "__main__":
    unittest.main(verbosity=2)
