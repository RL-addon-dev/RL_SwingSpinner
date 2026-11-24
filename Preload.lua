--[[
    Loads first, with what every other file uses: addon info, the addon's events, the locale table
    (filled by Locales\*.lua), and chat output.
]]

local addonName, env = ...

local Path = env.AX_Modules:Import("ax_modules\\path")
local Utils_Standard = env.AX_Modules:Import("ax_modules\\utils\\standard")

-- Basic addon information
env.NAME = "RL: |cffff8000Swing Spinner|r"
env.NAME_ALT = "Swing Spinner" -- without the prefix or color (About)
env.ICON = Path.Root .. "\\Art\\Icon\\logo-1024.png"
-- From the .toc. The packager sets it from the release tag. A git checkout still has the
-- placeholder.
local tocVersion = C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
env.VERSION_STRING = tocVersion:find("^@") and "dev" or tocVersion

-- Whether this client has swing timer events. Only WoW Forever does, and the .toc only lists it,
-- but a wrong client would otherwise error on load.
env.HAS_SWING_EVENTS = C_EventUtils ~= nil and C_EventUtils.IsEventValid("PLAYER_SWING")

-- The addon's own CallbackRegistry events. Not here are the settings window's events
-- (Setting_Enum.Event, from AX_Settings) and a single setting changing (Config.OnChange).
env.Event = Utils_Standard.Strict({
    DatabaseReady = "Preload.DatabaseReady", -- saved variables loaded (Config.lua)
}, "event")

-- The locale table, filled by Locales\*.lua.
local L = {}
env.L = L

--- Prints `msg` in chat, after the addon's name.
---@param msg string
function env.Print(msg)
    print(env.NAME .. ": " .. msg)
end
