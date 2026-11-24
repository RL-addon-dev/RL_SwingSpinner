--[[
    Spinners (Spinners_Shared.lua): creating the spinners once the saved variables load, and
    applying the settings whenever they change. Spinners.RefreshAll and Spinners.ResetPositions
    are used by the settings (Setting_Schema.lua).
]]

local env = select(2, ...)
local Config = env.Config
local CallbackRegistry = env.AX_Modules:Import("ax_modules\\callback-registry")
local Spinners = env.AX_Modules:Import("@\\Spinners")
local Private = env.AX_Modules:Import("@\\Spinners\\Private")

local BAR_TIMER_CVAR = "showSwingTimer"

--- Turns the spinners on or off, from the settings.
local function Refresh()
    local on = Private.IsOn()
    Private.RefreshSwingEvents(on)
    if not on then
        for _, spinner in ipairs(Private.spinners) do Private.ShowReady(spinner) end
    end
    Private.RefreshShown()
end

--- Applies every setting again.
function Spinners.RefreshAll()
    if #Private.spinners == 0 then return end
    Private.RefreshLook()
    Refresh()
    Private.RefreshDialog()
end

--- Moves the spinners back to their default locations.
function Spinners.ResetPositions()
    Config.GetPersistent().positions = nil
    for _, spinner in ipairs(Private.spinners) do Private.Place(spinner) end
end

--- Earlier versions turned the game's swing timer bars off (and RL: QoL Tweaks did before them).
--- They're turned back on once, since this addon leaves them alone now.
local function RestoreBarTimer()
    local persistent = Config.GetPersistent()
    if not persistent.hidBarTimer then return end
    if C_CVar.GetCVar(BAR_TIMER_CVAR) then C_CVar.SetCVar(BAR_TIMER_CVAR, "1") end
    persistent.hidBarTimer = nil
end

---@param info table one of Private.SPINNERS
---@return Spinner
local function CreateSpinner(info)
    local spinner = CreateFrame("Frame", "RL_WeaponSwingSpinner" .. info.key, UIParent,
        "RL_WeaponSwingSpinnerTemplate") --[[@as Spinner]]
    spinner.info = info
    spinner.hasWeapon = false
    spinner.swinging = false
    spinner.draining = false
    spinner.startTime, spinner.endTime = 0, 0
    spinner:SetDontSavePosition(true)
    Private.SetUpFonts(spinner)
    Private.SetUpSides(spinner)
    Private.SetUpSwing(spinner)
    Private.ShowReady(spinner)
    Private.AddToEditMode(spinner)
    return spinner
end

local function SetUp()
    RestoreBarTimer()
    if not env.HAS_SWING_EVENTS then return end
    for _, info in ipairs(Private.SPINNERS) do
        local spinner = CreateSpinner(info)
        Private.spinners[#Private.spinners + 1] = spinner
        Private.bySwingType[Private.PlayerSwingType[info.key]] = spinner
    end
    Private.RefreshLook()

    Config.OnAnyChange(Spinners.RefreshAll)
    Private.SetUpReticle()
    Private.SetUpEditMode()

    Refresh()
end

CallbackRegistry.Add(env.Event.DatabaseReady, SetUp)
