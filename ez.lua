--[[
    BLACKSIGIL - Anime Vanguards (Cascade UI Complete Edition)
    Trait + Banner Visual Engine - Native Fusion Edition

    This build keeps the existing visual/client-side behavior while
    replacing the hardcoded trait database with the game's MockTraits module.
]]

-- ================================
-- CASCADE UI INITIALIZATION
-- ================================
local function importRelease(owner, repo, version, file)
    local tag = (version == "latest" and "latest/download" or "download/"..version)
    local url = ("https://github.com/%s/%s/releases/%s/%s"):format(owner, repo, tag, file)
    
    local success, result = pcall(function()
        return game:HttpGetAsync(url)
    end)
    
    if not success then
        warn("Failed to fetch Cascade UI: " .. tostring(result))
        return nil
    end
    
    return loadstring(result, file)()
end

local cascade = importRelease("cascadeui", "Cascade", "latest", "dist.luau")
if not cascade then return end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterPlayer = game:GetService("StarterPlayer")
local LocalPlayer = Players.LocalPlayer

-- Set this to the raw URL hosting this BLACKSIGIL build for rejoin auto-execution.
local BLACKSIGIL_RAW_URL = "https://raw.githubusercontent.com/szty-v/chujcieto/refs/heads/main/ez.lua"
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")


local FusionPackage = ReplicatedStorage:WaitForChild("FusionPackage")
local Dependencies = require(FusionPackage:WaitForChild("Dependencies"))
local Fusion = require(FusionPackage:WaitForChild("Fusion"))
local NativeState = require(FusionPackage:WaitForChild("State"))
local NativeSlotComponent = require(FusionPackage.Components.Base.Slot)
local NodesModule = require(ReplicatedStorage:WaitForChild("Nodes"))
local OnEvent = Fusion.OnEvent
local PlayerDataState = Dependencies.PlayerData
local UnitDataState = Dependencies.UnitData
local ItemDataState = Dependencies.ItemData
local HotbarState = Dependencies.HotbarState
local BannerDataState = Dependencies.BannerData

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local SharedUtils = require(SharedFolder:WaitForChild("Utils"))

-- ================================
-- APP & WINDOW SETUP
-- ================================
local app = cascade.New({
    Name = "BLACKSIGIL",
    Theme = cascade.Themes.Dark,
    Accent = cascade.Accents.Green,
    WindowPill = true,
})

local window = app:Window({
    Title = "BLACKSIGIL",
    Subtitle = "Anime Vanguards - 2026",
    Draggable = true,
    Resizable = true,
    Searching = true,
})

-- Sidebar Sections
local visualSection = window:Section({ Title = "Visuals", Expanded = true })
local settingsSection = window:Section({ Title = "Settings", Expanded = true })

-- Tabs
local mainTab = visualSection:Tab({
    Title = "Visual Spoofing",
    Icon = cascade.Symbols.squareStack3dUp,
    Selected = true,
})

local settingsTab = settingsSection:Tab({
    Title = "Settings",
    Icon = cascade.Symbols.gear,
})

-- ================================
-- SAFE LOGGING
-- ================================
local function SafeLog(title, message)
    print(string.format("[BLACKSIGIL] %s - %s", tostring(title), tostring(message)))
end

-- ================================
-- SAFE PATH INDEXING & IMAGE HELPERS
-- ================================
local function SafeGet(parent, ...)
    local current = parent
    for _, child in ipairs({...}) do
        if not current then return nil end
        if type(child) == "number" then
            local children = current:GetChildren()
            current = children[child]
        else
            current = current:FindFirstChild(child)
        end
    end
    return current
end

local FALLBACK_IMAGE = "rbxassetid://17528233930"

local function SetSafeImage(imageLabel, imageId)
    if imageLabel and typeof(imageLabel) == "Instance" and imageLabel:IsA("ImageLabel") then
        if type(imageId) == "string" and imageId ~= "" then
            imageLabel.Image = imageId
        else
            imageLabel.Image = FALLBACK_IMAGE
        end
        for _, child in ipairs(imageLabel:GetChildren()) do
            if child:IsA("UIGradient") then
                child:Destroy()
            end
        end
    end
end

-- UI Path Directory
local UIPaths = {
    RerollMenuCount = function() return SafeGet(PlayerGui, "TraitReroll", "Frame", "Folder", "Frame", 3, "Frame", "Frame", "Frame", "TextLabel") end,
    BottomHUD_TraitCount1 = function() return SafeGet(PlayerGui, "BottomHUD", 2, 6, 5, "Frame", "TextLabel") end,
    BottomHUD_TraitCount2 = function() return SafeGet(PlayerGui, "BottomHUD", 2, 6, 4, "Frame", "TextLabel") end,
    BottomHUD_Gold = function() return SafeGet(PlayerGui, "BottomHUD", 2, 6, 3, "Frame", "TextLabel") end,
    BottomHUD_Gems = function() return SafeGet(PlayerGui, "BottomHUD", 2, 6, "Frame", "Frame", "TextLabel") end,
    TraitChance = function() return SafeGet(PlayerGui, "TraitReroll", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", 4, 5) end,
    TraitName = function() return SafeGet(PlayerGui, "TraitReroll", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", 4, "TextLabel") end,
    TraitImage = function() return SafeGet(PlayerGui, "TraitReroll", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "ImageLabel") end,
    TraitDescription = function() return SafeGet(PlayerGui, "TraitReroll", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "Frame", "Folder", "Frame", "Frame", "Frame", "TextLabel") end,
    HistoryCount = function() return SafeGet(PlayerGui, "Prompt", "Frame", "PromptWindow", "PromptWindow", "Frame", 6, 3, "Frame", 5) end,
    HistoryScroll = function() return SafeGet(PlayerGui, "Prompt", "Frame", "PromptWindow", "PromptWindow", "Frame", "Frame", "Frame", "ScrollingFrame") end,
    SummonGems = function() return SafeGet(PlayerGui, "Summon", "Frame", "Frame", "Frame", "Frame", 4, "Frame", 3, "Frame", "Frame", "Frame", "TextLabel") end,
    TraitRerollExactCount = function() return SafeGet(PlayerGui, "TraitReroll", "Frame", "Folder", "Overlay", 3, "Frame", "Frame", "Frame", "TextLabel") end,

    -- Automatic mock trait pity displays.
    DraconicTraitPityText = function() return SafeGet(PlayerGui, "TraitReroll", "Frame", "Folder", "Overlay", "ScrollingFrame", 19, "Frame", 4, "Frame", "Frame", "Frame", "Frame", 4) end,
    DraconicTraitPityBar = function() return SafeGet(PlayerGui, "TraitReroll", "Frame", "Folder", "Overlay", "ScrollingFrame", 19, "Frame", 4, "Frame", "Frame", "Frame", 2, "CanvasGroup", "Frame") end,
    ForsakenTraitPityText = function() return SafeGet(PlayerGui, "TraitReroll", "Frame", "Folder", "Overlay", "ScrollingFrame", 6, "Frame", 4, "Frame", "Frame", "Frame", "Frame", 4) end,
    ForsakenTraitPityBar = function() return SafeGet(PlayerGui, "TraitReroll", "Frame", "Folder", "Overlay", "ScrollingFrame", 6, "Frame", 4, "Frame", "Frame", "Frame", 2, "CanvasGroup", "Frame") end,
    PrimordialTraitPityText = function() return SafeGet(PlayerGui, "TraitReroll", "Frame", "Folder", "Overlay", "ScrollingFrame", "Frame", "Frame", 4, "Frame", "Frame", "Frame", "Frame", 4) end,
    PrimordialTraitPityBar = function() return SafeGet(PlayerGui, "TraitReroll", "Frame", "Folder", "Overlay", "ScrollingFrame", "Frame", "Frame", 4, "Frame", "Frame", "Frame", 2, "CanvasGroup", "Frame") end,
    UnboundTraitPityText = function() return SafeGet(PlayerGui, "TraitReroll", "Frame", "Folder", "Overlay", "ScrollingFrame", 17, "Frame", 4, "Frame", "Frame", "Frame", "Frame", 4) end,
    UnboundTraitPityBar = function() return SafeGet(PlayerGui, "TraitReroll", "Frame", "Folder", "Overlay", "ScrollingFrame", 17, "Frame", 4, "Frame", "Frame", "Frame", 2, "CanvasGroup", "Frame") end,

    -- Mock summon pity displays (display-only; no BLACKSIGIL sliders).
    LegendaryPityText = function() return SafeGet(PlayerGui, "Summon", "Frame", "Frame", "Frame", "Frame", 4, "Frame", 3, 5, 3, "Frame", "Frame", "Frame", 4) end,
    LegendaryPityBar = function() return SafeGet(PlayerGui, "Summon", "Frame", "Frame", "Frame", "Frame", 4, "Frame", 3, 5, 3, "Frame", "Frame", 2, "CanvasGroup", "Frame") end,
    MythicPityText = function() return SafeGet(PlayerGui, "Summon", "Frame", "Frame", "Frame", "Frame", 4, "Frame", 3, 5, "Frame", "Frame", "Frame", "Frame", 4) end,
    MythicPityBar = function() return SafeGet(PlayerGui, "Summon", "Frame", "Frame", "Frame", "Frame", 4, "Frame", 3, 5, "Frame", "Frame", "Frame", 2, "CanvasGroup", "Frame") end,
    SecretPityText = function() return SafeGet(PlayerGui, "Summon", "Frame", "Frame", "Frame", "Frame", 4, "Frame", 3, 5, 4, "Frame", "Frame", "Frame", 4) end,
    SecretPityBar = function() return SafeGet(PlayerGui, "Summon", "Frame", "Frame", "Frame", "Frame", 4, "Frame", 3, 5, 4, "Frame", "Frame", 2, "CanvasGroup", "Frame") end,
}

-- ================================
-- PERSISTENT MOCK STORAGE
-- ================================
local PERSISTENCE_FILE = "BLACKSIGIL_mock_state_v15.json"
local PersistedSnapshot = nil
local SavePersistentState = nil
local persistQueued = false

local function ReadPersistentSnapshot()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then
        return nil
    end

    local okExists, exists = pcall(isfile, PERSISTENCE_FILE)
    if not okExists or not exists then
        return nil
    end

    local okRead, raw = pcall(readfile, PERSISTENCE_FILE)
    if not okRead or type(raw) ~= "string" or raw == "" then
        return nil
    end

    local okDecode, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    if okDecode and type(decoded) == "table" then
        return decoded
    end

    return nil
end

local function QueuePersistentSave()
    if persistQueued then
        return
    end

    persistQueued = true
    task.defer(function()
        task.wait(0.05)
        persistQueued = false
        if SavePersistentState then
            local ok, err = pcall(SavePersistentState)
            if not ok then
                warn("[BLACKSIGIL] Persistent save failed:", err)
            end
        end
    end)
end

PersistedSnapshot = ReadPersistentSnapshot()

-- ================================
-- SPOOF STATE & TOGGLES
-- ================================
local MockUnitIDs = {}

local VisualState = _G.BLACKSIGIL_VISUAL_STATE
if type(VisualState) ~= "table" then
    VisualState = {}
end

-- Across rejoin/new execution, disk state wins over an empty/new Lua environment.
if type(PersistedSnapshot) == "table" and type(PersistedSnapshot.VisualState) == "table" then
    for key, value in pairs(PersistedSnapshot.VisualState) do
        VisualState[key] = value
    end
end

_G.BLACKSIGIL_VISUAL_STATE = VisualState

-- Preserve values across HUD/menu reconstruction or accidental script re-execution.
if VisualState.Gems == nil then VisualState.Gems = 50000 end
if VisualState.Gold == nil then VisualState.Gold = 100000 end
if VisualState.TraitRerolls == nil then VisualState.TraitRerolls = 500 end
if VisualState.RollsCount == nil then VisualState.RollsCount = 0 end
if VisualState.LastTrait == nil then VisualState.LastTrait = nil end
if type(VisualState.TraitHistory) ~= "table" then VisualState.TraitHistory = {} end
if type(VisualState.LastSummonResults) ~= "table" then VisualState.LastSummonResults = {} end
if type(VisualState.SummonHistory) ~= "table" then VisualState.SummonHistory = {} end
if type(VisualState.Pity) ~= "table" then VisualState.Pity = {} end
if VisualState.Pity.Legendary == nil then VisualState.Pity.Legendary = 0 end
if VisualState.Pity.Mythic == nil then VisualState.Pity.Mythic = 0 end
if VisualState.Pity.Secret == nil then VisualState.Pity.Secret = 0 end
if type(VisualState.TraitPity) ~= "table" then VisualState.TraitPity = {} end
if VisualState.TraitPity.Draconic == nil then VisualState.TraitPity.Draconic = 0 end
if VisualState.TraitPity.Forsaken == nil then VisualState.TraitPity.Forsaken = 0 end
if VisualState.TraitPity.Primordial == nil then VisualState.TraitPity.Primordial = 0 end
if VisualState.TraitPity.Unbound == nil then VisualState.TraitPity.Unbound = 0 end

-- Normal trait history is capped at 50 entries.
while #VisualState.TraitHistory > 50 do
    table.remove(VisualState.TraitHistory)
end

_G.AVTraitRollback = false
_G.AVSummonRollback = false

-- ================================
-- LIVE GAME MOCK TRAITS DATABASE
-- Source:
-- ReplicatedStorage.FusionPackage.Dependencies.Mock.MockTraits
-- ================================
local MockTraits = {}
local TraitDatabase = {}
local TraitByName = {}

local function ShallowCopy(source)
    local result = {}
    if type(source) == "table" then
        for key, value in pairs(source) do
            result[key] = value
        end
    end
    return result
end

local function GetMockTraitsModule()
    local fusionPackage = ReplicatedStorage:FindFirstChild("FusionPackage")
    if not fusionPackage then
        fusionPackage = ReplicatedStorage:WaitForChild("FusionPackage", 10)
    end

    local dependencies = fusionPackage and fusionPackage:FindFirstChild("Dependencies")
    if not dependencies and fusionPackage then
        dependencies = fusionPackage:WaitForChild("Dependencies", 10)
    end

    local mockFolder = dependencies and dependencies:FindFirstChild("Mock")
    if not mockFolder and dependencies then
        mockFolder = dependencies:WaitForChild("Mock", 10)
    end

    local module = mockFolder and mockFolder:FindFirstChild("MockTraits")
    if not module and mockFolder then
        module = mockFolder:WaitForChild("MockTraits", 10)
    end

    if module and module:IsA("ModuleScript") then
        return module
    end

    return nil
end

local function NormalizeTrait(internalName, data)
    if type(data) ~= "table" then
        return nil
    end

    local trait = {
        InternalName = tostring(internalName),
        Name = tostring(data.DisplayName or internalName),
        DisplayName = tostring(data.DisplayName or internalName),

        Image = type(data.Image) == "string" and data.Image or FALLBACK_IMAGE,
        Description = tostring(data.Description or ""),
        Rarity = tostring(data.Rarity or "Unknown"),
        Chance = math.max(0, tonumber(data.Chance) or 0),

        Damage = tonumber(data.Damage) or 0,
        SPA = tonumber(data.SPA) or 0,
        Range = tonumber(data.Range) or 0,
        CritChance = tonumber(data.CritChance) or 0,
        CritDamage = tonumber(data.CritDamage) or 0,
        PlacementLimit = tonumber(data.PlacementLimit) or 0,

        Raw = ShallowCopy(data)
    }

    return trait
end

local function RefreshTraitDatabase(showNotification)
    local module = GetMockTraitsModule()
    if not module then
        warn("[BLACKSIGIL] MockTraits module was not found.")
        return false, "MockTraits module not found"
    end

    local ok, result = pcall(require, module)
    if not ok or type(result) ~= "table" then
        warn("[BLACKSIGIL] Failed to require MockTraits:", result)
        return false, tostring(result)
    end

    local newDatabase = {}
    local newByName = {}

    for internalName, data in pairs(result) do
        local trait = NormalizeTrait(internalName, data)
        if trait then
            table.insert(newDatabase, trait)
            newByName[string.lower(trait.InternalName)] = trait
            newByName[string.lower(trait.Name)] = trait
        end
    end

    table.sort(newDatabase, function(a, b)
        if a.Rarity == b.Rarity then
            if a.Chance == b.Chance then
                return a.Name < b.Name
            end
            return a.Chance > b.Chance
        end
        return a.Rarity < b.Rarity
    end)

    if #newDatabase == 0 then
        warn("[BLACKSIGIL] MockTraits returned no usable traits.")
        return false, "No usable traits"
    end

    MockTraits = result
    TraitDatabase = newDatabase
    TraitByName = newByName

    print(string.format(
        "[BLACKSIGIL] Loaded %d traits from FusionPackage.Dependencies.Mock.MockTraits",
        #TraitDatabase
    ))

    if showNotification and app then
        SafeLog("Notice", "notification suppressed")
    end

    return true, #TraitDatabase
end

local function GetTraitByName(name)
    if type(name) ~= "string" then
        return nil
    end
    return TraitByName[string.lower(name)]
end

local function FormatTraitStats(trait)
    if type(trait) ~= "table" then
        return ""
    end

    local parts = {}

    local function add(label, value, suffix)
        if value and value ~= 0 then
            local sign = value > 0 and "+" or ""
            table.insert(parts, string.format("%s %s%s%s", label, sign, tostring(value), suffix or ""))
        end
    end

    add("DMG", trait.Damage, "%")
    add("SPA", trait.SPA, "%")
    add("RNG", trait.Range, "%")
    add("Crit", trait.CritChance, "%")
    add("Crit DMG", trait.CritDamage, "%")

    if trait.PlacementLimit and trait.PlacementLimit > 0 then
        table.insert(parts, "Placement " .. tostring(trait.PlacementLimit))
    end

    return table.concat(parts, " | ")
end

do
    local ok, err = RefreshTraitDatabase(false)
    if not ok then
        warn("[BLACKSIGIL] Trait engine started without live traits:", err)
    end
end

-- ================================
-- CORE HELPER FUNCTIONS
-- ================================
local PityMax = {
    Legendary = 50,
    Mythic = 400,
    Secret = 10000
}

local TraitPityMax = {
    Draconic = 300,
    Forsaken = 500,
    Primordial = 750,
    Unbound = 1500
}

local TraitPityGuaranteeOrder = {
    "Unbound",
    "Primordial",
    "Forsaken",
    "Draconic"
}

local function SetPityBar(guiObject, current, maximum)
    if not guiObject or not guiObject:IsA("GuiObject") then
        return
    end

    local ratio = math.clamp((tonumber(current) or 0) / maximum, 0, 1)
    local old = guiObject.Position
    guiObject.Position = UDim2.new(-1 + ratio, old.X.Offset, old.Y.Scale, old.Y.Offset)
end

local function SyncPityDisplays()
    pcall(function()
        local pity = VisualState.Pity

        local legendaryText = UIPaths.LegendaryPityText()
        if legendaryText and legendaryText:IsA("TextLabel") then
            legendaryText.Text = string.format("%d/%d", pity.Legendary, PityMax.Legendary)
        end
        SetPityBar(UIPaths.LegendaryPityBar(), pity.Legendary, PityMax.Legendary)

        local mythicText = UIPaths.MythicPityText()
        if mythicText and mythicText:IsA("TextLabel") then
            mythicText.Text = string.format("%d/%d", pity.Mythic, PityMax.Mythic)
        end
        SetPityBar(UIPaths.MythicPityBar(), pity.Mythic, PityMax.Mythic)

        local secretText = UIPaths.SecretPityText()
        if secretText and secretText:IsA("TextLabel") then
            secretText.Text = string.format("%d/%d", pity.Secret, PityMax.Secret)
        end
        SetPityBar(UIPaths.SecretPityBar(), pity.Secret, PityMax.Secret)
    end)
end

local function SyncTraitPityDisplays()
    pcall(function()
        local pity = VisualState.TraitPity

        local function syncOne(name, textGetter, barGetter)
            local maximum = TraitPityMax[name]
            local current = math.clamp(tonumber(pity[name]) or 0, 0, maximum)
            local label = textGetter()
            if label and label:IsA("TextLabel") then
                label.Text = string.format("%d/%d", current, maximum)
            end
            SetPityBar(barGetter(), current, maximum)
        end

        syncOne("Draconic", UIPaths.DraconicTraitPityText, UIPaths.DraconicTraitPityBar)
        syncOne("Forsaken", UIPaths.ForsakenTraitPityText, UIPaths.ForsakenTraitPityBar)
        syncOne("Primordial", UIPaths.PrimordialTraitPityText, UIPaths.PrimordialTraitPityBar)
        syncOne("Unbound", UIPaths.UnboundTraitPityText, UIPaths.UnboundTraitPityBar)
    end)
end

local function SyncAllDisplays()
    pcall(function()
        local gems1 = UIPaths.BottomHUD_Gems()
        if gems1 then gems1.Text = string.format("%d", VisualState.Gems) end
        local gems2 = UIPaths.SummonGems()
        if gems2 then gems2.Text = string.format("%d", VisualState.Gems) end

        local trait1 = UIPaths.BottomHUD_TraitCount1()
        if trait1 then trait1.Text = string.format("%d", VisualState.TraitRerolls) end
        local trait2 = UIPaths.BottomHUD_TraitCount2()
        if trait2 then trait2.Text = string.format("%d", VisualState.TraitRerolls) end
        local trait3 = UIPaths.RerollMenuCount()
        if trait3 then trait3.Text = string.format("%d", VisualState.TraitRerolls) end
        local traitExact = UIPaths.TraitRerollExactCount()
        if traitExact and traitExact:IsA("TextLabel") then
            traitExact.Text = string.format("%d", VisualState.TraitRerolls)
        end

        local gold = UIPaths.BottomHUD_Gold()
        if gold then gold.Text = string.format("%d", VisualState.Gold) end

        SyncPityDisplays()
        SyncTraitPityDisplays()
    end)
end

local function CloneMap(source)
    local out = {}
    if type(source) == "table" then
        for k, v in pairs(source) do
            out[k] = v
        end
    end
    return out
end

local function CloneArray(source)
    local out = {}
    if type(source) == "table" then
        for i, v in ipairs(source) do
            out[i] = type(v) == "table" and CloneMap(v) or v
        end
    end
    return out
end



local JsonSafeCopy


-- ================================
-- LOCAL CLIENT CURRENCY MIRROR
-- Keeps native BuyButton validation in sync with BLACKSIGIL's visual sliders.
-- No server currency is changed.
-- ================================
local function GetTraitRerollItemName()
    local info = Dependencies.Information
    local traits = info and info.Traits
    local name = traits and traits.RerollItem

    if type(name) == "string" and name ~= "" then
        return name
    end

    return "TraitReroll"
end

local function WriteAmountIntoItemRecord(current, assetName, amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))

    if type(current) == "table" then
        local newEntry = CloneMap(current)

        if newEntry.Amount ~= nil then
            newEntry.Amount = amount
        elseif newEntry.Value ~= nil then
            newEntry.Value = amount
        elseif newEntry.Count ~= nil then
            newEntry.Count = amount
        elseif newEntry.Quantity ~= nil then
            newEntry.Quantity = amount
        else
            newEntry.Amount = amount
        end

        if newEntry.Asset == nil then
            newEntry.Asset = assetName
        end

        return newEntry
    end

    if type(current) == "number" then
        return amount
    end

    return {
        Asset = assetName,
        Amount = amount
    }
end

local function SetLocalItemAmount(assetName, amount)
    if type(assetName) ~= "string" or assetName == "" then
        return false, "invalid asset name"
    end

    amount = math.max(0, math.floor(tonumber(amount) or 0))

    -- The diagnostic confirmed Dependencies.ItemData is a container of
    -- individual Fusion Value objects:
    --
    --   Fusion.peek(Dependencies.ItemData).Gem -> Value
    --   Fusion.peek(GemValue) -> { Amount = 1650 }
    --
    -- Never replace Dependencies.ItemData itself. Update only the leaf Value.
    local okItems, itemContainer = pcall(Fusion.peek, ItemDataState)

    if not okItems or type(itemContainer) ~= "table" then
        return false, "Dependencies.ItemData unavailable"
    end

    local itemState = itemContainer[assetName]

    if type(itemState) ~= "table" or type(itemState.set) ~= "function" then
        return false, "ItemData leaf state missing for " .. tostring(assetName)
    end

    local okCurrent, currentRecord = pcall(Fusion.peek, itemState)

    if not okCurrent or type(currentRecord) ~= "table" then
        return false, "Unable to read ItemData leaf for " .. tostring(assetName)
    end

    local newRecord = CloneMap(currentRecord)

    if newRecord.Amount ~= nil then
        newRecord.Amount = amount
    elseif newRecord.Value ~= nil then
        newRecord.Value = amount
    elseif newRecord.Count ~= nil then
        newRecord.Count = amount
    elseif newRecord.Quantity ~= nil then
        newRecord.Quantity = amount
    else
        newRecord.Amount = amount
    end

    local okSet, setErr = pcall(function()
        itemState:set(newRecord)
    end)

    if not okSet then
        return false, tostring(setErr)
    end

    SafeLog(
        "Local Currency",
        string.format("%s -> %d", tostring(assetName), amount)
    )

    return true
end

local function SyncVisualCurrenciesToNativeState()
    local gemOk, gemErr = SetLocalItemAmount("Gem", VisualState.Gems)
    if not gemOk then
        warn("[BLACKSIGIL] Gem mirror warning:", gemErr)
    end

    local rerollName = GetTraitRerollItemName()
    local rerollOk, rerollErr = SetLocalItemAmount(rerollName, VisualState.TraitRerolls)
    if not rerollOk then
        warn("[BLACKSIGIL] Trait reroll mirror warning:", rerollErr)
    end
end

local function SetNativeUnitDataState(newUnits)
    if type(newUnits) ~= "table" then
        return false, "invalid unit data table"
    end

    if UnitDataState and type(UnitDataState.set) == "function" then
        local ok, err = pcall(function()
            UnitDataState:set(newUnits)
        end)
        if ok then
            return true
        end
        return false, tostring(err)
    end

    if type(UnitDataState) == "table" then
        table.clear(UnitDataState)
        for key, value in pairs(newUnits) do
            UnitDataState[key] = value
        end
        return true
    end

    return false, "Dependencies.UnitData is not writable"
end

local function GetNativeUnitDataSnapshot()
    if UnitDataState and type(UnitDataState) == "table" then
        local ok, result = pcall(Fusion.peek, UnitDataState)
        if ok and type(result) == "table" then
            return result
        end
    end

    local ok, root = pcall(Fusion.peek, PlayerDataState)
    if ok and type(root) == "table" and type(root.UnitData) == "table" then
        return root.UnitData
    end

    return {}
end

local SyncMockTraitToHotbar
local RefreshEquippedMockPresentation

local function ApplyTraitToNativeLocalState(unitID, rolledTrait)
    if type(unitID) ~= "string" or unitID == "" then
        return false, "invalid unit id"
    end
    if type(rolledTrait) ~= "table" then
        return false, "invalid trait"
    end

    -- Mock units live in Dependencies.UnitData. Do NOT replace the whole
    -- Dependencies.PlayerData root here: on rejoin that wakes unrelated
    -- PlayerOverhead/Fusion computations and can produce locked-UIScale errors.
    local currentUnits = GetNativeUnitDataSnapshot()
    if type(currentUnits) ~= "table" then
        return false, "native UnitData unavailable"
    end

    local currentUnit = currentUnits[unitID]

    -- Rejoin race fallback: recover this mock record from the persisted snapshot
    -- if UnitData has not received it yet.
    if type(currentUnit) ~= "table"
        and type(PersistedSnapshot) == "table"
        and type(PersistedSnapshot.MockUnits) == "table"
        and type(PersistedSnapshot.MockUnits[unitID]) == "table" then
        currentUnit = CloneMap(PersistedSnapshot.MockUnits[unitID])
        currentUnit.BLACKSIGILMock = true
    end

    if type(currentUnit) ~= "table" then
        return false, "unit not found: " .. tostring(unitID)
    end

    local newUnits = CloneMap(currentUnits)
    local newUnit = CloneMap(currentUnit)
    local newHistory = CloneArray(currentUnit.TraitHistory)

    local traitKey = rolledTrait.InternalName or rolledTrait.Name
    local oldTrait = currentUnit.Trait
    local oldRollAmount = tonumber(currentUnit.TraitRollAmount) or 0

    newUnit.Trait = traitKey
    newUnit.TraitRollAmount = oldRollAmount + 1
    newUnit.BLACKSIGILMock = true

    table.insert(newHistory, 1, { traitKey, os.time() })
    while #newHistory > 50 do
        table.remove(newHistory)
    end
    newUnit.TraitHistory = newHistory

    newUnits[unitID] = newUnit
    MockUnitIDs[unitID] = true

    local unitSyncOk, unitSyncErr = SetNativeUnitDataState(newUnits)
    if not unitSyncOk then
        return false, "UnitData sync failed: " .. tostring(unitSyncErr)
    end

    -- Keep the in-memory persisted copy current too, so a GUI rebuild/rejoin race
    -- cannot resurrect the old trait.
    if type(PersistedSnapshot) == "table" then
        PersistedSnapshot.MockUnits = type(PersistedSnapshot.MockUnits) == "table"
            and PersistedSnapshot.MockUnits or {}
        PersistedSnapshot.MockUnits[unitID] = JsonSafeCopy(newUnit)
    end

    SafeLog("Native Trait", string.format(
        "%s: %s -> %s (roll %d)",
        unitID,
        tostring(oldTrait),
        tostring(traitKey),
        newUnit.TraitRollAmount
    ))
    return true
end

local function AddTraitToHistory(traitData)
    if type(traitData) ~= "table" then
        return
    end

    VisualState.RollsCount = VisualState.RollsCount + 1

    local historyEntry = {
        Roll = VisualState.RollsCount,
        Timestamp = os.time(),
        Trait = traitData
    }
    table.insert(VisualState.TraitHistory, 1, historyEntry)

    -- Keep the session history bounded so long sessions do not grow forever.
    if #VisualState.TraitHistory > 50 then
        table.remove(VisualState.TraitHistory)
    end

    local histCount = UIPaths.HistoryCount()
    if histCount then
        histCount.Text = tostring(math.min(#VisualState.TraitHistory, 50))
    end

    local scroll = UIPaths.HistoryScroll()
    if not scroll then
        return
    end

    local template = nil
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame")
            and child:FindFirstChild("Frame")
            and child:GetAttribute("BLACKSIGIL_HistoryClone") ~= true then
            template = child
            break
        end
    end

    if not template then
        return
    end

    local clone = template:Clone()
    clone:SetAttribute("BLACKSIGIL_HistoryClone", true)
    clone.Name = "BLACKSIGIL_" .. tostring(VisualState.RollsCount)

    -- Newest local roll first when the UI uses LayoutOrder.
    pcall(function()
        clone.LayoutOrder = -VisualState.RollsCount
    end)

    pcall(function()
        local inner = clone:FindFirstChild("Frame")
        local timeLabel = inner and SafeGet(inner, 5)
        if timeLabel and timeLabel:IsA("TextLabel") then
            timeLabel.Text = os.date("%a %b %d %H:%M:%S %Y", historyEntry.Timestamp)
        end

        local nameLabel = inner and inner:FindFirstChild("TextLabel")
        if nameLabel and nameLabel:IsA("TextLabel") then
            nameLabel.Text = traitData.Name
        end

        local imgLabel = inner and inner:FindFirstChild("ImageLabel")
        SetSafeImage(imgLabel, traitData.Image)

        -- If the game's template contains obvious rarity/chance/stat labels,
        -- fill them without depending on fragile numeric child indexes.
        if inner then
            for _, descendant in ipairs(inner:GetDescendants()) do
                if descendant:IsA("TextLabel") then
                    local loweredName = string.lower(descendant.Name)

                    if string.find(loweredName, "rarity") then
                        descendant.Text = traitData.Rarity
                    elseif string.find(loweredName, "chance") then
                        descendant.Text = string.format("%.4f%%", (traitData.Chance or 0) * 100)
                    elseif string.find(loweredName, "stat") then
                        local statText = FormatTraitStats(traitData)
                        if statText ~= "" then
                            descendant.Text = statText
                        end
                    end
                end
            end
        end
    end)

    clone.Parent = scroll

    -- Keep at most 50 BLACKSIGIL history rows in the visible history UI too.
    local clones = {}
    for _, child in ipairs(scroll:GetChildren()) do
        if child:GetAttribute("BLACKSIGIL_HistoryClone") == true then
            table.insert(clones, child)
        end
    end
    table.sort(clones, function(a, b)
        return (a.LayoutOrder or 0) < (b.LayoutOrder or 0)
    end)
    while #clones > 50 do
        local oldest = table.remove(clones)
        pcall(function() oldest:Destroy() end)
    end

    QueuePersistentSave()
end

local TraitRandom = Random.new()

local function GetGuaranteedTraitPity()
    for _, traitName in ipairs(TraitPityGuaranteeOrder) do
        local maximum = TraitPityMax[traitName]
        local current = tonumber(VisualState.TraitPity[traitName]) or 0
        if current + 1 >= maximum then
            local trait = GetTraitByName(traitName)
            if trait then
                return trait
            end
        end
    end
    return nil
end

local function AdvanceTraitPityAfterRoll(rolledTrait)
    for traitName, maximum in pairs(TraitPityMax) do
        VisualState.TraitPity[traitName] = math.min(
            maximum,
            (tonumber(VisualState.TraitPity[traitName]) or 0) + 1
        )
    end

    local rolledName = type(rolledTrait) == "table"
        and (rolledTrait.InternalName or rolledTrait.Name)
        or nil

    if type(rolledName) == "string" then
        for traitName in pairs(TraitPityMax) do
            if string.lower(rolledName) == string.lower(traitName) then
                VisualState.TraitPity[traitName] = 0
                break
            end
        end
    end
end

local function RollRandomTrait()
    if #TraitDatabase == 0 then
        local ok = RefreshTraitDatabase(false)
        if not ok or #TraitDatabase == 0 then
            return nil
        end
    end

    local result = GetGuaranteedTraitPity()

    if not result then
        local totalWeight = 0
        for _, trait in ipairs(TraitDatabase) do
            totalWeight = totalWeight + math.max(0, tonumber(trait.Chance) or 0)
        end

        if totalWeight <= 0 then
            result = TraitDatabase[TraitRandom:NextInteger(1, #TraitDatabase)]
        else
            local roll = TraitRandom:NextNumber(0, totalWeight)
            local accumulated = 0

            for _, trait in ipairs(TraitDatabase) do
                accumulated = accumulated + math.max(0, tonumber(trait.Chance) or 0)
                if roll <= accumulated then
                    result = trait
                    break
                end
            end

            result = result or TraitDatabase[#TraitDatabase]
        end
    else
        SafeLog("Trait Pity", string.format("%s guaranteed", tostring(result.Name)))
    end

    AdvanceTraitPityAfterRoll(result)
    SyncTraitPityDisplays()
    return result
end

local function UpdateMirroredTraitName(nameLabel, newText)
    if not nameLabel or not nameLabel:IsA("TextLabel") then
        return
    end

    local oldText = nameLabel.Text
    nameLabel.Text = newText

    -- Some UIs render an outline/shadow as another TextLabel.
    -- Only mirror labels that contained the old trait name; do not overwrite
    -- unrelated labels such as chance or description.
    local parent = nameLabel.Parent
    if parent and oldText ~= "" then
        for _, descendant in ipairs(parent:GetDescendants()) do
            if descendant ~= nameLabel
                and descendant:IsA("TextLabel")
                and descendant.Text == oldText then
                descendant.Text = newText
            end
        end
    end
end

local function RenderTraitResult(rolledTrait)
    if type(rolledTrait) ~= "table" then
        return false
    end

    local renderedAnything = false

    local nameLabel = UIPaths.TraitName()
    if nameLabel and nameLabel:IsA("TextLabel") then
        UpdateMirroredTraitName(nameLabel, rolledTrait.Name)
        renderedAnything = true
    end

    local chanceLbl = UIPaths.TraitChance()
    if chanceLbl and chanceLbl:IsA("TextLabel") then
        chanceLbl.Text = string.format(
            "%.4f%% Roll Chance",
            (tonumber(rolledTrait.Chance) or 0) * 100
        )
        renderedAnything = true
    end

    local descLbl = UIPaths.TraitDescription()
    if descLbl and descLbl:IsA("TextLabel") then
        descLbl.Text = rolledTrait.Description or ""
        renderedAnything = true
    end

    local imgLbl = UIPaths.TraitImage()
    if imgLbl and imgLbl:IsA("ImageLabel") then
        SetSafeImage(imgLbl, rolledTrait.Image)
        renderedAnything = true
    end

    return renderedAnything
end

local LastRerollIntercept = 0
local REROLL_INTERCEPT_WINDOW = 0.12
local RerollInProgress = false

local function PerformVisualReroll(unitID, confirmed, options)
    options = type(options) == "table" and options or {}
    if RerollInProgress then return false end

    local now = os.clock()
    if not options.IgnoreInterceptWindow and (now - LastRerollIntercept) < REROLL_INTERCEPT_WINDOW then
        return false
    end

    LastRerollIntercept = now
    RerollInProgress = true

    local ok, result = pcall(function()
        if options.Consume ~= false and VisualState.TraitRerolls <= 0 then
            SafeLog("Trait Reroll", "No visual trait rerolls remaining")
            return false
        end

        local rolledTrait = RollRandomTrait()
        if not rolledTrait then
            SafeLog("Trait Reroll", "Trait database unavailable")
            return false
        end

        local appliedNative, nativeErr = ApplyTraitToNativeLocalState(unitID, rolledTrait)

        if options.Consume ~= false then
            VisualState.TraitRerolls = math.max(0, VisualState.TraitRerolls - 1)

            -- Keep the real client-side reroll Value and exact TraitReroll label
            -- synchronized on every mock roll (e.g. 100 -> 99).
            local rerollOk, rerollErr = SetLocalItemAmount(
                GetTraitRerollItemName(),
                VisualState.TraitRerolls
            )
            if not rerollOk then
                warn("[BLACKSIGIL] Reroll consume sync warning:", rerollErr)
            end
        end
        VisualState.LastTrait = rolledTrait
        QueuePersistentSave()

        -- Render from MockTraits directly every time. This keeps the name,
        -- description, chance and icon visible even when the native Trait
        -- processor is rebuilding after a rejoin.
        RenderTraitResult(rolledTrait)
        AddTraitToHistory(rolledTrait)

        if appliedNative then
            if RefreshEquippedMockPresentation then
                task.defer(RefreshEquippedMockPresentation, unitID)
            end
        else
            warn("[BLACKSIGIL] Native local trait state failed:", nativeErr)
        end
        SyncAllDisplays()

        SafeLog("VISUAL REROLL", string.format("%s -> %s (%s, %.4f%%)%s", tostring(unitID), tostring(rolledTrait.Name), tostring(rolledTrait.Rarity), (rolledTrait.Chance or 0) * 100, confirmed and " [confirmed]" or ""))
        return true
    end)

    RerollInProgress = false
    if not ok then
        warn("[BLACKSIGIL] Visual trait reroll failed:", result)
        return false
    end
    return result == true
end

-- ================================
-- NATIVE LOCAL BANNER SUMMON ENGINE
-- ================================
local SummonRandom = Random.new()
local SummonInProgress = false

local function ResolveStateValue(value)
    local ok, resolved = pcall(Fusion.peek, value)
    if ok then
        return resolved
    end
    return value
end

local function GetBannerSnapshot(bannerID)
    local ok, root = pcall(Fusion.peek, BannerDataState)
    if not ok or type(root) ~= "table" then
        return nil, "BannerData peek failed"
    end

    local banner = root[bannerID]
    banner = ResolveStateValue(banner)

    if type(banner) ~= "table" then
        return nil, "banner not found: " .. tostring(bannerID)
    end

    return banner
end

local function LooksLikeRarity(value)
    if type(value) ~= "string" then
        return false
    end

    local known = {
        Common = true,
        Uncommon = true,
        Rare = true,
        Epic = true,
        Legendary = true,
        Mythic = true,
        Secret = true,
        Exclusive = true
    }

    return known[value] == true
end

local function FlattenBannerPool(pool)
    local candidates = {}
    local visited = {}

    local function walk(node, inheritedRarity)
        node = ResolveStateValue(node)

        if type(node) ~= "table" or visited[node] then
            return
        end
        visited[node] = true

        local asset = ResolveStateValue(node.Asset)
        if type(asset) == "string" and asset ~= "" then
            local chance = tonumber(ResolveStateValue(node.Chance)) or 0
            local rarity = ResolveStateValue(node.Rarity)
            if type(rarity) ~= "string" or rarity == "" then
                rarity = inheritedRarity
            end

            table.insert(candidates, {
                Asset = asset,
                Chance = math.max(0, chance),
                Rarity = rarity,
                Featured = ResolveStateValue(node.Featured) == true,
                Raw = node
            })
            return
        end

        for key, value in pairs(node) do
            local nextRarity = inheritedRarity
            if LooksLikeRarity(key) then
                nextRarity = key
            end
            walk(value, nextRarity)
        end
    end

    walk(pool, nil)
    return candidates
end

-- ================================
-- BANNER RARITY DISTRIBUTION
-- Hardcoded visual/mock summon odds.
-- Total = 100.00%
-- ================================
local BannerRarityChances = {
    Rare = 74.68,
    Epic = 15.06,
    Legendary = 10.00,
    Mythic = 0.25,
    Secret = 0.01
}

local BannerRarityOrder = {
    "Rare",
    "Epic",
    "Legendary",
    "Mythic",
    "Secret"
}

local function ResolveCandidateRarity(candidate)
    if type(candidate) ~= "table" then
        return nil
    end

    if type(candidate.Rarity) == "string" and candidate.Rarity ~= "" then
        return candidate.Rarity
    end

    local asset = candidate.Asset
    if type(asset) ~= "string" then
        return nil
    end

    local information = Dependencies.Information

    if information and type(information.GetAssetRarity) == "function" then
        local ok, rarity = pcall(function()
            return information:GetAssetRarity(asset)
        end)

        if ok and type(rarity) == "string" and rarity ~= "" then
            candidate.Rarity = rarity
            return rarity
        end
    end

    if information and type(information.GetAsset) == "function" then
        local ok, info = pcall(function()
            return information:GetAsset(asset)
        end)

        if ok and type(info) == "table" and type(info.Rarity) == "string" then
            candidate.Rarity = info.Rarity
            return info.Rarity
        end
    end

    return nil
end

local function RollBannerRarity()
    local target = SummonRandom:NextNumber(0, 100)
    local accumulated = 0

    for _, rarity in ipairs(BannerRarityOrder) do
        accumulated = accumulated + (BannerRarityChances[rarity] or 0)

        if target <= accumulated then
            return rarity
        end
    end

    -- Floating-point safety fallback.
    return "Rare"
end

local function GetGuaranteedPityRarity()
    -- Highest rarity wins if multiple guarantees become due together.
    if (VisualState.Pity.Secret or 0) + 1 >= PityMax.Secret then
        return "Secret"
    end
    if (VisualState.Pity.Mythic or 0) + 1 >= PityMax.Mythic then
        return "Mythic"
    end
    if (VisualState.Pity.Legendary or 0) + 1 >= PityMax.Legendary then
        return "Legendary"
    end
    return nil
end

local function AdvancePityAfterRoll(actualRarity)
    local pity = VisualState.Pity
    pity.Legendary = math.min(PityMax.Legendary, (pity.Legendary or 0) + 1)
    pity.Mythic = math.min(PityMax.Mythic, (pity.Mythic or 0) + 1)
    pity.Secret = math.min(PityMax.Secret, (pity.Secret or 0) + 1)

    if actualRarity == "Legendary" then
        pity.Legendary = 0
    elseif actualRarity == "Mythic" then
        pity.Mythic = 0
    elseif actualRarity == "Secret" then
        pity.Secret = 0
    end
end

local function FilterCandidatesByRarity(candidates, rarity)
    local filtered = {}

    for _, candidate in ipairs(candidates) do
        if ResolveCandidateRarity(candidate) == rarity then
            table.insert(filtered, candidate)
        end
    end

    return filtered
end

local function PickWeightedCandidate(candidates)
    if #candidates == 0 then
        return nil
    end

    local total = 0

    for _, candidate in ipairs(candidates) do
        total = total + math.max(0, tonumber(candidate.Chance) or 0)
    end

    -- Some CurrentPool builds do not expose meaningful per-unit Chance.
    -- In that case, split the rolled rarity evenly across its units.
    if total <= 0 then
        return candidates[SummonRandom:NextInteger(1, #candidates)]
    end

    local target = SummonRandom:NextNumber(0, total)
    local accumulated = 0

    for _, candidate in ipairs(candidates) do
        accumulated = accumulated + math.max(0, tonumber(candidate.Chance) or 0)

        if target <= accumulated then
            return candidate
        end
    end

    return candidates[#candidates]
end

local function GetEffectiveCandidateChance(candidates, candidate)
    local rarity = ResolveCandidateRarity(candidate)
    local rarityChance = BannerRarityChances[rarity] or 0

    if rarityChance <= 0 then
        return 0
    end

    local rarityCandidates = FilterCandidatesByRarity(candidates, rarity)

    if #rarityCandidates == 0 then
        return 0
    end

    local totalWeight = 0

    for _, entry in ipairs(rarityCandidates) do
        totalWeight = totalWeight + math.max(0, tonumber(entry.Chance) or 0)
    end

    if totalWeight <= 0 then
        return rarityChance / #rarityCandidates
    end

    return rarityChance
        * (math.max(0, tonumber(candidate.Chance) or 0) / totalWeight)
end

local LoggedBannerChanceTables = {}

local function LogHardcodedBannerChances(bannerID, candidates)
    if LoggedBannerChanceTables[bannerID] then
        return
    end

    LoggedBannerChanceTables[bannerID] = true

    print("[BLACKSIGIL] Hardcoded rarity chances for", bannerID)

    for _, rarity in ipairs(BannerRarityOrder) do
        print(string.format(
            "[BLACKSIGIL]   %-10s %.4f%%",
            rarity,
            BannerRarityChances[rarity]
        ))
    end

    print("[BLACKSIGIL] Effective unit chances for current pool:")

    for _, candidate in ipairs(candidates) do
        local rarity = ResolveCandidateRarity(candidate) or "Unknown"
        local effectiveChance = GetEffectiveCandidateChance(candidates, candidate)

        print(string.format(
            "[BLACKSIGIL]   %s | %s | %.6f%%",
            tostring(candidate.Asset),
            tostring(rarity),
            effectiveChance
        ))
    end
end

local function RollBannerCandidate(candidates, forcedRarity)
    if #candidates == 0 then
        return nil
    end

    -- Stage 1: pity guarantee takes priority, otherwise use hardcoded rarity roll.
    local rolledRarity = forcedRarity or RollBannerRarity()

    -- Stage 2: choose only from units of that rarity in the live CurrentPool.
    local rarityCandidates = FilterCandidatesByRarity(candidates, rolledRarity)

    if #rarityCandidates == 0 then
        warn(
            "[BLACKSIGIL] Banner pool has no",
            rolledRarity,
            "candidate; falling back to live pool"
        )

        local fallback = PickWeightedCandidate(candidates)

        if fallback then
            fallback.RolledRarity = rolledRarity
            fallback.EffectiveChance = GetEffectiveCandidateChance(candidates, fallback)
        end

        return fallback
    end

    local picked = PickWeightedCandidate(rarityCandidates)

    if picked then
        picked.RolledRarity = rolledRarity
        picked.EffectiveChance = GetEffectiveCandidateChance(candidates, picked)
    end

    return picked
end

local function FindExistingUnitTemplate(unitData, asset)
    if type(unitData) ~= "table" then
        return nil
    end

    for _, data in pairs(unitData) do
        if type(data) == "table" and data.Asset == asset then
            return data
        end
    end

    return nil
end

local function BuildMockUnitEntry(currentUnits, candidate)
    local asset = candidate.Asset
    local id = asset .. "#" .. HttpService:GenerateGUID(false)
    local template = FindExistingUnitTemplate(currentUnits, asset)
    local unit = template and CloneMap(template) or {}

    unit.Asset = asset
    unit.BLACKSIGILMock = true
    unit.ObtainedAt = os.time()
    unit.Favorited = nil
    unit.Locked = nil
    unit.Equipped = nil

    -- Fresh summons should not inherit another unit's trait/session history.
    unit.Trait = nil
    unit.TraitRollAmount = nil
    unit.TraitHistory = nil

    if unit.Shiny == nil then
        unit.Shiny = false
    end

    return id, unit
end

local function UpdateLocalBannerProgress(root, bannerID, results)
    local playerBannerData = CloneMap(root.BannerData)
    local bannerState = CloneMap(playerBannerData[bannerID])

    bannerState.SummonCount = (tonumber(bannerState.SummonCount) or 0) + #results

    playerBannerData[bannerID] = bannerState
    root.BannerData = playerBannerData
end

local function DeductLocalBannerCurrency(root, bannerSnapshot, amount)
    local info = ResolveStateValue(bannerSnapshot.BannerInfo)
    if type(info) ~= "table" then
        return
    end

    local currency = ResolveStateValue(info.Currency) or "Gem"
    local cost = tonumber(ResolveStateValue(info.Cost)) or 0
    local totalCost = math.max(0, cost * amount)

    if totalCost <= 0 then
        return
    end

    if currency == "Gem" then
        VisualState.Gems = math.max(0, VisualState.Gems - totalCost)

        local ok, err = SetLocalItemAmount("Gem", VisualState.Gems)
        if not ok then
            warn("[BLACKSIGIL] Visual Gem spend warning:", err)
        end
    end

    SafeLog(
        "Summon Currency",
        string.format("-%d %s", totalCost, tostring(currency))
    )
end

local function ApplyLocalSummonState(bannerID, bannerSnapshot, candidates, amount)
    local ok, currentRoot = pcall(Fusion.peek, PlayerDataState)
    if not ok or type(currentRoot) ~= "table" then
        return false, "PlayerData peek failed"
    end

    local currentUnits = currentRoot.UnitData
    if type(currentUnits) ~= "table" then
        return false, "PlayerData.UnitData missing"
    end

    local newRoot = CloneMap(currentRoot)
    local newUnits = CloneMap(currentUnits)
    local results = {}

    for _ = 1, amount do
        local guaranteedRarity = GetGuaranteedPityRarity()
        local candidate = RollBannerCandidate(candidates, guaranteedRarity)
        if not candidate then
            break
        end

        local actualRarity = ResolveCandidateRarity(candidate)
        AdvancePityAfterRoll(actualRarity)

        if guaranteedRarity then
            SafeLog("Pity Guarantee", string.format("%s guaranteed -> %s", guaranteedRarity, tostring(candidate.Asset)))
        end

        local unitID, unitData = BuildMockUnitEntry(newUnits, candidate)
        newUnits[unitID] = unitData
        MockUnitIDs[unitID] = true

        table.insert(results, {
            Asset = candidate.Asset,
            Amount = 1,
            ID = unitID,
            UnitID = unitID,
            GUID = unitID,
            Rarity = ResolveCandidateRarity(candidate),
            RolledRarity = candidate.RolledRarity,
            EffectiveChance = candidate.EffectiveChance,
            Featured = candidate.Featured == true,
            Shiny = unitData.Shiny == true
        })
    end

    if #results == 0 then
        return false, "banner pool produced no units"
    end

    newRoot.UnitData = newUnits
    UpdateLocalBannerProgress(newRoot, bannerID, results)
    DeductLocalBannerCurrency(newRoot, bannerSnapshot, #results)

    local okSet, setErr = pcall(function()
        PlayerDataState:set(newRoot)
        local unitSyncOk, unitSyncErr = SetNativeUnitDataState(newUnits)
        if not unitSyncOk then
            warn("[BLACKSIGIL] UnitData sync warning:", unitSyncErr)
        end
    end)

    if not okSet then
        return false, "PlayerData:set failed: " .. tostring(setErr)
    end

    SyncAllDisplays()
    QueuePersistentSave()

    return true, results
end

local function FindSummonCutsceneModule()
    local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    local runtimeMount = playerScripts and playerScripts:FindFirstChild("MountSummonMenu")
    local runtimeModule = runtimeMount and runtimeMount:FindFirstChild("SummonCutscene")

    if runtimeModule and runtimeModule:IsA("ModuleScript") then
        return runtimeModule
    end

    local starterScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
    local starterMount = starterScripts and starterScripts:FindFirstChild("MountSummonMenu")
    local starterModule = starterMount and starterMount:FindFirstChild("SummonCutscene")

    if starterModule and starterModule:IsA("ModuleScript") then
        return starterModule
    end

    return nil
end

local function HasNativeSummonCutsceneAssets()
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    local cutscenes = assets and assets:FindFirstChild("Cutscenes")
    local summonAssets = cutscenes and cutscenes:FindFirstChild("Summon")
    return summonAssets ~= nil
end

local function ShowNativeSummonResults(results)
    -- The shipped SummonCutscene module does an unconditional
    -- ReplicatedStorage.Assets.Cutscenes:WaitForChild("Summon").
    -- Some live clients do not replicate that folder, which would yield forever.
    -- Only require the cutscene module when its dependencies are already present.
    local cutsceneModule = nil
    if HasNativeSummonCutsceneAssets() then
        cutsceneModule = FindSummonCutsceneModule()
    else
        -- Native cutscene assets are not replicated in this client; silently use result UI fallback.
    end

    if cutsceneModule then
        local okRequire, Cutscene = pcall(require, cutsceneModule)
        if okRequire and type(Cutscene) == "table" and type(Cutscene.New) == "function" then
            local okNew, object = pcall(function()
                return Cutscene.New({
                    ExtraData = {
                        RollResult = results
                    },
                    RollResult = results,
                    CanSkip = true,
                    PlaybackSpeed = 1
                })
            end)

            if okNew and type(object) == "table" then
                if type(object.Animation) == "function" then
                    task.spawn(function()
                        local okAnim, animErr = pcall(object.Animation, object)
                        if not okAnim then
                            warn("[BLACKSIGIL] Native summon cutscene failed:", animErr)
                            pcall(function()
                                SharedUtils:DisplaySummonResult(results, true, "SummonAnimation")
                            end)
                        end
                    end)
                    return true
                elseif type(object.Start) == "function" then
                    task.spawn(function()
                        local okStart, startErr = pcall(object.Start, object)
                        if not okStart then
                            warn("[BLACKSIGIL] Native summon cutscene start failed:", startErr)
                            pcall(function()
                                SharedUtils:DisplaySummonResult(results, true, "SummonAnimation")
                            end)
                        end
                    end)
                    return true
                end
            end
        end
    end

    local okDisplay, displayErr = pcall(function()
        SharedUtils:DisplaySummonResult(results, true, "SummonAnimation")
    end)

    if not okDisplay then
        warn("[BLACKSIGIL] Native summon result UI failed:", displayErr)
        return false
    end

    return true
end

local function PerformVisualSummon(bannerID, amount)
    if SummonInProgress then
        return false
    end

    SummonInProgress = true

    local ok, result = pcall(function()
        amount = math.clamp(math.floor(tonumber(amount) or 1), 1, 50)

        local bannerSnapshot, bannerErr = GetBannerSnapshot(bannerID)
        if not bannerSnapshot then
            warn("[BLACKSIGIL] Banner snapshot failed:", bannerErr)
            return false
        end

        local currentPool = ResolveStateValue(bannerSnapshot.CurrentPool)
        local candidates = FlattenBannerPool(currentPool)

        if #candidates == 0 then
            warn("[BLACKSIGIL] No summon candidates found in CurrentPool for", bannerID)
            return false
        end

        SafeLog("Banner", string.format("%s: loaded %d live pool entries", tostring(bannerID), #candidates))

        local applied, resultsOrErr = ApplyLocalSummonState(
            bannerID,
            bannerSnapshot,
            candidates,
            amount
        )

        if not applied then
            warn("[BLACKSIGIL] Local summon state failed:", resultsOrErr)
            return false
        end

        local results = resultsOrErr
        VisualState.LastSummonResults = results
        table.insert(VisualState.SummonHistory, 1, {
            Banner = bannerID,
            Timestamp = os.time(),
            Results = results
        })

        while #VisualState.SummonHistory > 50 do
            table.remove(VisualState.SummonHistory)
        end

        local names = {}
        for _, entry in ipairs(results) do
            local suffix = ""

            if entry.Rarity then
                suffix = suffix .. " [" .. tostring(entry.Rarity) .. "]"
            end

            if tonumber(entry.EffectiveChance) then
                suffix = suffix .. string.format(" %.6f%%", entry.EffectiveChance)
            end

            table.insert(names, tostring(entry.Asset) .. suffix)
        end

        SafeLog(
            "VISUAL SUMMON",
            string.format("%s x%d -> %s", tostring(bannerID), #results, table.concat(names, ", "))
        )

        ShowNativeSummonResults(results)
        return true
    end)

    SummonInProgress = false

    if not ok then
        warn("[BLACKSIGIL] Visual summon failed:", result)
        return false
    end

    return result == true
end


-- ================================
-- VISUAL MOCK EQUIP / UNEQUIP - SAFE LOCAL PRESENTATION
--
-- We intentionally do NOT touch the server-backed HotbarData replica or
-- Dependencies.HotbarState. Mock equip is split into:
--   1) UnitData.Equipped for the inventory checkmark.
--   2) the game's own Base.Slot -> Unit -> HotbarLayout chain mounted INSIDE
--      the real empty hotbar slot GUI (no replica mutation).
--   3) UNIT_ADD_TO_PLAYER / UNIT_REMOVE_FOR_PLAYER for the native follower.
-- ================================
local VisualUnequipMockUnit
local MockEquippedSlots = {}   -- [unitID] = slotNumber
local MockSlotUnits = {}       -- [slotNumber] = unitID
local MockSlotViews = {}       -- [unitID] = { Scope, Instance, AnchorConnections }
local MockOverlayRoot = nil

JsonSafeCopy = function(value, depth)
    depth = depth or 0
    if depth > 12 then
        return nil
    end

    local kind = type(value)
    if kind == "nil" or kind == "string" or kind == "boolean" then
        return value
    end
    if kind == "number" then
        if value == value and value ~= math.huge and value ~= -math.huge then
            return value
        end
        return nil
    end
    if kind ~= "table" then
        return nil
    end

    -- Preserve a true sequential array; otherwise stringify keys so
    -- HttpService:JSONEncode never receives a mixed-key Lua table.
    local arrayLength = #value
    local isArray = arrayLength > 0
    if isArray then
        local count = 0
        for key in pairs(value) do
            if type(key) ~= "number" or key < 1 or key > arrayLength or key % 1 ~= 0 then
                isArray = false
                break
            end
            count = count + 1
        end
        isArray = isArray and count == arrayLength
    end

    local out = {}
    if isArray then
        for i = 1, arrayLength do
            out[i] = JsonSafeCopy(value[i], depth + 1)
        end
    else
        for key, child in pairs(value) do
            local copied = JsonSafeCopy(child, depth + 1)
            if copied ~= nil then
                out[tostring(key)] = copied
            end
        end
    end
    return out
end

SavePersistentState = function()
    if type(writefile) ~= "function" then
        return false
    end

    -- Start from the last successfully loaded/saved mock table. During rejoin,
    -- Dependencies.UnitData can briefly be empty while the native state mounts;
    -- never let that transient state erase the persistent inventory.
    local mockUnits = {}
    if type(PersistedSnapshot) == "table"
        and type(PersistedSnapshot.MockUnits) == "table" then
        for unitID, unitData in pairs(PersistedSnapshot.MockUnits) do
            if type(unitID) == "string" and type(unitData) == "table" then
                mockUnits[unitID] = JsonSafeCopy(unitData)
            end
        end
    end

    local units = GetNativeUnitDataSnapshot()
    if type(units) == "table" then
        for unitID, unitData in pairs(units) do
            if type(unitData) == "table" and unitData.BLACKSIGILMock == true then
                mockUnits[unitID] = JsonSafeCopy(unitData)
            end
        end
    end

    local snapshot = {
        Version = 23,
        VisualState = JsonSafeCopy(VisualState),
        MockUnits = mockUnits,
        Equipped = JsonSafeCopy(MockEquippedSlots)
    }

    -- Keep the in-memory copy synchronized with exactly what is written.
    PersistedSnapshot = snapshot

    local okEncode, encoded = pcall(HttpService.JSONEncode, HttpService, snapshot)
    if not okEncode then
        return false
    end

    local okWrite = pcall(writefile, PERSISTENCE_FILE, encoded)
    return okWrite
end

local function IsMockUnitID(unitID)
    if type(unitID) ~= "string" or unitID == "" then
        return false
    end

    if MockUnitIDs[unitID] then
        return true
    end

    local units = GetNativeUnitDataSnapshot()
    local data = type(units) == "table" and units[unitID] or nil
    if type(data) == "table" and data.BLACKSIGILMock == true then
        MockUnitIDs[unitID] = true
        return true
    end

    local ok, root = pcall(Fusion.peek, PlayerDataState)
    if ok and type(root) == "table" and type(root.UnitData) == "table" then
        data = root.UnitData[unitID]
        if type(data) == "table" and data.BLACKSIGILMock == true then
            MockUnitIDs[unitID] = true
            return true
        end
    end

    return false
end

local function GetCurrentMockUnitData(unitID)
    local units = GetNativeUnitDataSnapshot()
    if type(units) == "table" and type(units[unitID]) == "table" then
        return units[unitID]
    end

    local ok, root = pcall(Fusion.peek, PlayerDataState)
    if ok and type(root) == "table" and type(root.UnitData) == "table"
        and type(root.UnitData[unitID]) == "table" then
        return root.UnitData[unitID]
    end

    if type(PersistedSnapshot) == "table"
        and type(PersistedSnapshot.MockUnits) == "table"
        and type(PersistedSnapshot.MockUnits[unitID]) == "table" then
        return PersistedSnapshot.MockUnits[unitID]
    end

    return nil
end

local function SetMockInventoryEquipped(unitID, equipped)
    local currentUnits = GetNativeUnitDataSnapshot()
    local currentUnit = type(currentUnits) == "table" and currentUnits[unitID] or nil

    if type(currentUnit) ~= "table" then
        return false, "mock unit missing from UnitData"
    end

    local newUnits = CloneMap(currentUnits)
    local newUnit = CloneMap(currentUnit)
    newUnit.Equipped = equipped == true
    newUnits[unitID] = newUnit

    local ok, err = SetNativeUnitDataState(newUnits)
    if not ok then
        return false, err
    end

    return true
end

local function GetRealHotbarSnapshot()
    local ok, hotbar = pcall(Fusion.peek, HotbarState)
    if ok and type(hotbar) == "table" then
        return hotbar
    end
    return {}
end

local function GetMaxVisualSlots()
    local hotbar = GetRealHotbarSnapshot()
    return math.max(1, tonumber(hotbar.MaxSlots) or 6)
end

local function IsRealSlotOccupied(slot)
    local hotbar = GetRealHotbarSnapshot()
    local slots = type(hotbar.Slots) == "table" and hotbar.Slots or {}
    return slots[tostring(slot)] ~= nil or slots[slot] ~= nil
end

local function FindFreeMockSlot(requestedSlot)
    local maxSlots = GetMaxVisualSlots()
    local requested = tonumber(requestedSlot)

    if requested then
        requested = math.floor(requested)
        if requested >= 1 and requested <= maxSlots
            and not IsRealSlotOccupied(requested)
            and MockSlotUnits[requested] == nil then
            return requested
        end
    end

    for slot = 1, maxSlots do
        if not IsRealSlotOccupied(slot) and MockSlotUnits[slot] == nil then
            return slot
        end
    end

    return nil
end

local function GetMockOverlayRoot()
    if MockOverlayRoot and MockOverlayRoot.Parent then
        return MockOverlayRoot
    end

    local parent = PlayerGui:FindFirstChild("BottomHUD")
    local screenGui

    if parent and parent:IsA("ScreenGui") then
        screenGui = parent
    else
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "BLACKSIGIL_MockHotbar"
        screenGui.IgnoreGuiInset = true
        screenGui.ResetOnSpawn = false
        screenGui.DisplayOrder = 100
        screenGui.Parent = PlayerGui
    end

    local root = Instance.new("Frame")
    root.Name = "BLACKSIGIL_MockHotbarOverlay"
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.Size = UDim2.fromScale(1, 1)
    root.Position = UDim2.fromScale(0, 0)
    root.ZIndex = 100
    root.Parent = screenGui

    MockOverlayRoot = root
    return root
end

local function FindNativeHotbarSlotAnchor(slot)
    local hud = PlayerGui:FindFirstChild("BottomHUD")
    if not hud then
        return nil
    end

    local best = nil
    local bestScore = -math.huge

    for _, obj in ipairs(hud:GetDescendants()) do
        if obj:IsA("GuiObject") and obj.Visible and obj.LayoutOrder == slot then
            local size = obj.AbsoluteSize
            if size.X >= 80 and size.X <= 140 and size.Y >= 80 and size.Y <= 140 then
                local score = 0
                if obj:IsA("GuiButton") then score = score + 10 end
                if math.abs(size.X - 108) <= 12 then score = score + 5 end
                if math.abs(size.Y - 108) <= 12 then score = score + 5 end
                if obj:FindFirstChildOfClass("UIAspectRatioConstraint") then score = score + 2 end

                if score > bestScore then
                    best = obj
                    bestScore = score
                end
            end
        end
    end

    return best
end

local function GetFallbackSlotRect(slot)
    local maxSlots = GetMaxVisualSlots()
    local slotSize = 108
    local gap = 8
    local totalWidth = maxSlots * slotSize + math.max(0, maxSlots - 1) * gap
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local x = math.floor((viewport.X - totalWidth) * 0.5 + (slot - 1) * (slotSize + gap))
    local y = math.floor(viewport.Y - 150)
    return Vector2.new(x, y), Vector2.new(slotSize, slotSize)
end

local function CleanupMockNativeSlot(unitID)
    local view = MockSlotViews[unitID]
    if not view then
        return
    end

    if type(view.Connections) == "table" then
        for _, connection in ipairs(view.Connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
    end

    if view.Scope and type(view.Scope.doCleanup) == "function" then
        pcall(function()
            view.Scope:doCleanup()
        end)
    end

    if typeof(view.Host) == "Instance" then
        pcall(function()
            view.Host:Destroy()
        end)
    end

    MockSlotViews[unitID] = nil
end

local function CreateMockSlotHost(anchor, slot)
    if anchor and anchor.Parent then
        local host = Instance.new("Frame")
        host.Name = "BLACKSIGIL_MockNativeSlot_" .. tostring(slot)
        host.BackgroundTransparency = 1
        host.BorderSizePixel = 0
        host.Size = UDim2.fromScale(1, 1)
        host.Position = UDim2.fromScale(0.5, 0.5)
        host.AnchorPoint = Vector2.new(0.5, 0.5)
        host.ZIndex = math.max(100, anchor.ZIndex + 50)
        host.ClipsDescendants = false
        host.Parent = anchor
        return host, true
    end

    -- Fallback only if the native hotbar has not mounted yet.
    local root = GetMockOverlayRoot()
    local pos, size = GetFallbackSlotRect(slot)
    local host = Instance.new("Frame")
    host.Name = "BLACKSIGIL_MockNativeSlotFallback_" .. tostring(slot)
    host.BackgroundTransparency = 1
    host.BorderSizePixel = 0
    host.Size = UDim2.fromOffset(size.X, size.Y)
    host.Position = UDim2.fromOffset(pos.X, pos.Y)
    host.AnchorPoint = Vector2.zero
    host.ZIndex = 100
    host.ClipsDescendants = false
    host.Parent = root
    return host, false
end

local function ResolveMockHotbarCost(unitData)
    if type(unitData) ~= "table" then
        return 0
    end

    for _, key in ipairs({ "PlacementCost", "Cost", "DeployCost", "BaseCost" }) do
        local value = tonumber(unitData[key])
        if value then
            return math.max(0, value)
        end
    end

    -- HotbarLayout only needs the placement Cost. Read the base UpgradeInfo
    -- directly instead of running GetCalculatedStatsFromData/GetEquipmentData.
    local assets = nil
    pcall(function()
        assets = Fusion.peek(Dependencies.Assets)
    end)
    if type(assets) ~= "table" and type(Dependencies.Assets) == "table" then
        assets = Dependencies.Assets
    end

    local assetInfo = type(assets) == "table" and assets[unitData.Asset] or nil
    local upgrades = type(assetInfo) == "table" and assetInfo.UpgradeInfo or nil
    if type(upgrades) == "table" then
        local base = upgrades[0] or upgrades[1] or upgrades["0"] or upgrades["1"]
        if type(base) ~= "table" then
            local bestKey, bestValue
            for key, value in pairs(upgrades) do
                local numericKey = tonumber(key)
                if numericKey and type(value) == "table"
                    and (bestKey == nil or numericKey < bestKey) then
                    bestKey, bestValue = numericKey, value
                end
            end
            base = bestValue
        end

        if type(base) == "table" then
            local cost = tonumber(base.Cost or base.PlacementCost or base.DeployCost)
            if cost then
                return math.max(0, cost)
            end
        end
    end

    return 0
end

local function MountMockNativeSlot(unitID, slot)
    CleanupMockNativeSlot(unitID)

    local unitData = GetCurrentMockUnitData(unitID)
    if type(unitData) ~= "table" then
        error("mock unit data unavailable")
    end

    local anchor = FindNativeHotbarSlotAnchor(slot)
    local host, mountedInNativeSlot = CreateMockSlotHost(anchor, slot)

    local scope = Fusion.scoped(Fusion, NativeState, {
        Slot = NativeSlotComponent
    })

    -- Give AssetDataProcessor an explicit reactive mock record. This follows
    -- the exact native path while avoiding reads from the server-owned hotbar.
    local dataState = scope:Value(CloneMap(unitData))
    local assetState = scope:Value(unitData.Asset)

    local instance = scope:Slot({
        Parent = host,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),

        DisplayType = "Hotbar",
        AssetType = "Unit",
        ID = unitID,
        Asset = assetState,
        Data = dataState,
        SlotNumber = slot,

        -- Match the real Hotbar contract: always pass an explicit Cost.
        Cost = ResolveMockHotbarCost(unitData),

        -- Match the real Hotbar slot presentation as closely as possible.
        HideIcons = true,
        ShowObtainments = false,
        Disabled = false,
        Selected = false,
        LayoutOrder = slot,
        ZIndex = 100,

        [OnEvent("Activated")] = function()
            SafeLog("Mock Hotbar", string.format("slot %d selected (%s)", slot, unitID))
        end,

        [OnEvent("MouseButton2Click")] = function()
            task.defer(function()
                VisualUnequipMockUnit(unitID)
            end)
        end
    })

    local connections = {}

    -- If BottomHUD rebuilds the empty slot, remount into the new native slot.
    if mountedInNativeSlot and anchor then
        table.insert(connections, anchor.AncestryChanged:Connect(function(_, parent)
            if parent == nil and MockEquippedSlots[unitID] == slot then
                task.defer(function()
                    task.wait()
                    if MockEquippedSlots[unitID] == slot then
                        local ok, err = pcall(MountMockNativeSlot, unitID, slot)
                        if not ok then
                            warn("[BLACKSIGIL] Native hotbar remount failed:", err)
                        end
                    end
                end)
            end
        end))
    else
        -- Promote fallback into the real slot once BottomHUD is available.
        task.defer(function()
            for _ = 1, 20 do
                if MockEquippedSlots[unitID] ~= slot then
                    return
                end
                task.wait(0.1)
                if FindNativeHotbarSlotAnchor(slot) then
                    local ok, err = pcall(MountMockNativeSlot, unitID, slot)
                    if not ok then
                        warn("[BLACKSIGIL] Native hotbar promotion failed:", err)
                    end
                    return
                end
            end
        end)
    end

    MockSlotViews[unitID] = {
        Scope = scope,
        Instance = instance,
        Host = host,
        Anchor = anchor,
        Connections = connections,
        Slot = slot,
        DataState = dataState,
        AssetState = assetState,
        NativeMounted = mountedInNativeSlot
    }

    SafeLog(
        "Native Hotbar",
        string.format(
            "%s -> slot %d (%s)",
            unitID,
            slot,
            mountedInNativeSlot and "native anchor" or "fallback"
        )
    )

    return true
end

local function GetFollowerExtraData(unitID, slot)
    local unitData = GetCurrentMockUnitData(unitID)
    if type(unitData) ~= "table" then
        return nil
    end

    local extra = {
        HotbarSlot = slot,
        UnitData = CloneMap(unitData),
        SkinData = {},
        AccessoryData = {}
    }

    local ok, playerRoot = pcall(Fusion.peek, PlayerDataState)
    if ok and type(playerRoot) == "table" then
        if unitData.Skin and type(playerRoot.SkinData) == "table" then
            extra.SkinData = CloneMap(playerRoot.SkinData[unitData.Skin])
        end
        if unitData.Accessory and type(playerRoot.AccessoryData) == "table" then
            extra.AccessoryData = CloneMap(playerRoot.AccessoryData[unitData.Accessory])
        end
    end

    return extra
end

local function AddMockFollower(unitID, slot)
    local extra = GetFollowerExtraData(unitID, slot)
    if not extra then
        return false, "mock unit data unavailable"
    end

    local ok, err = pcall(function()
        NodesModule.UNIT_ADD_TO_PLAYER:FireSelf(LocalPlayer, unitID, extra)
    end)

    if not ok then
        return false, tostring(err)
    end

    return true
end

local function RemoveMockFollower(unitID)
    pcall(function()
        NodesModule.UNIT_REMOVE_FOR_PLAYER:FireSelf(LocalPlayer, unitID)
    end)
end

RefreshEquippedMockPresentation = function(unitID)
    local slot = MockEquippedSlots[unitID]
    if not slot then
        return false
    end

    local unitData = GetCurrentMockUnitData(unitID)
    if type(unitData) ~= "table" then
        return false
    end

    -- Update the native Slot -> AssetDataProcessor -> Unit -> HotbarLayout
    -- chain through its own local reactive values.
    local view = MockSlotViews[unitID]
    if view then
        if view.DataState and type(view.DataState.set) == "function" then
            pcall(function()
                view.DataState:set(CloneMap(unitData))
            end)
        end
        if view.AssetState and type(view.AssetState.set) == "function" then
            pcall(function()
                view.AssetState:set(unitData.Asset)
            end)
        end
    else
        local ok, err = pcall(MountMockNativeSlot, unitID, slot)
        if not ok then
            warn("[BLACKSIGIL] Native hotbar refresh mount failed:", err)
        end
    end

    -- Rebuild native workspace follower so the billboard/model receives the
    -- newly rolled Trait/Shiny/Skin data too.
    local extra = GetFollowerExtraData(unitID, slot)
    if extra then
        pcall(function()
            extra.Rebuild = true
            NodesModule.UNIT_UPDATE_FOR_PLAYER:FireSelf(LocalPlayer, unitID, extra)
        end)
    end

    return true
end

local function VisualEquipMockUnit(unitID, requestedSlot)
    if not IsMockUnitID(unitID) then
        return false, "not a BLACKSIGIL mock unit"
    end

    local slot = MockEquippedSlots[unitID]
    if not slot then
        slot = FindFreeMockSlot(requestedSlot)
        if not slot then
            return false, "no free visual hotbar slot"
        end
    end

    local okFlag, flagErr = SetMockInventoryEquipped(unitID, true)
    if not okFlag then
        return false, flagErr
    end

    MockEquippedSlots[unitID] = slot
    MockSlotUnits[slot] = unitID

    local okSlot, slotErr = pcall(MountMockNativeSlot, unitID, slot)
    if not okSlot then
        warn("[BLACKSIGIL] Native mock slot mount failed:", slotErr)
    end

    RemoveMockFollower(unitID)
    local okFollower, followerErr = AddMockFollower(unitID, slot)
    if not okFollower then
        warn("[BLACKSIGIL] Mock follower add failed:", followerErr)
    end

    SafeLog("Visual Equip", string.format("%s -> native visual slot %d + follower", unitID, slot))
    QueuePersistentSave()
    return true
end

VisualUnequipMockUnit = function(unitID)
    if not IsMockUnitID(unitID) then
        return false, "not a BLACKSIGIL mock unit"
    end

    local slot = MockEquippedSlots[unitID]

    RemoveMockFollower(unitID)
    CleanupMockNativeSlot(unitID)

    if slot then
        MockSlotUnits[slot] = nil
    end
    MockEquippedSlots[unitID] = nil

    local okFlag, flagErr = SetMockInventoryEquipped(unitID, false)
    if not okFlag then
        warn("[BLACKSIGIL] Inventory unequip flag warning:", flagErr)
    end

    SafeLog("Visual Unequip", tostring(unitID))
    QueuePersistentSave()
    return true
end

SyncMockTraitToHotbar = function(unitID, traitKey)
    if IsMockUnitID(unitID) and MockEquippedSlots[unitID] then
        task.defer(RefreshEquippedMockPresentation, unitID)
    end
end

local function RestorePersistentMockData()
    if type(PersistedSnapshot) ~= "table" then
        return
    end

    local persistedUnits = PersistedSnapshot.MockUnits
    if type(persistedUnits) ~= "table" or next(persistedUnits) == nil then
        return
    end

    local okRoot, currentRoot = pcall(Fusion.peek, PlayerDataState)
    if not okRoot or type(currentRoot) ~= "table" then
        return
    end

    local currentUnits = type(currentRoot.UnitData) == "table" and currentRoot.UnitData or {}
    local newUnits = CloneMap(currentUnits)
    local restored = 0

    for unitID, unitData in pairs(persistedUnits) do
        if type(unitID) == "string" and type(unitData) == "table" then
            local copy = CloneMap(unitData)
            copy.BLACKSIGILMock = true
            newUnits[unitID] = copy
            MockUnitIDs[unitID] = true
            restored = restored + 1
        end
    end

    if restored > 0 then
        -- UnitData is the inventory-facing state we need. Replacing the complete
        -- PlayerData root on rejoin unnecessarily invalidates unrelated Fusion
        -- trees such as PlayerOverhead.
        local okUnitRestore, unitRestoreErr = SetNativeUnitDataState(newUnits)
        if not okUnitRestore then
            warn("[BLACKSIGIL] Persistent UnitData restore warning:", unitRestoreErr)
        end
        SafeLog("Persistence", string.format("restored %d mock units", restored))
        if SavePersistentState then
            pcall(SavePersistentState)
        end
    end

    local equipped = PersistedSnapshot.Equipped
    if type(equipped) == "table" then
        task.defer(function()
            task.wait(1)
            for unitID, slot in pairs(equipped) do
                if MockUnitIDs[unitID] then
                    pcall(VisualEquipMockUnit, unitID, tonumber(slot))
                end
            end
        end)
    end
end

local function ClearMockHistoryGui()
    local scroll = UIPaths.HistoryScroll()
    if scroll then
        for _, child in ipairs(scroll:GetChildren()) do
            if child:GetAttribute("BLACKSIGIL_HistoryClone") == true then
                pcall(function() child:Destroy() end)
            end
        end
    end
end

local function DeleteAllMockData()
    -- Remove local followers/hotbar overlays first.
    local equippedIDs = {}
    for unitID in pairs(MockEquippedSlots) do
        table.insert(equippedIDs, unitID)
    end
    for _, unitID in ipairs(equippedIDs) do
        pcall(VisualUnequipMockUnit, unitID)
    end

    -- Remove every BLACKSIGIL-created unit from both local UnitData states.
    local okRoot, currentRoot = pcall(Fusion.peek, PlayerDataState)
    if okRoot and type(currentRoot) == "table" then
        local newUnits = CloneMap(currentRoot.UnitData)
        for unitID, unitData in pairs(newUnits) do
            if MockUnitIDs[unitID] or (type(unitData) == "table" and unitData.BLACKSIGILMock == true) then
                newUnits[unitID] = nil
            end
        end
        local newRoot = CloneMap(currentRoot)
        newRoot.UnitData = newUnits
        pcall(function() PlayerDataState:set(newRoot) end)
        pcall(function() SetNativeUnitDataState(newUnits) end)
    end

    table.clear(MockUnitIDs)
    table.clear(MockEquippedSlots)
    table.clear(MockSlotUnits)

    PersistedSnapshot = {
        Version = 23,
        VisualState = {},
        MockUnits = {},
        Equipped = {}
    }

    VisualState.Gems = 50000
    VisualState.Gold = 100000
    VisualState.TraitRerolls = 500
    VisualState.RollsCount = 0
    VisualState.LastTrait = nil
    VisualState.TraitHistory = {}
    VisualState.LastSummonResults = {}
    VisualState.SummonHistory = {}
    VisualState.Pity = { Legendary = 0, Mythic = 0, Secret = 0 }
    VisualState.TraitPity = { Draconic = 0, Forsaken = 0, Primordial = 0, Unbound = 0 }

    ClearMockHistoryGui()
    SetLocalItemAmount("Gem", VisualState.Gems)
    SetLocalItemAmount(GetTraitRerollItemName(), VisualState.TraitRerolls)
    SyncAllDisplays()

    if type(delfile) == "function" and type(isfile) == "function" then
        pcall(function()
            if isfile(PERSISTENCE_FILE) then
                delfile(PERSISTENCE_FILE)
            end
        end)
    end
    QueuePersistentSave()
    SafeLog("Reset", "all BLACKSIGIL mock data deleted")
end

-- ================================
-- NETWORK INTERCEPTION HOOK
-- Exact paths only:
-- _updateNode:FireServer({Type="Post"}, "ROLL_UNIT_TRAIT", unitID, confirmed)
-- _updateNode:FireServer({Type="Post"}, "BANNER_SUMMON", bannerID, amount)
-- ================================
local NetworkEvents = ReplicatedStorage:WaitForChild("Nodes"):WaitForChild("Network"):WaitForChild("NetworkEvents")
local UpdateNodeRemote = NetworkEvents:WaitForChild("_updateNode")

local function IsExactTraitReroll(remote, method, args)
    if method ~= "FireServer" then return false end
    if remote ~= UpdateNodeRemote then return false end
    local envelope = args[1]
    return type(envelope) == "table"
        and envelope.Type == "Post"
        and args[2] == "ROLL_UNIT_TRAIT"
        and type(args[3]) == "string"
end


local function IsExactUnitEquip(remote, method, args)
    if method ~= "FireServer" or remote ~= UpdateNodeRemote then
        return false
    end

    local envelope = args[1]

    return type(envelope) == "table"
        and envelope.Type == "Post"
        and args[2] == "UNIT_EQUIP"
        and type(args[3]) == "string"
end

local function IsExactUnitUnequip(remote, method, args)
    if method ~= "FireServer" or remote ~= UpdateNodeRemote then
        return false
    end

    local envelope = args[1]

    return type(envelope) == "table"
        and envelope.Type == "Post"
        and args[2] == "UNIT_UNEQUIP"
        and type(args[3]) == "string"
end


local function IsExactBannerSummon(remote, method, args)
    if method ~= "FireServer" then return false end
    if remote ~= UpdateNodeRemote then return false end
    local envelope = args[1]
    return type(envelope) == "table"
        and envelope.Type == "Post"
        and args[2] == "BANNER_SUMMON"
        and type(args[3]) == "string"
        and type(args[4]) == "number"
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = { ... }

    if IsExactUnitEquip(self, method, args) then
        local unitID = args[3]

        if IsMockUnitID(unitID) then
            SafeLog("Equip Intercept", "mock unit " .. tostring(unitID))
            local requestedSlot = args[4]
            local ok, err = VisualEquipMockUnit(unitID, requestedSlot)

            if not ok then
                warn("[BLACKSIGIL] Visual equip failed:", err)
            end

            -- Mock unit IDs are never sent to the server.
            return nil
        end
    end

    if IsExactUnitUnequip(self, method, args) then
        local unitID = args[3]

        if IsMockUnitID(unitID) then
            SafeLog("Unequip Intercept", "mock unit " .. tostring(unitID))
            local ok, err = VisualUnequipMockUnit(unitID)

            if not ok then
                warn("[BLACKSIGIL] Visual unequip failed:", err)
            end

            -- Mock unit IDs are never sent to the server.
            return nil
        end
    end

    if _G.AVTraitRollback and IsExactTraitReroll(self, method, args) then
        task.defer(PerformVisualReroll, args[3], args[4] == true)
        return nil
    end

    if _G.AVSummonRollback and IsExactBannerSummon(self, method, args) then
        task.defer(PerformVisualSummon, args[3], args[4])
        return nil
    end

    return oldNamecall(self, ...)
end))

-- ================================
-- UI PAGE: VISUAL SPOOFING
-- ================================
local currencyGroup = mainTab:PageSection({ Title = "Currency Sliders", Subtitle = "Adjust your visual currency amounts." })
local currencyForm = currencyGroup:Form()

-- Gems Slider
local gemsRow = currencyForm:Row({ SearchIndex = "Gems Amount" })
gemsRow:Left():TitleStack({ Title = "Gems Amount", Subtitle = "Adjust your visual gems count." })
gemsRow:Right():Slider({
    Minimum = 0,
    Maximum = 1000000,
    Value = VisualState.Gems,
    ValueChanged = function(self, val)
        VisualState.Gems = math.floor(val)
        local ok, err = SetLocalItemAmount("Gem", VisualState.Gems)
        if not ok then warn("[BLACKSIGIL] Gem slider sync warning:", err) end
        SyncAllDisplays()
        QueuePersistentSave()
    end
})

-- Gold Slider
local goldRow = currencyForm:Row({ SearchIndex = "Gold Amount" })
goldRow:Left():TitleStack({ Title = "Gold Amount", Subtitle = "Adjust your visual gold count." })
goldRow:Right():Slider({
    Minimum = 0,
    Maximum = 10000000,
    Value = VisualState.Gold,
    ValueChanged = function(self, val)
        VisualState.Gold = math.floor(val)
        SyncAllDisplays()
        QueuePersistentSave()
    end
})

-- Rerolls Slider
local rerollRow = currencyForm:Row({ SearchIndex = "Trait Rerolls" })
rerollRow:Left():TitleStack({ Title = "Trait Rerolls", Subtitle = "Adjust your visual reroll count." })
rerollRow:Right():Slider({
    Minimum = 0,
    Maximum = 100000,
    Value = VisualState.TraitRerolls,
    ValueChanged = function(self, val)
        VisualState.TraitRerolls = math.floor(val)
        local ok, err = SetLocalItemAmount(GetTraitRerollItemName(), VisualState.TraitRerolls)
        if not ok then warn("[BLACKSIGIL] Reroll slider sync warning:", err) end
        SyncAllDisplays()
        QueuePersistentSave()
    end
})

local protectionGroup = mainTab:PageSection({ Title = "Spoof Controls & Protection", Subtitle = "Enable server-side call blocking." })
local protectionForm = protectionGroup:Form()

-- Trait Rollback Toggle
local traitRollbackRow = protectionForm:Row({ SearchIndex = "Visual Trait Rollback" })
traitRollbackRow:Left():TitleStack({ Title = "Visual Trait Rollback", Subtitle = "Block trait rerolls from hitting the server." })
traitRollbackRow:Right():Toggle({
    Value = _G.AVTraitRollback,
    ValueChanged = function(self, val)
        _G.AVTraitRollback = val
        SafeLog("Notice", "notification suppressed")
    end
})

-- Summon Rollback Toggle
local summonRollbackRow = protectionForm:Row({ SearchIndex = "Visual Summon Rollback" })
summonRollbackRow:Left():TitleStack({
    Title = "Visual Summon Rollback",
    Subtitle = "Block BANNER_SUMMON and generate the result locally."
})
summonRollbackRow:Right():Toggle({
    Value = _G.AVSummonRollback,
    ValueChanged = function(self, val)
        _G.AVSummonRollback = val
        SafeLog("Summon Rollback", val and "Enabled" or "Disabled")
    end
})

-- Trait Engine Actions
local traitActionRow = protectionForm:Row({ SearchIndex = "Trait Engine Actions" })
traitActionRow:Left():TitleStack({
    Title = "Trait Engine",
    Subtitle = "Reload live MockTraits or test the renderer locally."
})

local traitActionStack = traitActionRow:Right():HStack({ Padding = UDim.new(0, 5) })

traitActionStack:Button({
    Label = "Reload Traits",
    State = "Primary",
    Pushed = function()
        local ok, detail = RefreshTraitDatabase(true)
        if not ok then
            SafeLog("Notice", "notification suppressed")
        end
    end
})


-- Action Buttons
local actionRow = protectionForm:Row()
local actionStack = actionRow:Right():HStack({ Padding = UDim.new(0, 5) })

actionStack:Button({
    Label = "Force Refresh HUD",
    State = "Primary",
    Pushed = function()
        SyncAllDisplays()
        SafeLog("Notice", "notification suppressed")
    end
})


local function QueueBlackSigilForTeleport()
    local queueFn =
        queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)

    if type(queueFn) ~= "function" then
        warn("[BLACKSIGIL] Executor does not expose queue_on_teleport")
        return false
    end

    local payload = [[
loadstring(game:HttpGet("https://raw.githubusercontent.com/szty-v/chujcieto/refs/heads/main/ez.lua"))()
]]

    local ok, err = pcall(function()
        queueFn(payload)
    end)

    if not ok then
        warn("[BLACKSIGIL] queue_on_teleport failed:", err)
        return false
    end

    return true
end

actionStack:Button({
    Label = "Rejoin Server",
    State = "Destructive",
    Pushed = function()
        QueuePersistentSave()
        if SavePersistentState then
            pcall(SavePersistentState)
        end

        local queued = QueueBlackSigilForTeleport()
        if not queued then
            warn("[BLACKSIGIL] Auto-execute could not be queued")
        end

        task.wait(0.15)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

-- ================================
-- UI PAGE: SETTINGS
-- ================================
local engineGroup = settingsTab:PageSection({ Title = "Blacksigil Engine", Subtitle = "General script information." })
engineGroup:Label({ Text = "Toggle the panel anytime using RightShift." })

local themeRow = engineGroup:Form():Row()
themeRow:Left():TitleStack({ Title = "UI Theme", Subtitle = "Switch between Light and Dark." })
themeRow:Right():Toggle({
    Value = app.Theme == cascade.Themes.Dark,
    ValueChanged = function(self, val)
        app.Theme = val and cascade.Themes.Dark or cascade.Themes.Light
    end
})


local dataRow = engineGroup:Form():Row({ SearchIndex = "Delete All Mock Data" })
dataRow:Left():TitleStack({
    Title = "Delete All Mock Data",
    Subtitle = "Remove saved mock units, traits, histories, pities and visual state."
})
dataRow:Right():Button({
    Label = "Delete Mock Data",
    State = "Destructive",
    Pushed = function()
        DeleteAllMockData()
    end
})

-- TraitReroll is created lazily. Keep a lightweight waiter alive so exact
-- reroll count + index pity text/bars are applied as soon as its descendants exist.
task.spawn(function()
    while true do
        local rerollGui = PlayerGui:FindFirstChild("TraitReroll")
        if rerollGui then
            SyncAllDisplays()
        end
        task.wait(0.25)
    end
end)

-- Keep visual values/pity applied when the game rebuilds BottomHUD, Summon or TraitReroll.
local hudRefreshQueued = false
local function QueueVisualHudRefresh()
    if hudRefreshQueued then return end
    hudRefreshQueued = true
    task.defer(function()
        task.wait()
        hudRefreshQueued = false
        SyncAllDisplays()
    end)
end

PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "BottomHUD" or child.Name == "Summon" or child.Name == "TraitReroll" then
        QueueVisualHudRefresh()
    end
end)

PlayerGui.DescendantAdded:Connect(function(descendant)
    local root = descendant
    while root and root.Parent ~= PlayerGui do
        root = root.Parent
    end
    if root and (root.Name == "BottomHUD" or root.Name == "Summon" or root.Name == "TraitReroll") then
        QueueVisualHudRefresh()
    end
end)

-- ================================
-- INITIALIZATION
-- ================================
RestorePersistentMockData()
SyncVisualCurrenciesToNativeState()
SyncAllDisplays()
QueuePersistentSave()
SafeLog("Loaded", string.format("Trait engine ready with %d live MockTraits; native banner summon engine ready", #TraitDatabase))
SafeLog("Equip", "Visual mock equip/unequip enabled")
SafeLog("Currency", "Native client affordability mirrors enabled")
SafeLog("Hotbar", "v15 native visuals + direct UpgradeInfo cost + rejoin-safe mock UnitData")
SafeLog("Pity", "Summon pity 50/400/10000; trait pity Draconic 300 / Forsaken 500 / Primordial 750 / Unbound 1500")
SafeLog("State", "Using leaf ItemData Values + PlayerData.HotbarData backing state")

print(string.format(
    "BLACKSIGIL - Anime Vanguards (Cascade Edition) initialized with %d live traits and banner summon rollback.",
    #TraitDatabase
))
