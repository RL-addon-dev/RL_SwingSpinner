--[[
    Spinners: the gamepad UI's swing timer circle, one for the main hand, the off hand and the
    ranged weapon. The files share this one's list of spinners, their state, and small helpers
    (Private).

        Spinners_Shared.lua     this, the spinners and their state
        Spinners_Display.lua    how a spinner looks and when it shows
        Spinners_Swing.lua      swing timers (PLAYER_SWING)
        Spinners_EditMode.lua   dragging in Edit Mode, and the size and opacity dialog
        Spinners_Reticle.lua    hiding the gamepad UI's own swing timer
        Spinners.lua            creating the spinners, and applying the settings

    The game's own swing timer bars are left alone, so both can be used.
]]

local env = select(2, ...)
local Config = env.Config
local L = env.L
local Spinners = env.AX_Modules:New("@\\Spinners")
local Private = env.AX_Modules:New("@\\Spinners\\Private")

---@class SpinnerSelection : Frame
---@field ShowHighlighted fun(self)
---@field ShowSelected fun(self)
---@field ShowEditInstructions fun(self, shown: boolean)
---@field GetLabelText fun(self): string

-- The circle's bar, a texture with a radial progress bar (WoW Forever's API, which the editor's
-- API list doesn't have).
---@class SpinnerLoadBar : Texture
---@field SetRadialProgressBarPercent fun(self, percent: number)

-- One way a spinner can be drawn: the whole circle, or its left or right half.
---@class SpinnerParts
---@field bar SpinnerLoadBar
---@field glow Texture
---@field tip Texture
---@field anim AnimationGroup
---@field tipStart number the tip's rotation before a swing, in radians
---@field tipTurn number how far the tip turns over a swing, in radians

---@class Spinner : Frame
---@field Anim AnimationGroup
---@field LeftAnim AnimationGroup
---@field RightAnim AnimationGroup
---@field LoadBarBG Texture
---@field LoadBarGlow Texture
---@field LeftLoadBarGlow Texture
---@field RightLoadBarGlow Texture
---@field LoadBar SpinnerLoadBar
---@field LeftLoadBar SpinnerLoadBar
---@field RightLoadBar SpinnerLoadBar
---@field SpinnerTip Texture
---@field LeftSpinnerTip Texture
---@field RightSpinnerTip Texture
---@field Countdown FontString
---@field sides table<string, SpinnerParts> "Full", "Left" and "Right"
---@field side string which of `sides` it's drawn as
---@field parts SpinnerParts the one of `sides` it's drawn as
---@field follows Spinner? the spinner it sits on, with its size and opacity (Combine With Main Hand)
---@field info table
---@field hasWeapon boolean
---@field swinging boolean its swing is filling
---@field draining boolean the circle empties instead of filling (Spinner Behavior)
---@field startTime number when the swing started
---@field endTime number when the swing is ready, for the countdown
---@field selection SpinnerSelection?

-- The Size and Opacity sliders' limits, in percent, in the settings and Edit Mode's dialog.
Spinners.SCALE_MIN, Spinners.SCALE_MAX = 50, 300
Spinners.OPACITY_MIN, Spinners.OPACITY_MAX = 10, 100
Spinners.READY_OPACITY_MIN, Spinners.READY_OPACITY_MAX = 0, 100
Spinners.PERCENT_STEP = 5

-- Each spinner's setting keys, label and default location (an offset from the screen's center).
Private.SPINNERS = {
    { key = "MainHand", label = L["Spinner - MainHand"], x = -120, y = -80 },
    { key = "OffHand", label = L["Spinner - OffHand"], x = -90, y = -80 },
    { key = "Ranged", label = L["Spinner - Ranged"], x = -120, y = -110 },
}

-- Swing types: MainHand, OffHand and Ranged. Only WoW Forever has them, so the editor's API
-- list doesn't.
Private.PlayerSwingType = Enum["PlayerSwingType"] ---@type table<string, number>

Private.spinners = {} ---@type Spinner[]
Private.bySwingType = {} ---@type table<number, Spinner>
Private.inCombat = false
Private.editing = false -- Edit Mode is open

--- One of `spinner`'s settings.
---@param spinner Spinner
---@param setting string "Color", "GameColor", "Scale", "Opacity", or "" for whether it's used
---@return string key a Config.Key value
function Private.KeyOf(spinner, setting)
    return Config.Key[spinner.info.key .. setting]
end

--- The spinner whose size and opacity `spinner` uses: the one it follows, or itself.
---@param spinner Spinner
---@return Spinner
function Private.LookOf(spinner)
    return spinner.follows or spinner
end

--- Whether `spinner` is turned on in the settings.
---@param spinner Spinner
---@return boolean
function Private.IsUsed(spinner)
    return Config.Get(Private.KeyOf(spinner, "")) == true
end

--- Whether the spinners can work at all. Only WoW Forever has swing timer events.
---@return boolean
function Private.IsOn()
    return env.HAS_SWING_EVENTS
end
