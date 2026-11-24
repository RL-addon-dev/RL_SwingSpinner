--[[
    Saved variables. This file names them, sets their defaults and loads them when the addon loads
    (then fires env.Event.DatabaseReady). It also defines the settings' keys and accessors
    (Config.Key, Config.Get, Config.Set, Config.OnChange), and how the settings UI (AX_Settings)
    reads and writes them.

    Loads after Preload.lua and before libs\AX_Settings\AX_Settings.xml, which reads
    env.AX_SettingsOptions while it loads.

        RL_WeaponSwingSpinnerDB              settings
        RL_WeaponSwingSpinnerDB_Persistent   the spinners' positions, the settings window's
                                             position, and whether an earlier version turned the
                                             game's swing timer bars off
]]

local env = select(2, ...)

local CallbackRegistry = env.AX_Modules:Import("ax_modules\\callback-registry")
local SavedVariables = env.AX_Modules:Import("ax_modules\\saved-variables")
local Utils_Standard = env.AX_Modules:Import("ax_modules\\utils\\standard")
local WoWClient = env.AX_Modules:Import("ax_modules\\wow-client")

local Config = {}
env.Config = Config



-- Values of settings with a fixed set of choices. They're the positions of the options in the
-- settings' dropdowns (Setting_Schema.lua), so the two must list them in the same order.
local Enum = {}
env.Enum = Enum

-- Spinner Behavior (FillDirection): whether a spinner fills as its swing goes on, or starts full
-- and drains.
Enum.FillDirection = {
    Fill  = 1,
    Drain = 2
}

-- Idle Style (ReadyStyle): what a spinner looks like once its weapon is ready to swing.
Enum.ReadyStyle = {
    Empty  = 1,
    Faded  = 2, -- the full circle at Fade Opacity
    Full   = 3,
    Hidden = 4
}



-- Defaults

local NAME = "RL_WeaponSwingSpinnerDB"
local NAME_PERSISTENT = "RL_WeaponSwingSpinnerDB_Persistent"

local SPINNER_KEYS = { "MainHand", "OffHand", "Ranged" }
local SPINNER_COLORS = {
    MainHand = { r = 1, g = 0.82, b = 0.25 }, -- gold, with Default Color off
    OffHand  = { r = 1, g = 0.5, b = 0 },     -- the addon's name color
    Ranged   = { r = 0.45, g = 0.9, b = 0.3 },
}

-- Each spinner's settings, saved as <spinner><setting> ("MainHandScale"). The spinner's own
-- key ("MainHand") is whether it's used.
local SPINNER_DEFAULTS = {
    [""]    = true,
    Scale   = 100, -- percent
    Opacity = 100, -- percent
}

-- Settings every spinner shares.
local DB_DEFAULTS = {
    -- Spinner Visibility: the spinners show while any of these that's ticked is true.
    ShowInCombat   = false,
    ShowWithTarget = false, -- an enemy you could attack is targeted
    ShowRecharging = true,  -- each spinner while its swing is filling
    ShowAlways     = false,
    FillDirection = Enum.FillDirection.Fill,
    ReadyStyle   = Enum.ReadyStyle.Hidden,
    ReadyOpacity = 35,    -- percent, a ready spinner's opacity with Idle Style = Fade
    Countdown    = false, -- seconds left, in the middle of the circle
    CombineHands = false, -- the off hand is the main hand's circle's left half
}
for _, spinner in ipairs(SPINNER_KEYS) do
    for setting, value in pairs(SPINNER_DEFAULTS) do DB_DEFAULTS[spinner .. setting] = value end
    DB_DEFAULTS[spinner .. "Color"] = SPINNER_COLORS[spinner]
    -- The game's own art, untinted, instead of Color. Only the main hand starts with it.
    DB_DEFAULTS[spinner .. "GameColor"] = spinner == "MainHand"
end

-- The keys settings are saved under, one per default above. Pass them to Config.Get / Set /
-- OnChange (below) and the schema's `key`: Config.Get(Config.Key.ShowAlways).
local Key = {}
for name in pairs(DB_DEFAULTS) do Key[name] = name end
Config.Key = Utils_Standard.Strict(Key, "setting key")

Config.DB = nil
Config.DBPersistent = nil

--- Takes over what RL: QoL Tweaks saved, from when the spinners were part of it. It loads first
--- (the .toc's OptionalDeps), so its saved variables are there. Its swing timer keys are cleared.
--- If it turned the game's swing timer bars off, they're turned back on (Spinners.lua).
local function MigrateFromQoLTweaks()
    local persistent = Config.DBPersistent:GetData()
    local old = _G["RL_QoLTweaksDB"]
    if type(old) == "table" then
        if old.hidBarTimer then persistent.hidBarTimer = true end
        if not persistent.migrated and type(old.swingTimerPositions) == "table" then
            persistent.positions = CopyTable(old.swingTimerPositions)
        end
        old.swingTimers, old.swingTimerPositions, old.hidBarTimer = nil, nil, nil
        old.swingTimer, old.swingTimerX, old.swingTimerY = nil, nil, nil
    end
    persistent.migrated = true
end

--- Show When, When Ready and Countdown were briefly set per spinner. The main hand's are kept,
--- as the shared ones.
local function MigrateSharedSettings()
    local data = Config.DB:GetData()
    for _, setting in ipairs({ "ShowWhen", "ReadyStyle", "Countdown" }) do
        if data[setting] == nil then data[setting] = data["MainHand" .. setting] end
        for _, spinner in ipairs({ "MainHand", "OffHand", "Ranged" }) do data[spinner .. setting] = nil end
    end
    -- Settings that were removed, including the cast spinners'.
    data.Enabled, data.HideBarTimers, data.Scale, data.Opacity, data.DimOutOfRange = nil, nil, nil, nil, nil
    data.HideCastBar = nil
    for _, setting in ipairs({ "", "Color", "Scale", "Opacity", "SpellName" }) do
        data["PetCast" .. setting], data["PlayerCast" .. setting] = nil, nil
    end
end

-- When Ready's choices were once Full, Empty, Hidden, Faded. Saved choices are their positions,
-- so they're moved to the same choice in the new order, once.
local OLD_READY_STYLES = { Enum.ReadyStyle.Full, Enum.ReadyStyle.Empty, Enum.ReadyStyle.Hidden, Enum.ReadyStyle.Faded }

local function MigrateReadyStyleOrder()
    local persistent = Config.DBPersistent:GetData()
    if persistent.readyStyleSorted then return end
    local data = Config.DB:GetData()
    if data.ReadyStyle ~= nil then data.ReadyStyle = OLD_READY_STYLES[data.ReadyStyle] end
    persistent.readyStyleSorted = true
end

--- Shown When was a dropdown, saved as its choice's position: Combat, Combat/Target, then Always.
--- Auto Attack came in third for a while (showWhenSorted). Its choice becomes the checkboxes,
--- and Auto Attack becomes Swing Recharging, which replaced it.
local function MigrateShowWhen()
    local data = Config.DB:GetData()
    local persistent = Config.DBPersistent:GetData()
    local choice = data.ShowWhen
    if choice ~= nil then
        if choice == 3 and not persistent.showWhenSorted then choice = 4 end
        data.ShowInCombat = choice == 1 or choice == 2
        data.ShowWithTarget = choice == 2
        data.ShowRecharging = choice == 3
        data.ShowAlways = choice == 4
    end
    if data.ShowAutoAttack ~= nil then data.ShowRecharging = data.ShowAutoAttack end
    data.ShowWhen, data.ShowAutoAttack, persistent.showWhenSorted = nil, nil, nil
end

--- The settings' color picker used to save each color as soon as it was shown, so the defaults
--- of the time stuck. Saved colors are cleared once, so the current defaults apply.
local function ClearSavedColors()
    local persistent = Config.DBPersistent:GetData()
    if persistent.savedColorsCleared then return end
    local data = Config.DB:GetData()
    for _, spinner in ipairs(SPINNER_KEYS) do data[spinner .. "Color"] = nil end
    persistent.savedColorsCleared = true
end

--- Loads the saved variables with their defaults, then fires env.Event.DatabaseReady.
function Config.LoadDB()
    Config.DB = SavedVariables.RegisterDatabase(NAME).defaults(DB_DEFAULTS)
    Config.DBPersistent = SavedVariables.RegisterDatabase(NAME_PERSISTENT).defaults({})
    MigrateFromQoLTweaks()
    MigrateSharedSettings()
    MigrateReadyStyleOrder()
    MigrateShowWhen()
    ClearSavedColors()

    CallbackRegistry.Trigger(env.Event.DatabaseReady)
end

--- A setting's value, or its default. Only after env.Event.DatabaseReady.
---@param key string a Config.Key value
---@return any
function Config.Get(key)
    return Config.DB:GetVariable(key)
end

--- Saves a setting. If the value changed, its Config.OnChange callbacks run.
---@param key string a Config.Key value
---@param value any
function Config.Set(key, value)
    -- A color the same as its default isn't saved, so a later change of default still applies.
    -- The color picker saves its color as soon as it's shown, a little rounded.
    local default = DB_DEFAULTS[key]
    if type(value) == "table" and type(default) == "table" then
        local same = true
        for _, channel in ipairs({ "r", "g", "b" }) do
            if math.abs((value[channel] or 0) - default[channel]) > 0.005 then same = false end
        end
        if same then value = nil end
    end
    Config.DB:SetVariable(key, value)
end

--- Calls `callback(event, value)` whenever a setting is changed (by Config.Set or the settings).
---@param key string a Config.Key value
---@param callback fun(event: string, value: any)
function Config.OnChange(key, callback)
    SavedVariables.OnChange(NAME, key, callback)
end

--- Calls `callback()` whenever any setting changes.
---@param callback function
function Config.OnAnyChange(callback)
    for key in pairs(DB_DEFAULTS) do Config.OnChange(key, callback) end
end

--- The persistent table itself (positions and flags), after env.Event.DatabaseReady.
---@return table
function Config.GetPersistent()
    return Config.DBPersistent:GetData()
end

-- Saved variables exist once the addon has loaded.
CallbackRegistry.Add(WoWClient.Event.OnAddonLoaded, Config.LoadDB)



-- AX_Settings (libs\AX_Settings): read when AX_Settings.xml loads, after this file.
env.AX_SettingsOptions = {
    prefix  = "RLWSS",
    title   = env.NAME,
    storage = {
        get = Config.Get,
        set = Config.Set,
    },
    windowPosition = {
        get = function()
            local stored = Config.DBPersistent and Config.DBPersistent:GetData()
            return stored and stored.settingWindowPosition
        end,
        set = function(position)
            Config.DBPersistent:GetData().settingWindowPosition = position
        end,
    },
    getSchema = function() return env.AX_Modules:Import("@\\Setting\\Schema").SCHEMA end,
}
