-- UI calls are simulated; protected attributes reject insecure combat writes.
state = {pet = true, dead = false, mood = 2, combat = false, secure = false,
    hp = 100, maxHP = 100, now = 100, class = "HUNTER", merchant = "price",
    messages = {}, chat = {}, frames = {}, tickers = {}, drivers = {}}
unpack = unpack or table.unpack
tinsert, tremove = table.insert, table.remove
NUM_BAG_SLOTS, LE_PARTY_CATEGORY_INSTANCE = 4, 2
UISpecialFrames, SlashCmdList = {}, {}
local methods = {}
local function widget(kind, name, parent, template)
    local w = setmetatable({kind = kind, name = name, parent = parent, template = template,
        scripts = {}, attributes = {}, refs = {}, shown = true, text = "", value = 0}, {__index = methods})
    table.insert(state.frames, w)
    if name then _G[name] = w end
    return w
end
for name in ("SetPoint ClearAllPoints SetAllPoints SetBackdrop SetBackdropColor SetBackdropBorderColor " ..
    "SetColorTexture SetVertexColor SetBlendMode SetFromAlpha SetToAlpha SetDuration SetLooping " ..
    "SetTexCoord SetGradient SetRotation SetFrameStrata SetFrameLevel SetMovable EnableMouse " ..
    "SetClampedToScreen RegisterForDrag RegisterForClicks SetJustifyH SetAlpha SetOffset SetStartDelay " ..
    "SetShadowOffset SetClipsChildren SetMinMaxValues SetDesaturated SetHighlightTexture SetFontObject " ..
    "SetAutoFocus SetNumeric SetMaxLetters ClearFocus SetTextColor SetOwner StartMoving StopMovingOrSizing"):gmatch("%S+") do
    methods[name] = function() end
end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetWidth() return self.width or 300 end
function methods:GetHeight() return self.height or 100 end
function methods:GetCenter() return 100, 100 end
function methods:GetBottom() return 50 end
function methods:GetEffectiveScale() return 1 end
function methods:SetText(text) self.text = tostring(text or "") end
function methods:GetStringWidth() return #self.text * 6 end
function methods:SetNumber(n) self.number = n end
function methods:GetNumber() return self.number or 0 end
function methods:SetValue(v) self.value = v end
function methods:GetValue() return self.value end
function methods:SetScript(name, fn) self.scripts[name] = fn end
function methods:HookScript(name, fn)
    local prev = self.scripts[name]
    self.scripts[name] = function(...) if prev then prev(...) end; fn(...) end
end
function methods:SetShown(show) if show then self:Show() else self:Hide() end end
function methods:Show()
    local changed = not self.shown; self.shown = true
    if changed and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide()
    local changed = self.shown; self.shown = false
    if changed and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:IsShown() return self.shown end
function methods:Play() self.playing = true end
function methods:Stop() self.playing = false end
function methods:IsPlaying() return self.playing end
function methods:CreateTexture() return widget("Texture", nil, self) end
function methods:CreateFontString() return widget("FontString", nil, self) end
function methods:CreateAnimationGroup() return widget("AnimationGroup", nil, self) end
function methods:CreateAnimation() return widget("Animation", nil, self) end
function methods:SetNormalFontObject() self.font = self:CreateFontString() end
function methods:GetFontString() return self.font end
function methods:SetTexture(t) self.texture = t end
function methods:SetStatusBarTexture() self.fill = self:CreateTexture() end
function methods:GetStatusBarTexture() return self.fill end
function methods:SetAttribute(name, value)
    assert(not state.combat or state.secure, "insecure protected attribute write during combat: " .. name)
    self.attributes[name] = value
end
function methods:GetAttribute(name) return self.attributes[name] end
function methods:SetFrameRef(name, frame) self.refs[name] = frame end
function methods:GetFrameRef(name) return self.refs[name] end
function methods:RegisterEvent(name) self.events = self.events or {}; self.events[name] = true end
methods.RegisterUnitEvent = methods.RegisterEvent
function methods:UnregisterAllEvents() self.events = {} end
function methods:AddLine(text) table.insert(state.messages, tostring(text)) end
methods.AddDoubleLine = methods.AddLine
CreateFrame = widget
UIParent, Minimap, GameTooltip = widget("Frame"), widget("Frame"), widget("Tooltip")
PetFrame = widget("Button", "PetFrame")
PetFrame:SetAttribute("*type1", "target")
PetFrame:SetAttribute("*type2", "togglemenu")
EllesmereUIUnitFrames_Pet = widget("Button", "EllesmereUIUnitFrames_Pet")
function CreateColor(...) return {...} end
function RegisterStateDriver(frame, name, condition)
    assert(condition == "[combat] combat; peace")
    table.insert(state.drivers, {frame = frame, name = name})
end
function fire(event, ...)
    for _, frame in ipairs(state.frames) do
        if frame.events and frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, ...) end
    end
end
function combat(on)
    state.combat = on
    for _, driver in ipairs(state.drivers) do
        local env = setmetatable({self = driver.frame, newstate = on and "combat" or "peace"}, {__index = _G})
        local fn = assert(loadstring(driver.frame:GetAttribute("_onstate-" .. driver.name)))
        setfenv(fn, env)
        state.secure = true; fn(); state.secure = false
    end
    fire(on and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED")
end
function UnitClass() return state.class, state.class end
function UnitExists() return state.pet end
function UnitIsDead() return state.dead end
function UnitName() return "Whiskers" end
function UnitLevel() return 20 end
function UnitCreatureFamily() return "Cat" end
function UnitOnTaxi() return false end
function UnitHealth() return state.hp end
function UnitHealthMax() return state.maxHP end
function InCombatLockdown() return state.combat end
function GetTime() return state.now end
function issecretvalue(value) return state.secret ~= nil and value == state.secret end
function SetPortraitTexture() end
function PlaySoundFile() end
function BreakUpLargeNumbers(n) return tostring(n) end
function IsAltKeyDown() return false end
function IsControlKeyDown() return false end
function IsShiftKeyDown() return false end
function IsInGroup() return false end
function IsInRaid() return false end
function GetCursorInfo() end
function ClearCursor() end
function GetCursorPosition() return 100, 100 end
function GetBuildInfo() return "1.60.1", "70790", "", 16001 end
date = os.date
function print(...) table.insert(state.messages, table.concat({...}, " ")) end
function tContains(list, value) for _, v in ipairs(list) do if v == value then return true end end return false end
function tIndexOf(list, value) for i, v in ipairs(list) do if v == value then return i end end end
C_PetInfo = {
    CanPetEatItem = function(id) return id == 117 or id == 2287 end,
    GetPetHappiness = function() return state.mood end,
    GetPetLoyalty = function() return "Loyalty Level 3 (Faithful)" end,
}
C_Container = {
    GetContainerNumSlots = function(bag) return bag == 0 and 2 or 0 end,
    GetContainerItemInfo = function(bag, slot)
        return {itemID = slot == 1 and 117 or 2287, isLocked = state.locked}
    end,
}
C_Item = {
    GetItemInfoInstant = function() return nil, nil, nil, nil, 134414 end,
    GetItemInfo = function(id) return id == 117 and "Tough Jerky" or "Haunch of Meat", nil, 1, id == 117 and 5 or 15 end,
    GetItemCount = function() return 5 end,
}
function GetMerchantNumItems() return 3 end
function GetMerchantItemID(i) return ({117, 999, 2287})[i] end
function GetMerchantItemLink(i) return state.noLink and nil or "item:" .. GetMerchantItemID(i) end
function GetCoinTextureString(price) return "copper:" .. price end
C_MerchantFrame = {GetItemInfo = function(i)
    assert(i ~= 2, "non-food vendor item should be ignored")
    if state.merchant == "missing" then return nil end
    if state.merchant == "noPrice" then return {} end
    return {price = state.merchant == "free" and 0 or 25, stackCount = 5}
end}
C_ChatInfo = {SendChatMessage = function(text, channel) table.insert(state.chat, {text, channel}) end}
C_Timer = {NewTicker = function(_, fn) table.insert(state.tickers, fn) end}
-- Removed legacy APIs deliberately stay nil.
GetMerchantItemInfo, GetPetLoyalty, SendChatMessage, GetPetExperience = nil, nil, nil, nil

function hasText(text)
    for _, f in ipairs(state.frames) do if type(f.text) == "string" and f.text:find(text, 1, true) then return true end end
    for _, s in ipairs(state.messages) do if s:find(text, 1, true) then return true end end
    return false
end
