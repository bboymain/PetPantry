-- Click pet portrait (or press the keybind) = cast Feed Pet on the highest-priority food in your bags.
-- Any other click keeps the frame's normal "*typeN" action (target / menu).
local FEED_PET = 6991
local CLICKS = { -- label, modifier prefix, mouse button
    {"Left-click", "", "1"},
    {"Right-click", "", "2"},
    {"Shift + Left-click", "shift-", "1"},
    {"Ctrl + Left-click", "ctrl-", "1"},
    {"Alt + Left-click", "alt-", "1"},
}
local THEMES = {
    {name = "Forever", bg = {0.04, 0.06, 0.125, 1}, card = {0.06, 0.09, 0.18, 1}, btn = {0.07, 0.11, 0.2, 1},
        hot = {0.12, 0.2, 0.36, 1}, border = {0.165, 0.29, 0.5}, title = {1, 0.82, 0.3}, accent = {0.4, 0.867, 1},
        text = {0.85, 0.9, 1}, dim = {0.5, 0.6, 0.75}},
    {name = "Obsidian", bg = {0.05, 0.05, 0.06, 1}, card = {0.08, 0.08, 0.09, 1}, btn = {0.11, 0.11, 0.12, 1},
        hot = {0.22, 0.18, 0.07, 1}, border = {0.25, 0.25, 0.27}, title = {1, 0.82, 0}, accent = {1, 0.82, 0},
        text = {0.9, 0.9, 0.9}, dim = {0.55, 0.55, 0.55}},
    {name = "Teal", bg = {0.06, 0.06, 0.07, 1}, card = {0.09, 0.09, 0.1, 1}, btn = {0.13, 0.13, 0.15, 1},
        hot = {0.1, 0.24, 0.23, 1}, border = {0.2, 0.2, 0.23}, title = {0.3, 0.8, 0.75}, accent = {0.3, 0.8, 0.75},
        text = {0.95, 0.95, 0.96}, dim = {0.55, 0.57, 0.6}},
    {name = "Crimson", bg = {0.08, 0.03, 0.03, 1}, card = {0.12, 0.04, 0.04, 1}, btn = {0.16, 0.05, 0.05, 1},
        hot = {0.32, 0.08, 0.06, 1}, border = {0.4, 0.12, 0.1}, title = {1, 0.82, 0.3}, accent = {1, 0.4, 0.3},
        text = {1, 0.9, 0.88}, dim = {0.7, 0.5, 0.48}},
}
local MOODS = {"|cffff4033Unhappy|r", "|cffffd24dContent|r", "|cff4dff4dHappy|r"}
local MAX_FOODS = 10

-- Shuffle-bag random: every line in a list plays once before any line repeats.
-- The pet's own noise by family, used wherever a line says {noise}.
-- ponytail: English family names only; other client languages get the generic noise.
local NOISES = {
    Wolf = "*howls*", Cat = "*purrs*", Bear = "*growls*", Boar = "*snorts*", Spider = "*clicks mandibles*",
    Raptor = "*screeches*", Bat = "*squeaks*", Owl = "*hoots*", Crab = "*clacks claws*", Gorilla = "*beats chest*",
    Turtle = "*slowly blinks*", Crocolisk = "*snaps jaws*", Hyena = "*cackles*", Scorpid = "*clicks pincers*",
    ["Carrion Bird"] = "*caws*", ["Wind Serpent"] = "*hisses*", Tallstrider = "*squawks*",
}
local function petNoise()
    return NOISES[UnitCreatureFamily("pet") or ""] or "*makes happy pet noises*"
end

local bags = {}
local function pick(lines)
    local bag = bags[lines]
    if not bag or #bag == 0 then
        bag = {}
        for i = 1, #lines do bag[i] = lines[i] end
        for i = #bag, 2, -1 do
            local j = math.random(i)
            bag[i], bag[j] = bag[j], bag[i]
        end
        bags[lines] = bag
    end
    return (tremove(bag):gsub("{noise}", petNoise()))
end
local CHATTER = { -- what your pet "says" in the card, by mood
    [1] = {
        "I could eat a murloc. Raw.",
        "Feed me or I walk.",
        "*stomach growls loudly*",
        "Is that jerky? Please.",
        "I've started eyeing your boots.",
        "Hunger level: Onyxia.",
        "I'd eat a Defias Pillager right now. Armor and all.",
        "You eat. I watch. This is abuse.",
        "*chews on your quiver*",
        "One more fight on an empty stomach and I'm joining the Horde. Or the Alliance. Whoever feeds me.",
        "My loyalty is dropping. Just saying.",
        "I dreamt of Roasted Quail again.",
    },
    [2] = {
        "A snack wouldn't hurt.",
        "I'm fine. Mostly.",
        "Could go for a bite.",
        "*sniffs your bags*",
        "I'm not hungry. I'm just... looking.",
        "Is that a Tough Jerky in your bag or are you happy to see me?",
        "Snack o'clock is approaching.",
        "I'd hunt better with a treat. Science.",
        "*stares at you. Stares at bag. Stares at you.*",
        "Content. Not thrilled. Content.",
    },
    [3] = {
        "Best hunter ever.",
        "Ready to hunt!",
        "*happy tail wag*",
        "Full belly, sharp claws.",
        "Point me at something. Anything.",
        "I'd die for you. Actually, I have. Several times.",
        "Who needs mounts when you have me?",
        "{noise} happily",
        "{noise} Let's GO!",
        "Pull the whole camp. I believe in us.",
        "Life is good. Loot is better.",
        "I'll tank this. Probably.",
        "10/10 would be tamed again.",
    },
    dead = {
        "...",
        "*needs a Revive Pet*",
        "Tell my story at the stables.",
        "I regret nothing. Except that pull.",
        "Was that the tank's job? It was, wasn't it.",
    },
    none = {
        "Your pet misses you.",
        "It's quiet without a pet.",
        "Somewhere, a stable master is feeding your pet worse food.",
        "Hunters without pets are just... rogues with bows.",
    },
}
local T = THEMES[1] -- current theme; every painter reads it at paint time
local db
local hooked, portraits, glows = {}, {}, {}
local lowWarned
local arm, onFeedClick
local armedFood -- item the next feed will use

-- Keybind target: Esc > Key Bindings > "Pet Pantry" (see Bindings.xml).
local key = CreateFrame("Button", "PetPantryButton", UIParent, "SecureActionButtonTemplate")
key:SetSize(1, 1)
key:SetPoint("TOPLEFT")
key:RegisterForClicks("AnyUp", "AnyDown") -- template acts on the one matching ActionButtonUseKeyDown
key:HookScript("PreClick", function() arm(); onFeedClick(nil, "keybind") end)
BINDING_HEADER_PETPANTRY = "Pet Pantry"
_G["BINDING_NAME_CLICK PetPantryButton:LeftButton"] = "Feed pet"

-- Combat click changes must run in WoW's secure environment.
local combat = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
combat:SetFrameRef("key", key)
combat:SetAttribute("_onstate-combat", [[
    if newstate ~= "combat" then return end
    self:GetFrameRef("key"):SetAttribute("type1", nil)
    local i = 1
    local frame = self:GetFrameRef("portrait" .. i)
    while frame do
        frame:SetAttribute("type1", nil)
        frame:SetAttribute("type2", nil)
        frame:SetAttribute("shift-type1", nil)
        frame:SetAttribute("ctrl-type1", nil)
        frame:SetAttribute("alt-type1", nil)
        i = i + 1
        frame = self:GetFrameRef("portrait" .. i)
    end
]])
RegisterStateDriver(combat, "combat", "[combat] combat; peace")

local function hasPet()
    return UnitExists("pet") and not UnitIsDead("pet")
end

local function happiness() -- 1 unhappy, 2 content, 3 happy
    if not hasPet() then return end
    local h = C_PetInfo.GetPetHappiness()
    if issecretvalue and issecretvalue(h) then return end
    return h
end

local function findFood()
    if not hasPet() then return end
    for _, id in ipairs(db.foods) do
        if C_PetInfo.CanPetEatItem(id) then
            for bag = 0, NUM_BAG_SLOTS do
                for slot = 1, C_Container.GetContainerNumSlots(bag) do
                    local info = C_Container.GetContainerItemInfo(bag, slot)
                    if info and info.itemID == id and not info.isLocked then return bag, slot, id end
                end
            end
        end
    end
end

-- Our own sounds (generated for this addon), respecting the player's SFX volume.
local SOUND_DIR = "Interface\\AddOns\\PetPantry\\Sounds\\"
local function sound(name)
    if db and db.sounds then PlaySoundFile(SOUND_DIR .. name .. ".ogg", "SFX") end
end

local MILESTONES = { -- meals -> title the pet earns
    {10, "Snacker"}, {50, "Foodie"}, {100, "Gourmet"}, {250, "Glutton"},
    {500, "Bottomless Pit"}, {1000, "Legend of the Feast"},
}
local function petTitle(meals)
    local title
    for _, m in ipairs(MILESTONES) do
        if meals >= m[1] then title = m[2] end
    end
    return title
end

-- Not "GetPetExperience and GetPetExperience()": `and` keeps only the first return, losing nextXP.
local function petXP()
    if GetPetExperience then return GetPetExperience() end
end

local function itemIcon(id)
    return select(5, C_Item.GetItemInfoInstant(id))
end

local function setFeed(f, prefix, btn, bag, slot)
    f:SetAttribute(prefix .. "type" .. btn, bag and "spell" or nil) -- nil falls back to "*typeN"
    f:SetAttribute(prefix .. "spell" .. btn, FEED_PET)
    f:SetAttribute(prefix .. "target-bag" .. btn, bag)
    f:SetAttribute(prefix .. "target-slot" .. btn, slot)
end

---------------------------------------------------------------- Hungry glow
local function updateGlow()
    local h = db.glow and happiness()
    for _, g in ipairs(glows) do
        if h == 1 or h == 2 then
            g:SetVertexColor(1, h == 1 and 0.1 or 0.6, 0) -- red unhappy, orange content
            g:Show(); g.pulse:Play()
        else
            g:Hide(); g.pulse:Stop()
        end
    end
end

local function addGlow(f)
    local g = f:CreateTexture(nil, "OVERLAY")
    g:SetAllPoints()
    g:SetColorTexture(1, 1, 1, 0.35)
    g:SetBlendMode("ADD")
    g:Hide()
    g.pulse = g:CreateAnimationGroup()
    g.pulse:SetLooping("BOUNCE")
    local a = g.pulse:CreateAnimation("Alpha")
    a:SetFromAlpha(1); a:SetToAlpha(0.2); a:SetDuration(0.8)
    tinsert(glows, g)
end

---------------------------------------------------------------- Portrait tooltip
local function addTooltip(f)
    if InCombatLockdown() or not hasPet() then return end
    if not GameTooltip:IsShown() then GameTooltip:SetOwner(f, "ANCHOR_RIGHT") end
    GameTooltip:AddLine(" ")
    local _, _, id = findFood()
    if db.skipHappy and happiness() == 3 then
        GameTooltip:AddLine("Pet is Happy - not feeding", unpack(T.dim))
    elseif id then
        GameTooltip:AddLine(CLICKS[db.click][1] .. " to feed:", unpack(T.title))
        GameTooltip:AddLine("|T" .. itemIcon(id) .. ":14|t " .. (C_Item.GetItemInfo(id) or ("item " .. id))
            .. "  x" .. C_Item.GetItemCount(id), unpack(T.text))
    else
        GameTooltip:AddLine("No listed pet food in your bags (/pfeed)", 1, 0.4, 0.4)
    end
    local xp, nextXP = petXP()
    if nextXP and nextXP > 0 then
        GameTooltip:AddLine(("Pet XP: %d / %d (%d%%)"):format(xp, nextXP, xp / nextXP * 100), unpack(T.dim))
    end
    GameTooltip:Show()
end

---------------------------------------------------------------- Low food warning
local function checkLowFood()
    if not hasPet() or db.warnAt < 1 then return end
    local total = 0
    for _, id in ipairs(db.foods) do
        if C_PetInfo.CanPetEatItem(id) then total = total + C_Item.GetItemCount(id) end
    end
    if total < db.warnAt and not lowWarned then
        print("|cffffd24dPet Pantry:|r only " .. total .. " pet food left!")
    end
    lowWarned = total < db.warnAt
end

---------------------------------------------------------------- Arming
-- Protected attributes can only change out of combat; re-read bags on every click.
arm = function()
    if InCombatLockdown() or not db then return end
    for _, name in ipairs({"PetFrame", "EllesmereUIUnitFrames_Pet"}) do
        local f = _G[name]
        if f and not hooked[f] then
            hooked[f] = true
            tinsert(portraits, f)
            combat:SetFrameRef("portrait" .. #portraits, f)
            f:HookScript("PreClick", arm)
            f:HookScript("PreClick", function(...) onFeedClick(...) end)
            f:HookScript("OnEnter", addTooltip)
            addGlow(f)
        end
    end
    local bag, slot, id = findFood()
    armedFood = id
    if db.skipHappy and happiness() == 3 then bag, slot = nil, nil end
    for _, f in ipairs(portraits) do
        for i, c in ipairs(CLICKS) do
            if i == db.click then setFeed(f, c[2], c[3], bag, slot) else setFeed(f, c[2], c[3]) end
        end
    end
    setFeed(key, "", "1", bag, slot)
end

---------------------------------------------------------------- UI (drawn in code, no external art)
local WHITE = "Interface\\Buttons\\WHITE8x8"

-- Every themed element registers a painter; switching theme just re-runs them all.
local painters = {}
local function paint(fn)
    tinsert(painters, fn)
    fn()
end

local function box(f, role)
    f:SetBackdrop({bgFile = WHITE, edgeFile = WHITE, edgeSize = 1})
    paint(function()
        f:SetBackdropColor(unpack(T[role]))
        f:SetBackdropBorderColor(unpack(T.border))
    end)
end

local function colorTex(tex, role, alpha)
    paint(function()
        local c = T[role]
        tex:SetColorTexture(c[1], c[2], c[3], alpha or 1)
    end)
end

-- Vector glyphs from rotated 2px lines: {length, angle, x, y}
local d = math.pi / 4
local GLYPHS = {
    x = {{11, d, 0, 0}, {11, -d, 0, 0}},
    up = {{7, d, -2.5, 0}, {7, -d, 2.5, 0}},
    down = {{7, -d, -2.5, 0}, {7, d, 2.5, 0}},
}

-- Hover = accent border + accent text/glyph + lighter fill.
local function flatButton(parent, w, h, glyph, onClick)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(w, h)
    b:SetBackdrop({bgFile = WHITE, edgeFile = WHITE, edgeSize = 1})
    b:SetNormalFontObject("GameFontHighlightSmall")
    b.parts = {}
    for _, g in ipairs(GLYPHS[glyph] or {}) do
        local t = b:CreateTexture(nil, "ARTWORK")
        t:SetColorTexture(1, 1, 1)
        t:SetSize(g[1], 2)
        t:SetPoint("CENTER", g[3], g[4])
        t:SetRotation(g[2])
        tinsert(b.parts, t)
    end
    function b.tint()
        local c = b.hover and T.accent or T.text
        b:SetBackdropColor(unpack(b.hover and T.hot or T.btn))
        b:SetBackdropBorderColor(unpack(b.hover and T.accent or T.border))
        for _, t in ipairs(b.parts) do t:SetVertexColor(unpack(c)) end
        local fs = b:GetFontString()
        if fs then fs:SetTextColor(unpack(c)) end
    end
    b:SetScript("OnEnter", function() b.hover = true; b.tint() end)
    b:SetScript("OnLeave", function() b.hover = false; b.tint() end)
    b:SetScript("OnClick", onClick)
    paint(b.tint)
    return b
end

local ui = CreateFrame("Frame", "PetPantryUI", UIParent, "BackdropTemplate")
ui:SetSize(300, 722)
ui:SetPoint("TOP", 0, -100) -- top-anchored so the window grows downward
ui:Hide()
box(ui, "bg")
ui:SetMovable(true)
ui:EnableMouse(true)
ui:SetClampedToScreen(true)
ui:RegisterForDrag("LeftButton")
ui:SetScript("OnDragStart", ui.StartMoving)
ui:SetScript("OnDragStop", ui.StopMovingOrSizing)
tinsert(UISpecialFrames, "PetPantryUI") -- Esc closes it

local function label(parent, text, point, x, y, font, role)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    fs:SetPoint(point, x, y)
    fs:SetText(text)
    paint(function() fs:SetTextColor(unpack(T[role or "text"])) end)
    return fs
end

-- Faint drumstick filling the whole list area edge to edge, fading out toward the top (anchored after the settings block exists)
local mark = ui:CreateTexture(nil, "BACKGROUND", nil, 2)
mark:SetTexture("Interface\\Icons\\INV_Misc_Food_14")
mark:SetTexCoord(0.08, 0.92, 0.08, 0.92)
mark:SetGradient("VERTICAL", CreateColor(1, 1, 1, 0.12), CreateColor(1, 1, 1, 0))

-- Header: gradient bar with a glowing accent line underneath
local header = ui:CreateTexture(nil, "BACKGROUND", nil, 1)
header:SetColorTexture(1, 1, 1)
paint(function()
    local a, b = T.btn, T.hot
    header:SetGradient("VERTICAL", CreateColor(a[1], a[2], a[3], 1), CreateColor(b[1], b[2], b[3], 1))
end)
header:SetPoint("TOPLEFT", 1, -1)
header:SetPoint("TOPRIGHT", -1, -1)
header:SetHeight(31)
label(ui, "Pet Pantry", "TOPLEFT", 12, -10, "GameFontNormal", "title")
flatButton(ui, 20, 20, "x", function() ui:Hide() end):SetPoint("TOPRIGHT", -6, -6)
local line = ui:CreateTexture(nil, "ARTWORK")
colorTex(line, "accent")
line:SetHeight(1)
line:SetPoint("TOPLEFT", 1, -32)
line:SetPoint("TOPRIGHT", -1, -32)
local glow = ui:CreateTexture(nil, "ARTWORK")
glow:SetColorTexture(1, 1, 1)
paint(function()
    local c = T.accent
    glow:SetGradient("VERTICAL", CreateColor(c[1], c[2], c[3], 0), CreateColor(c[1], c[2], c[3], 0.3))
end)
glow:SetHeight(8)
glow:SetPoint("TOPLEFT", line, "BOTTOMLEFT")
glow:SetPoint("TOPRIGHT", line, "BOTTOMRIGHT")

-- Pet card: portrait | name, mood, level + family | next meal
local card = CreateFrame("Frame", nil, ui, "BackdropTemplate")
card:SetPoint("TOPLEFT", 10, -42)
card:SetPoint("TOPRIGHT", -10, -42)
card:SetHeight(66)
box(card, "card")
local pFrame = CreateFrame("Frame", nil, card, "BackdropTemplate")
pFrame:SetSize(52, 52)
pFrame:SetPoint("LEFT", 6, 0)
pFrame:SetBackdrop({edgeFile = WHITE, edgeSize = 1})
paint(function() pFrame:SetBackdropBorderColor(unpack(T.accent)) end)
local portrait = pFrame:CreateTexture(nil, "ARTWORK")
portrait:SetPoint("TOPLEFT", 1, -1)
portrait:SetPoint("BOTTOMRIGHT", -1, 1)
local petName = label(card, "", "TOPLEFT", 66, -9, "GameFontNormal", "title")
petName:SetPoint("RIGHT", -52, 0)
petName:SetJustifyH("LEFT")
local petInfo = label(card, "", "TOPLEFT", 66, -26, nil, "dim")
petInfo:SetPoint("RIGHT", -52, 0)
petInfo:SetJustifyH("LEFT")
local chatter = label(card, "", "TOPLEFT", 66, -44, nil, "text")
chatter:SetPoint("RIGHT", -52, 0)
chatter:SetJustifyH("LEFT")
local lastMood

-- Trying to feed a pet that's already Happy gets you sass instead of silence.
local STUFFED = { -- "Don't feed when Happy" is on, so nothing gets eaten
    "I'm stuffed. Seriously.",
    "One more bite and I explode.",
    "*turns away from the food dramatically*",
    "Hunter, I am FULL. Respect the belly.",
    "Do I look hungry? Don't answer that.",
    "*lies down and plays dead*",
    "Wafer-thin mint? No. NO.",
    "I'm not a garbage disposal, I'm a companion.",
    "Save it for later. Or for the warlock's imp.",
    "My belly has reached max level.",
    "If I eat that I'll need a bigger hitbox.",
    "Food? Again? I'm too full to even growl.",
    "*unbuckles belt it doesn't have*",
    "Stop. I already can't fit through doors.",
    "Are you gonna eat me later? I'm already full.",
    "I can't help you, I'm in a food coma.",
    "*barfs a little bit* Uh... no.",
    "Are you fattening me up for something? Be honest.",
    "I've eaten so much I can see my own aggro radius.",
    "Not now, I'm digesting. It's a full-time job.",
    "*burps loudly* ...excuse me. No.",
    "Put it in the bank. I'll eat it next expansion.",
    "My stomach just filed a complaint.",
    "If you feed me again, I'm legally a mount.",
    "I physically cannot. My legs don't reach the ground anymore.",
    "Is this a feeding or an intervention?",
    "*waddles away slowly*",
    "No. Nope. Stomach's closed. Come back tomorrow.",
    "I'm so full I'm seeing Roasted Quail when I close my eyes.",
    "Hunter, I love you, but I will throw up on your boots.",
}
local FORCED = { -- the setting is off, so the food goes down anyway
    "*chews reluctantly*",
    "Fine. FINE. But I'm not happy about it. Well, I am. That's the problem.",
    "*food coma intensifies*",
    "You're going to need a bigger stable.",
    "This is how pets become mounts.",
    "*eats it anyway, glares at you*",
    "Don't expect me to run after this.",
    "I will remember this at the next wipe.",
    "Next time, feed the tank.",
}
-- Themed speech bubble, by default just above your character; floats up and fades.
-- Movable: Settings > Speech bubble > Move (position saved per character).
local bubble = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
bubble:SetFrameStrata("HIGH")
bubble:Hide()
bubble:SetMovable(true)
bubble:SetClampedToScreen(true)
bubble:RegisterForDrag("LeftButton")
bubble:SetScript("OnDragStart", bubble.StartMoving)
local function placeBubble()
    bubble:ClearAllPoints()
    bubble:SetPoint("BOTTOM", UIParent, "CENTER", db.bubbleX, db.bubbleY)
end
bubble:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    db.bubbleX = self:GetCenter() - UIParent:GetWidth() / 2
    db.bubbleY = self:GetBottom() - UIParent:GetHeight() / 2
    placeBubble()
end)
box(bubble, "card")
paint(function() bubble:SetBackdropBorderColor(unpack(T.accent)) end)
local bubbleName = label(bubble, "", "TOP", 0, -7, "GameFontNormalSmall", "title")
local bubbleText = label(bubble, "", "TOP", 0, -21, "GameFontHighlight", "text")
local pop = bubble:CreateAnimationGroup()
local fadeIn = pop:CreateAnimation("Alpha")
fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.2)
local fadeOut = pop:CreateAnimation("Alpha")
fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0); fadeOut:SetStartDelay(2.8); fadeOut:SetDuration(0.6)
local rise = pop:CreateAnimation("Translation")
rise:SetOffset(0, 24); rise:SetDuration(3.4)
pop:SetScript("OnFinished", function() bubble:Hide() end)

-- Share pet lines with other players. Addons can't auto-send /say or /yell outdoors,
-- but emotes and group chat are allowed. Throttled so it never floods chat.
local SHARE = {"Off", "Emote (nearby)", "Party / Raid"}
local SHARE_EVERY = 15 -- seconds between shared lines
local lastShared = 0
local EMOTE_FRAMES = { -- "Nami <frame>" in chat
    "translates for %s: %s",
    "nods as %s says: %s",
    "hears %s mutter: %s",
    "glances at %s, who says: %s",
    "pats %s, who replies: %s",
    "sighs as %s announces: %s",
    "listens to %s's commentary: %s",
    "rolls their eyes. %s says: %s",
}
local function shareChat(text)
    if db.share == 1 or GetTime() - lastShared < SHARE_EVERY then return end
    local channel
    if db.share == 2 then
        channel = "EMOTE"
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        channel = "INSTANCE_CHAT"
    elseif IsInRaid() then
        channel = "RAID"
    elseif IsInGroup() then
        channel = "PARTY"
    end
    if not channel then return end
    lastShared = GetTime()
    C_ChatInfo.SendChatMessage(text, channel)
end

local function fitBubble(name, line)
    bubbleName:SetText(name)
    bubbleText:SetText(line)
    bubble:SetSize(math.max(bubbleText:GetStringWidth(), bubbleName:GetStringWidth()) + 28, 44)
end

local bubbleUnlocked = false
local function say(name, line)
    if not bubbleUnlocked then
        fitBubble(name, line)
        -- Longer lines stay up longer: ~4s minimum, +1s per 20 characters.
        local hold = math.max(4, 2.5 + #line / 20)
        fadeOut:SetStartDelay(hold)
        rise:SetDuration(hold + 0.6)
        pop:Stop()
        bubble:Show()
        pop:Play()
    end
    -- Bubble first, chat second: a chat hiccup can never stop you from seeing the line.
    shareChat(db.share == 2 and pick(EMOTE_FRAMES):format(name, line) or (name .. ": " .. line))
end

local function setBubbleUnlocked(on)
    bubbleUnlocked = on
    pop:Stop()
    bubble:EnableMouse(on)
    if on then
        fitBubble("Speech bubble", "Drag me anywhere, then click Done")
        bubble:SetAlpha(1)
        bubble:Show()
    else
        bubble:Hide()
    end
end

local lastJoke = 0
onFeedClick = function(_, button)
    if InCombatLockdown() or happiness() ~= 3 or GetTime() - lastJoke < 3 then return end
    local c = CLICKS[db.click]
    local mods = (IsAltKeyDown() and "alt-" or "") .. (IsControlKeyDown() and "ctrl-" or "")
        .. (IsShiftKeyDown() and "shift-" or "")
    local isFeedClick = button == "keybind"
        or (mods == c[2] and button == (c[3] == "1" and "LeftButton" or "RightButton"))
    if not isFeedClick then return end
    lastJoke = GetTime()
    local lines = db.skipHappy and STUFFED or FORCED
    local line = pick(lines)
    say(UnitName("pet"), '"' .. line .. '"')
    chatter:SetText('"' .. line .. '"')
end

local YUM = {
    "%s! *nom nom*",
    "Mmm, %s!",
    "*devours the %s*",
    "%s? My favorite!",
    "*crunch* ...%s. Delicious.",
    "%s! You DO love me.",
    "5 stars. Would eat %s again.",
    "*inhales the %s whole*",
    "Ahh, %s. Just like mom used to hunt.",
    "%s! Worth every copper you didn't pay.",
}
local VENDOR = {
    "Ooh! They sell snacks here!",
    "Buy the food. Buy ALL the food.",
    "I smell snacks. Don't pretend you don't.",
    "Hunter. HUNTER. Look at the menu.",
    "This vendor gets my vote.",
}
local function announceMeal(id)
    if not db.announce or not id or GetTime() - lastJoke < 1 then return end -- a joke already spoke
    local line = pick(YUM):format(C_Item.GetItemInfo(id) or "food")
    say(UnitName("pet"), '"' .. line .. '"')
    chatter:SetText('"' .. line .. '"')
end

-- On opening a vendor: list the food it sells that your current pet eats.
-- Combat chatter: automatic lines when the pet gets low, dies, or gets healed back up.
local LOW = {
    "I'm seeing a white light. Is that Mend Pet?",
    "Hunter, this is where you press Mend Pet.",
    "Tis but a scratch! ...several scratches.",
    "Why am I tanking?! I'm a pet!",
    "Feign Death?! Can I do that too?!",
    "If I die, I'm haunting your bank.",
    "My health bar is looking VERY red.",
    "I didn't sign up for this. I was TAMED.",
    "Remember me as I was: fluffy.",
    "Not the face! Not the face!",
    "Tell the Stable Master... I loved him.",
    "Heal me or I'm eating your hearthstone.",
    "Is it too late to be a warlock's pet?",
    "Pulling aggro was YOUR job!",
    "I can see my whole tamed life flashing before my eyes.",
    "Remember when you fed me that Tough Jerky? Good times.",
    "This is fine. Everything is fine. *is on fire*",
    "Quick, Feign Death! No wait, that only saves YOU.",
    "Mend Pet. Mend Pet! MEND. PET.",
    "Can we talk about my hazard pay?",
    "Is this the part where you Feign Death and leave me? AGAIN?",
    "I'd like to speak to the Stable Master.",
    "Should I be seeing double? I'm seeing double.",
    "Bite harder, they said. It'll be fun, they said.",
    "I'm too loyal for this.",
    "Plot twist: I'M the one who needs Revive Pet.",
    "Somebody call a Druid!",
    "Low health, high spirits! Mostly low health.",
    "Hey! Hey! Your pet is dying over here!",
    "I'll just... lie down for a sec.",
    "Wait, whose side is the healer on?",
    "Oh no. Oh no no no no.",
    "*whimpers in a way that's somehow still adorable*",
    "My last snack better not have been jerky.",
}
local DEATH = {
    "Worth it.",
    "Avenge meeeee...",
    "Tell my cubs I love them.",
    "Revive Pet... costs mana, right? Right?",
    "I blame the tank.",
    "Well. That was a pull.",
    "*dramatic death noises*",
    "At least I died Happy. Well fed, even.",
    "I'll be in the spirit stable if you need me.",
    "Should've tamed a turtle.",
    "Tell the stable I died doing what I loved. Tanking. Badly.",
    "*spirit floats away, stealing one last treat*",
    "Revive me, and this time bring snacks.",
    "Death: 1. Pet: 0.",
    "I left my dinner in your bag. Don't eat it.",
    "Gah! Not like this! Not before second breakfast!",
    "My only regret... is not biting harder.",
    "I see a light... and it smells like Roasted Quail.",
    "Resurrect me in 3... 2... hello?",
    "Plz no dismiss. Revive.",
    "Guess I'm a ghost pet now. Boo.",
    "*falls over dramatically, one paw twitching*",
}
local RELIEF = {
    "Phew. Thanks for the heal.",
    "I'm back, baby!",
    "Mend Pet is my love language.",
    "That was totally on purpose.",
    "Nobody saw that. Nobody.",
    "I wasn't scared. You were scared.",
    "Did someone call a vet? Oh wait, that was you.",
    "Healed and hungry. Snack break?",
    "Okay, NOW I'm angry.",
    "Round two. Let's go.",
    "I meant to do that. It was a strategy.",
    "Remind me to bite that guy's ankles later.",
    "Health restored! Dignity... still pending.",
    "You DO care!",
}
local LOW_AT, SAFE_AT = 0.25, 0.6 -- ponytail: fixed thresholds; make them settings if anyone asks
local wasLow, wasDead, lastCombatLine = false, false, 0
local function petHealth()
    if not db.combatTalk or not UnitExists("pet") then return end
    local hp, max = UnitHealth("pet"), UnitHealthMax("pet")
    if issecretvalue and (issecretvalue(hp) or issecretvalue(max)) then return end -- client hides it: stay quiet
    if max == 0 then return end
    local pct = hp / max
    local lines
    if UnitIsDead("pet") or hp == 0 then
        if not wasDead then lines = DEATH end
        wasDead, wasLow = true, false
    elseif pct <= LOW_AT then
        if not wasLow and GetTime() - lastCombatLine > 8 then lines = LOW end
        wasLow, wasDead = true, false
    elseif pct >= SAFE_AT then
        if wasLow then lines = RELIEF end
        wasLow, wasDead = false, false
    end
    if not lines then return end
    if lines == LOW then sound("whimper") end
    lastCombatLine = GetTime()
    local line = pick(lines)
    say(UnitName("pet"), '"' .. line .. '"')
    chatter:SetText('"' .. line .. '"')
end

-- Milestone toast: drops in near the top of the screen with a fanfare.
local toast = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
toast:SetFrameStrata("HIGH")
toast:SetSize(290, 58)
toast:SetPoint("TOP", 0, -150)
toast:Hide()
box(toast, "card")
paint(function() toast:SetBackdropBorderColor(unpack(T.title)) end)
local tIconEdge = CreateFrame("Frame", nil, toast, "BackdropTemplate")
tIconEdge:SetSize(42, 42)
tIconEdge:SetPoint("LEFT", 8, 0)
tIconEdge:SetBackdrop({edgeFile = WHITE, edgeSize = 1})
paint(function() tIconEdge:SetBackdropBorderColor(unpack(T.title)) end)
local tIcon = tIconEdge:CreateTexture(nil, "ARTWORK")
tIcon:SetPoint("TOPLEFT", 1, -1)
tIcon:SetPoint("BOTTOMRIGHT", -1, 1)
tIcon:SetTexture("Interface\\Icons\\INV_Misc_Food_14")
tIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
label(toast, "MILESTONE", "TOPLEFT", 60, -8, "GameFontNormalSmall", "dim")
local tLine1 = label(toast, "", "TOPLEFT", 60, -22, "GameFontNormal", "title")
local tLine2 = label(toast, "", "TOPLEFT", 60, -39, nil, "text")
local toastAnim = toast:CreateAnimationGroup()
local tIn = toastAnim:CreateAnimation("Alpha")
tIn:SetFromAlpha(0); tIn:SetToAlpha(1); tIn:SetDuration(0.3)
local tDrop = toastAnim:CreateAnimation("Translation")
tDrop:SetOffset(0, -12); tDrop:SetDuration(0.3)
local tOut = toastAnim:CreateAnimation("Alpha")
tOut:SetFromAlpha(1); tOut:SetToAlpha(0); tOut:SetStartDelay(4.5); tOut:SetDuration(0.8)
toastAnim:SetScript("OnFinished", function() toast:Hide() end)

local function showMilestone(name, meals, title)
    tLine1:SetText(name .. " reached " .. meals .. " meals!")
    tLine2:SetText("Title unlocked: " .. name .. " the " .. title)
    toastAnim:Stop()
    toast:Show()
    toastAnim:Play()
    sound("fanfare")
    shareChat(db.share == 2 and ("celebrates! " .. name .. " reached " .. meals .. " meals and is now " .. name .. " the " .. title .. "!")
        or (name .. " reached " .. meals .. " meals and is now " .. name .. " the " .. title .. "!"))
end

-- Idle chatter: out of combat, the pet pipes up every few minutes (randomized so it feels alive).
local IDLE = {
    "Are we there yet?",
    "I smell a rare spawn. Probably.",
    "*chases own tail*",
    "Can we go fishing? You fish, I eat.",
    "That murloc looked at me funny.",
    "Is it snack time? It feels like snack time.",
    "*sniffs the air suspiciously*",
    "I'm bored. Pull something.",
    "You've been staring at your bags for a while.",
    "Remember when I was level 1? Good times.",
    "*yawns*",
    "I could take that guy. Just saying.",
    "Let's go bother some gnolls.",
    "Do you ever think about the Stable Master? Me neither.",
    "*digs a hole for no reason*",
    "If you go AFK, I'm eating the jerky.",
    "I think I saw a gold coin over there.",
    "Best pet on this server. Confirm?",
    "*rolls over for belly rubs*",
    "Ready when you are. Dungeon? Also ready. Probably.",
    "Did you hear that? ...Me neither. Let's hunt anyway.",
    "I'm not saying I'm hungry, but I'm hungry.",
    "{noise}",
    "{noise} ...sorry, wrong emote.",
    "Is that a quest giver? Don't talk to them. They'll make us kill 10 boars.",
    "Your mount gets more attention than me.",
    "Pretty sure that bush moved.",
    "I don't want to alarm you, but I think we're lost.",
    "*sniffs a flower, sneezes*",
    "One day I'll get my own action bar.",
    "Do the guards know I'm a good pet? Tell the guards.",
    "Rate my stance: 10/10 alert.",
}
-- Extra idle lines per family (mixed in ~35% of the time when your pet's family has some).
local FAMILY_IDLE = {
    Wolf = {"Can I pee on that Defias? Just once?", "The moon is out. I'm legally required to howl.", "*chases a squirrel into the next zone*"},
    Cat = {"I knocked your hearthstone off a table. Not sorry.", "If I fits, I sits. Your bag. I fits.", "*stares at nothing for three minutes*"},
    Bear = {"Hibernation is just a long AFK. Can we?", "Honey. Do you have honey. Anyone?", "*scratches back on a tree, sighs deeply*"},
    Boar = {"I'm not fat, I'm armored.", "*rolls in mud, looks proud*", "I just want to charge something. Anything."},
    Spider = {"I made you a web. It's in your bags now.", "Eight eyes and I still can't find the quest item.", "*clicks mandibles thoughtfully*"},
    Raptor = {"Clever girl? No. Clever pet.", "Can we go back to Stranglethorn? I miss the screaming.", "*tilts head suspiciously*"},
    Bat = {"Is it night yet? I'm a night person.", "*hangs upside down from nothing*", "Echolocation says: there's a rare over there."},
    Owl = {"Hoo? You. It's always you.", "*swivels head all the way around, just to flex*", "I know things. Owl things."},
    Crab = {"Sideways is the only way.", "*clacks at a passing murloc*", "Don't call me crabby. I'm always like this."},
    Gorilla = {"I could do this whole zone with one arm.", "*beats chest for no reason*", "Bananas. Just saying the word. Bananas."},
    Turtle = {"Slow and steady wins the... wait, where'd everyone go?", "*retreats into shell, emerges, retreats again*", "I'm basically a tank. A slow tank."},
    Crocolisk = {"I've been told I have a lovely smile.", "*snaps at a butterfly, misses*", "Swim break? Swim break."},
    Hyena = {"Hehehe. Nothing's funny. Hehehe.", "*cackles at your armor choices*", "I found a bone. It's yours now. Or mine."},
    Scorpid = {"I'm not poisonous. I'm spicy.", "*waves stinger menacingly at a rabbit*", "Pinch first, ask questions never."},
    ["Carrion Bird"] = {"Is that guy dying? Asking for a friend.", "*circles above something dead*", "I call dibs on the next corpse."},
    ["Wind Serpent"] = {"I'm technically a noodle with wings.", "*crackles with static, zaps your hair*", "Lightning Breath? More like Lightning Breakfast."},
    Tallstrider = {"My legs are fine. They're just long.", "*high-steps through the grass*", "Mulgore misses me. I can feel it."},
}
local IDLE_MINS = {0, 2, 5, 10, 15} -- 0 = off
local nextIdle = 0
C_Timer.NewTicker(20, function()
    if not db or db.idleMins == 0 or not hasPet() or InCombatLockdown() or UnitOnTaxi("player") then
        nextIdle = 0
        return
    end
    local now = GetTime()
    if nextIdle == 0 or now >= nextIdle then
        local fire = nextIdle ~= 0 -- first pass only schedules, so it never talks right after login
        nextIdle = now + db.idleMins * 60 * (0.7 + math.random() * 0.6)
        if not fire then return end
        local fam = FAMILY_IDLE[UnitCreatureFamily("pet") or ""]
        local line = pick(fam and math.random() < 0.35 and fam or IDLE)
        say(UnitName("pet"), '"' .. line .. '"')
        chatter:SetText('"' .. line .. '"')
    end
end)

local function vendorAlert()
    if not db.vendor or not hasPet() then return end
    local found = {}
    for i = 1, GetMerchantNumItems() do
        local id = GetMerchantItemID(i)
        if id and C_PetInfo.CanPetEatItem(id) then
            local info = C_MerchantFrame.GetItemInfo(i)
            local price = info and info.price
            tinsert(found, (GetMerchantItemLink(i) or "?") .. (price and (" " .. GetCoinTextureString(price)) or ""))
        end
    end
    if #found == 0 then return end
    print("|cffffd24dPet Pantry:|r " .. UnitName("pet") .. " eats: " .. table.concat(found, ", "))
    say(UnitName("pet"), '"' .. pick(VENDOR) .. '"')
end
label(card, "NEXT", "TOPRIGHT", -12, -10, "GameFontNormalSmall", "dim")
local nFrame = CreateFrame("Frame", nil, card, "BackdropTemplate")
nFrame:SetSize(28, 28)
nFrame:SetPoint("TOPRIGHT", -9, -24)
nFrame:SetBackdrop({edgeFile = WHITE, edgeSize = 1})
paint(function() nFrame:SetBackdropBorderColor(unpack(T.border)) end)
local nextIcon = nFrame:CreateTexture(nil, "ARTWORK")
nextIcon:SetPoint("TOPLEFT", 1, -1)
nextIcon:SetPoint("BOTTOMRIGHT", -1, 1)
nextIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
local nextCount = nFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
nextCount:SetPoint("BOTTOMRIGHT", -1, 2)

-- New line only when the mood changes (or the window opens), so it doesn't flicker on every bag update.
local function setChatter(mood)
    local lines = CHATTER[mood]
    if not lines then chatter:SetText("") return end
    if mood ~= lastMood then
        lastMood = mood
        chatter:SetText('"' .. pick(lines) .. '"')
    end
end

-- XP bar under the card: gradient fill that glides to its value, glowing spark at the tip,
-- a shine sweeping across every few seconds, and a floating "+N XP" when the pet earns some.
local target, lastXP, lastNext = 0, nil, nil
local xpFrame = CreateFrame("Frame", nil, ui, "BackdropTemplate")
xpFrame:SetPoint("TOPLEFT", card, "BOTTOMLEFT", 0, -6)
xpFrame:SetPoint("TOPRIGHT", card, "BOTTOMRIGHT", 0, -6)
xpFrame:SetHeight(16)
box(xpFrame, "btn")
local xpBar = CreateFrame("StatusBar", nil, xpFrame)
xpBar:SetPoint("TOPLEFT", 1, -1)
xpBar:SetPoint("BOTTOMRIGHT", -1, 1)
xpBar:SetStatusBarTexture(WHITE)
xpBar:SetMinMaxValues(0, 1)
xpBar:SetValue(0)
local fill = xpBar:GetStatusBarTexture()
paint(function()
    local c = T.accent
    fill:SetGradient("HORIZONTAL", CreateColor(c[1] * 0.35, c[2] * 0.35, c[3] * 0.35, 1), CreateColor(c[1], c[2], c[3], 1))
end)

local spark = xpBar:CreateTexture(nil, "OVERLAY")
spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
spark:SetBlendMode("ADD")
spark:SetSize(16, 30)
spark:SetPoint("CENTER", fill, "RIGHT", 0, 0)

-- Shine lives in a frame the size of the fill that clips it, so it never sweeps over the empty part.
local clip = CreateFrame("Frame", nil, xpBar)
clip:SetPoint("TOPLEFT")
clip:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT")
clip:SetClipsChildren(true)
local shineHolder = CreateFrame("Frame", nil, clip)
shineHolder:SetAllPoints(xpBar)
local shine = shineHolder:CreateTexture(nil, "OVERLAY")
shine:SetColorTexture(1, 1, 1)
shine:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0), CreateColor(1, 1, 1, 0.45))
shine:SetSize(40, 14)
shine:SetPoint("RIGHT", shineHolder, "LEFT")
local sweep = shine:CreateAnimationGroup()
sweep:SetLooping("REPEAT")
local move = sweep:CreateAnimation("Translation")
move:SetOffset(320, 0)
move:SetDuration(1.4)
move:SetStartDelay(2.5)

local xpLeft = xpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
xpLeft:SetPoint("LEFT", 6, 0)
xpLeft:SetShadowOffset(1, -1)
local xpRight = xpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
xpRight:SetPoint("RIGHT", -6, 0)
xpRight:SetShadowOffset(1, -1)
paint(function() xpLeft:SetTextColor(unpack(T.title)); xpRight:SetTextColor(unpack(T.text)) end)

local gain = ui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
gain:SetPoint("BOTTOMRIGHT", xpFrame, "TOPRIGHT", -4, 2)
paint(function() gain:SetTextColor(unpack(T.title)) end)
gain:SetAlpha(0)
local gainAnim = gain:CreateAnimationGroup()
local gUp = gainAnim:CreateAnimation("Translation")
gUp:SetOffset(0, 18); gUp:SetDuration(1.4)
local gIn = gainAnim:CreateAnimation("Alpha")
gIn:SetFromAlpha(0); gIn:SetToAlpha(1); gIn:SetDuration(0.15)
local gOut = gainAnim:CreateAnimation("Alpha")
gOut:SetFromAlpha(1); gOut:SetToAlpha(0); gOut:SetStartDelay(0.9); gOut:SetDuration(0.5)

local flash = xpBar:CreateTexture(nil, "OVERLAY", nil, 2)
flash:SetAllPoints(fill)
flash:SetColorTexture(1, 1, 1, 0.5)
flash:SetBlendMode("ADD")
flash:SetAlpha(0)
local flashAnim = flash:CreateAnimationGroup()
local fOut = flashAnim:CreateAnimation("Alpha")
fOut:SetFromAlpha(1); fOut:SetToAlpha(0); fOut:SetDuration(0.6)

xpFrame:SetScript("OnShow", function() lastXP = nil end) -- no giant "+XP" for gains made while closed

-- Glide toward the target instead of jumping.
xpBar:SetScript("OnUpdate", function(self, elapsed)
    local v = self:GetValue()
    if math.abs(target - v) > 0.001 then
        self:SetValue(v + (target - v) * math.min(1, elapsed * 5))
    end
    spark:SetShown(self:GetValue() > 0.01 and self:GetValue() < 0.99)
end)

local function drawXP()
    xpFrame:SetShown(UnitExists("pet"))
    if not UnitExists("pet") then sweep:Stop() return end
    if InCombatLockdown() then return end -- keep the last value; pet data can be hidden mid-fight
    xpLeft:SetText("Lvl " .. UnitLevel("pet"))
    local xp, nextXP = petXP()
    if type(xp) ~= "number" or type(nextXP) ~= "number" then
        target = 0
        xpRight:SetText("|cff808080XP not available|r")
        return
    end
    if not sweep:IsPlaying() then sweep:Play() end
    if nextXP == 0 then -- max level
        target = 1
        xpRight:SetText("MAX")
        return
    end
    if lastXP and nextXP == lastNext and xp > lastXP then
        gain:SetText("+" .. (xp - lastXP) .. " XP")
        gainAnim:Stop(); gainAnim:Play()
        flashAnim:Stop(); flashAnim:Play()
    elseif lastNext and nextXP ~= lastNext then
        xpBar:SetValue(0) -- leveled up: refill from empty
    end
    lastXP, lastNext = xp, nextXP
    target = xp / nextXP
    xpRight:SetText(("%s / %s  |cffffffff%d%%|r"):format(BreakUpLargeNumbers(xp), BreakUpLargeNumbers(nextXP), target * 100))
end

local function loyaltyText() -- e.g. "Loyalty Level 3 (Faithful)" -> "Faithful"
    local l = C_PetInfo.GetPetLoyalty()
    return l and ("  |cff808080" .. (l:match("%((.-)%)") or l) .. "|r") or ""
end

local function drawCard()
    if InCombatLockdown() then return end -- pet/bag info can be restricted in combat
    if UnitExists("pet") then
        SetPortraitTexture(portrait, "pet", true) -- true = square, no round mask
        portrait:SetTexCoord(0, 1, 0, 1)
        local title = petTitle(db.meals[UnitName("pet")] or 0)
        petName:SetText(UnitName("pet") .. (title and (" the " .. title) or "") .. loyaltyText())
        local h = happiness()
        local mood = UnitIsDead("pet") and "|cff999999Dead|r" or MOODS[h] or ""
        local meals = db.meals[UnitName("pet")] or 0
        petInfo:SetText(mood .. "  Lvl " .. UnitLevel("pet") .. " " .. (UnitCreatureFamily("pet") or "")
            .. "  |cff808080" .. meals .. (meals == 1 and " meal" or " meals") .. "|r")
        setChatter(UnitIsDead("pet") and "dead" or h)
    else
        portrait:SetTexture("Interface\\Icons\\Ability_Hunter_BeastCall")
        portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        petName:SetText("No pet out")
        petInfo:SetText("Call your pet to feed it")
        setChatter("none")
    end
    local _, _, id = findFood()
    nextIcon:SetTexture(id and itemIcon(id) or "Interface\\Icons\\INV_Misc_QuestionMark")
    nextIcon:SetDesaturated(not id)
    nextCount:SetText(id and C_Item.GetItemCount(id) or "")
end

label(ui, "FOOD PRIORITY", "TOPLEFT", 12, -142, "GameFontNormalSmall", "title")
label(ui, "Top is eaten first. Only listed food is used.", "TOPLEFT", 12, -156, nil, "dim")

local rows = {}
local render

local function move(i, dir)
    local j = i + dir
    if j < 1 or j > #db.foods then return end
    db.foods[i], db.foods[j] = db.foods[j], db.foods[i]
    render(); arm()
end

-- ponytail: fixed 10 rows, no scrolling; add a ScrollBox if anyone needs 10+ foods
for i = 1, MAX_FOODS do
    local r = CreateFrame("Frame", nil, ui)
    r:SetSize(276, 25)
    r:SetPoint("TOPLEFT", 12, -174 - (i - 1) * 26)
    if i % 2 == 1 then
        local stripe = r:CreateTexture(nil, "BACKGROUND")
        stripe:SetAllPoints()
        colorTex(stripe, "accent", 0.05)
    end
    r.num = label(r, "", "LEFT", 4, 0, "GameFontNormalSmall", "title")
    local edge = r:CreateTexture(nil, "ARTWORK")
    colorTex(edge, "border")
    edge:SetSize(21, 21)
    edge:SetPoint("LEFT", 20, 0)
    r.icon = r:CreateTexture(nil, "OVERLAY")
    r.icon:SetSize(19, 19)
    r.icon:SetPoint("CENTER", edge)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- crop the old-style icon border
    r.text = label(r, "", "LEFT", 48, 0)
    r.text:SetPoint("RIGHT", -104, 0)
    r.text:SetJustifyH("LEFT")
    r.count = label(r, "", "RIGHT", -72, 0, nil, "dim")
    flatButton(r, 20, 20, "x", function() tremove(db.foods, i); render(); arm() end):SetPoint("RIGHT", -2, 0)
    flatButton(r, 20, 20, "down", function() move(i, 1) end):SetPoint("RIGHT", -24, 0)
    flatButton(r, 20, 20, "up", function() move(i, -1) end):SetPoint("RIGHT", -46, 0)
    rows[i] = r
end

-- Adds every bag item the current pet will eat, highest item level first.
local function addFromBags()
    if not hasPet() then print("|cffffd24dPet Pantry:|r call your pet first.") return end
    local new = {}
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            local id = info and info.itemID
            if id and not tContains(db.foods, id) and not tContains(new, id) and C_PetInfo.CanPetEatItem(id) then
                tinsert(new, id)
            end
        end
    end
    table.sort(new, function(a, b)
        return (select(4, C_Item.GetItemInfo(a)) or 0) > (select(4, C_Item.GetItemInfo(b)) or 0)
    end)
    local added = 0
    for _, id in ipairs(new) do
        if #db.foods < MAX_FOODS then tinsert(db.foods, id); added = added + 1 end
    end
    print("|cffffd24dPet Pantry:|r added " .. added .. " food" .. (added == 1 and "" or "s") .. ".")
    render(); arm()
end
-- Sits right under the last food row, like an "add row" line; hidden when the list is full.
local addBtn = flatButton(ui, 276, 22, nil, addFromBags)
addBtn:SetText("+ Add food from bags")
addBtn.tint()

local empty = label(ui, "...or drag food from your bags into this window", "TOP", 0, -202, nil, "dim")

-- Settings: a block that sits under the food list, so the window grows/shrinks with the list.
local LIST_TOP, ROW_H, LIST_PAD, SET_H = 174, 26, 14, 392 -- SET_H = settings + footer height
local set = CreateFrame("Frame", nil, ui)
set:SetPoint("LEFT")
set:SetPoint("RIGHT")
set:SetHeight(SET_H)
local setLine = set:CreateTexture(nil, "ARTWORK")
colorTex(setLine, "border")
setLine:SetHeight(1)
setLine:SetPoint("TOPLEFT", 1, 0)
setLine:SetPoint("TOPRIGHT", -1, 0)
label(set, "SETTINGS", "TOPLEFT", 12, -12, "GameFontNormalSmall", "title")

local function cycle(i, n, mouse)
    return (i + (mouse == "RightButton" and -2 or 0)) % n + 1
end

local applyTheme
label(set, "Theme", "TOPLEFT", 12, -38)
local themeBtn = flatButton(set, 140, 22, nil, function(_, mouse)
    db.theme = cycle(db.theme, #THEMES, mouse)
    applyTheme()
end)
themeBtn:SetPoint("TOPRIGHT", -12, -32)
themeBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp") -- right-click cycles backwards

label(set, "Portrait click", "TOPLEFT", 12, -66)
local clickBtn = flatButton(set, 140, 22, nil, function(_, mouse)
    db.click = cycle(db.click, #CLICKS, mouse)
    render(); arm()
end)
clickBtn:SetPoint("TOPRIGHT", -12, -60)
clickBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

local toggles = {}
local function toggleRow(text, y, field, onChange)
    label(set, text, "TOPLEFT", 12, y - 3)
    local t = CreateFrame("Button", nil, set, "BackdropTemplate")
    t:SetSize(34, 18)
    t:SetPoint("TOPRIGHT", -12, y)
    t:SetBackdrop({bgFile = WHITE, edgeFile = WHITE, edgeSize = 1})
    t.knob = t:CreateTexture(nil, "ARTWORK")
    t.knob:SetSize(12, 12)
    function t.draw()
        local on = db and db[field]
        t.knob:ClearAllPoints()
        t.knob:SetPoint(on and "RIGHT" or "LEFT", on and -3 or 3, 0)
        t.knob:SetColorTexture(unpack(on and T.title or T.dim))
        t:SetBackdropColor(unpack(on and T.hot or T.btn))
        t:SetBackdropBorderColor(unpack(t.hover and T.accent or T.border))
    end
    t:SetScript("OnClick", function() db[field] = not db[field]; t.draw(); onChange() end)
    t:SetScript("OnEnter", function() t.hover = true; t.draw() end)
    t:SetScript("OnLeave", function() t.hover = false; t.draw() end)
    paint(t.draw)
    tinsert(toggles, t)
end
toggleRow("Glow portrait when hungry", -91, "glow", updateGlow)
toggleRow("Don't feed when pet is Happy", -119, "skipHappy", function() arm() end)
toggleRow("Pet announces its meals", -147, "announce", function() end)
toggleRow("Tell me when vendors sell pet food", -175, "vendor", function() end)
toggleRow("Pet talks in combat (low health, death)", -203, "combatTalk", function() end)
toggleRow("Sounds (munch, whimper, fanfare)", -231, "sounds", function() sound("crunch") end)

label(set, "Idle chatter", "TOPLEFT", 12, -262)
local idleBtn = flatButton(set, 140, 22, nil, function(_, mouse)
    local i = tIndexOf(IDLE_MINS, db.idleMins) or 1
    db.idleMins = IDLE_MINS[cycle(i, #IDLE_MINS, mouse)]
    nextIdle = 0
    render()
end)
idleBtn:SetPoint("TOPRIGHT", -12, -256)
idleBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

label(set, "Share lines in chat", "TOPLEFT", 12, -290)
local shareBtn = flatButton(set, 140, 22, nil, function(_, mouse)
    db.share = cycle(db.share, #SHARE, mouse)
    render()
end)
shareBtn:SetPoint("TOPRIGHT", -12, -284)
shareBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

label(set, "Speech bubble", "TOPLEFT", 12, -318)
local moveBtn = flatButton(set, 66, 22, nil, function(self)
    setBubbleUnlocked(not bubbleUnlocked)
    render()
end)
moveBtn:SetPoint("TOPRIGHT", -86, -312)
local resetBtn = flatButton(set, 70, 22, nil, function()
    db.bubbleX, db.bubbleY = 0, 110
    placeBubble()
end)
resetBtn:SetPoint("TOPRIGHT", -12, -312)
resetBtn:SetText("Reset")
resetBtn.tint()

label(set, "Warn when food below (0 = off)", "TOPLEFT", 12, -346)
local warnBox = CreateFrame("EditBox", nil, set, "BackdropTemplate")
warnBox:SetSize(44, 20)
warnBox:SetPoint("TOPRIGHT", -12, -342)
box(warnBox, "btn")
warnBox:SetFontObject("GameFontHighlightSmall")
paint(function() warnBox:SetTextColor(unpack(T.text)) end)
warnBox:SetJustifyH("CENTER")
warnBox:SetAutoFocus(false)
warnBox:SetNumeric(true)
warnBox:SetMaxLetters(3)
local function saveWarn(self)
    db.warnAt = self:GetNumber()
    lowWarned = nil
    self:SetBackdropBorderColor(unpack(T.border))
    self:ClearFocus()
end
warnBox:SetScript("OnEnterPressed", saveWarn)
warnBox:SetScript("OnEscapePressed", saveWarn)
warnBox:SetScript("OnEditFocusLost", saveWarn)
warnBox:SetScript("OnEditFocusGained", function(self) self:SetBackdropBorderColor(unpack(T.accent)) end)

-- Footer credit
local footLine = ui:CreateTexture(nil, "ARTWORK")
colorTex(footLine, "border")
footLine:SetHeight(1)
footLine:SetPoint("BOTTOMLEFT", 1, 24)
footLine:SetPoint("BOTTOMRIGHT", -1, 24)
label(ui, "Made with |cffff6680<3|r by Matt", "BOTTOM", 0, 8, nil, "dim")

render = function()
    local n = #db.foods
    for i, r in ipairs(rows) do
        local id = db.foods[i]
        r:SetShown(id ~= nil)
        if id then
            r.num:SetText(i)
            r.icon:SetTexture(itemIcon(id))
            r.text:SetText(C_Item.GetItemInfo(id) or ("item " .. id))
            r.count:SetText("x" .. C_Item.GetItemCount(id))
        end
    end
    addBtn:ClearAllPoints()
    if n == 0 then addBtn:SetPoint("TOPLEFT", 12, -174) else addBtn:SetPoint("TOPLEFT", rows[n], "BOTTOMLEFT", 0, -4) end
    addBtn:SetShown(n < MAX_FOODS)
    empty:SetShown(n == 0)
    local listBottom = n == 0 and 214 or LIST_TOP + n * ROW_H - 1 + (n < MAX_FOODS and 26 or 0)
    local setTop = listBottom + LIST_PAD
    set:SetPoint("TOP", 0, -setTop)
    ui:SetHeight(setTop + SET_H)
    -- Drumstick fills the list area; crop it from the top so it never squashes.
    local f = math.min(1, (setTop - 136) / 298)
    mark:SetTexCoord(0.08, 0.92, 0.92 - 0.84 * f, 0.92)
    themeBtn:SetText(T.name)
    clickBtn:SetText(CLICKS[db.click][1])
    idleBtn:SetText(db.idleMins == 0 and "Off" or ("Every ~" .. db.idleMins .. " min"))
    shareBtn:SetText(SHARE[db.share])
    moveBtn:SetText(bubbleUnlocked and "Done" or "Move")
    moveBtn.tint()
    themeBtn.tint(); clickBtn.tint(); idleBtn.tint(); shareBtn.tint()
    for _, t in ipairs(toggles) do t.draw() end
    warnBox:SetNumber(db.warnAt)
    drawCard()
    drawXP()
end
mark:ClearAllPoints()
mark:SetPoint("TOPLEFT", ui, "TOPLEFT", 1, -136)
mark:SetPoint("BOTTOMRIGHT", set, "TOPRIGHT", -1, 0)

applyTheme = function()
    T = THEMES[db.theme]
    for _, p in ipairs(painters) do p() end
    render()
end

local function addFromCursor()
    local kind, id = GetCursorInfo()
    if kind ~= "item" then return end
    ClearCursor()
    if not tContains(db.foods, id) and #db.foods < MAX_FOODS then tinsert(db.foods, id) end
    render(); arm()
end
ui:SetScript("OnReceiveDrag", addFromCursor)
ui:SetScript("OnMouseUp", addFromCursor)
ui:SetScript("OnShow", function() lastMood = nil; render() end)
ui:SetScript("OnHide", function() if bubbleUnlocked then setBubbleUnlocked(false) end end)

---------------------------------------------------------------- Minimap button (drag to move around the edge)
local mm = CreateFrame("Button", "PetPantryMinimapButton", Minimap)
mm:SetSize(31, 31)
mm:SetFrameStrata("MEDIUM")
mm:SetFrameLevel(8)
mm:RegisterForDrag("LeftButton")
mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local mmBg = mm:CreateTexture(nil, "BACKGROUND")
mmBg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
mmBg:SetSize(20, 20)
mmBg:SetPoint("TOPLEFT", 7, -5)
local mmIcon = mm:CreateTexture(nil, "ARTWORK")
mmIcon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastTraining")
mmIcon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
mmIcon:SetSize(17, 17)
mmIcon:SetPoint("TOPLEFT", 7, -6)
local mmRing = mm:CreateTexture(nil, "OVERLAY")
mmRing:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
mmRing:SetSize(53, 53)
mmRing:SetPoint("TOPLEFT")

local function placeMinimap()
    local a = math.rad(db.minimapAngle)
    local r = Minimap:GetWidth() / 2 + 5
    mm:ClearAllPoints()
    mm:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end
mm:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local s = Minimap:GetEffectiveScale()
        db.minimapAngle = math.deg(math.atan2(cy / s - my, cx / s - mx))
        placeMinimap()
    end)
end)
mm:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
mm:SetScript("OnClick", function() ui:SetShown(not ui:IsShown()) end)
mm:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddDoubleLine("Pet Pantry", "by Matt", T.title[1], T.title[2], T.title[3], unpack(T.dim))
    GameTooltip:AddLine("Click to open. Drag to move.", unpack(T.dim))
    GameTooltip:Show()
end)
mm:SetScript("OnLeave", function() GameTooltip:Hide() end)

---------------------------------------------------------------- Events
local ev = CreateFrame("Frame")
for _, e in ipairs({"PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED", "UNIT_PET",
    "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "GET_ITEM_INFO_RECEIVED"}) do
    ev:RegisterEvent(e)
end
for _, e in ipairs({"UNIT_HAPPINESS", "UNIT_PORTRAIT_UPDATE", "UNIT_LEVEL"}) do ev:RegisterUnitEvent(e, "pet") end
ev:RegisterUnitEvent("UNIT_HEALTH", "pet")
ev:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
ev:RegisterEvent("MERCHANT_SHOW")
ev:RegisterEvent("UNIT_PET_EXPERIENCE")
ev:SetScript("OnEvent", function(_, e, unit, _, spellID)
    if e == "PLAYER_LOGIN" then
        if select(2, UnitClass("player")) ~= "HUNTER" then -- only hunters have pets to feed
            ev:UnregisterAllEvents()
            mm:Hide()
            return
        end
        PetPantryDB = PetPantryDB or {}
        db = PetPantryDB
        db.foods = db.foods or {}
        db.click = CLICKS[db.click] and db.click or 1
        db.theme = THEMES[db.theme] and db.theme or 1
        if db.glow == nil then db.glow = true end
        if db.skipHappy == nil then db.skipHappy = true end
        if db.announce == nil then db.announce = true end
        if db.vendor == nil then db.vendor = true end
        if db.combatTalk == nil then db.combatTalk = true end
        if db.sounds == nil then db.sounds = true end
        db.idleMins = db.idleMins or 5
        db.share = SHARE[db.share] and db.share or 1 -- off by default: other players can see it
        db.bubbleX = db.bubbleX or 0
        db.bubbleY = db.bubbleY or 110
        placeBubble()
        db.warnAt = db.warnAt or 10
        db.meals = db.meals or {} -- pet name -> times fed
        db.minimapAngle = db.minimapAngle or 200
        placeMinimap()
        applyTheme()
        SLASH_PETPANTRY1 = "/pfeed"
        SLASH_PETPANTRY2 = "/pantry"
        SlashCmdList.PETPANTRY = function(msg)
            if msg == "debug" then -- snapshot saved to the SavedVariables file on /reload, so nothing needs copying
                local xp, nextXP = petXP()
                local hp, hpMax = UnitHealth("pet"), UnitHealthMax("pet")
                local function plain(v) return (issecretvalue and issecretvalue(v)) and "secret" or v end
                db.debug = {
                    time = date("%Y-%m-%d %H:%M:%S"),
                    build = select(2, GetBuildInfo()),
                    pet = UnitExists("pet") and UnitName("pet") or false,
                    xp = plain(xp), nextXP = plain(nextXP),
                    loyalty = plain(C_PetInfo.GetPetLoyalty()),
                    happiness = plain(C_PetInfo.GetPetHappiness()),
                    health = plain(hp), healthMax = plain(hpMax),
                    foods = #db.foods, click = db.click, theme = db.theme,
                }
                print("|cffffd24dPet Pantry:|r debug snapshot saved. Type /reload so it gets written to disk.")
                return
            end
            ui:SetShown(not ui:IsShown())
        end
    end
    if not db then return end
    if e == "UNIT_SPELLCAST_SUCCEEDED" then
        if unit ~= "player" or spellID ~= FEED_PET or not UnitExists("pet") then return end
        local name = UnitName("pet")
        db.meals[name] = (db.meals[name] or 0) + 1
        sound("crunch")
        announceMeal(armedFood)
        for _, m in ipairs(MILESTONES) do
            if db.meals[name] == m[1] then showMilestone(name, m[1], m[2]) end
        end
    end
    if e == "MERCHANT_SHOW" then vendorAlert() return end
    if e == "UNIT_HEALTH" then petHealth() return end -- fires constantly; skip the full refresh
    if e == "PLAYER_REGEN_DISABLED" then return end -- secure state driver restores normal portrait clicks
    if ui:IsShown() then render() end
    arm()
    updateGlow()
    if e == "BAG_UPDATE_DELAYED" or e == "UNIT_PET" then checkLowFood() end
end)
