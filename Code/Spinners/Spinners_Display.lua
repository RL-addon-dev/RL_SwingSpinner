--[[
    Spinners (Spinners_Shared.lua): how a spinner looks and when it shows. Its color, location,
    opacity and countdown font, whether it's a whole circle or half of one (Combine With Main
    Hand), its circle as a swing goes on, its look once ready (Idle Style), and whether it shows at
    all (Spinner Visibility).
]]

local env = select(2, ...)
local Config = env.Config
local Private = env.AX_Modules:Import("@\\Spinners\\Private")

local KeyOf = Private.KeyOf

local COUNTDOWN_SHRINK = 2.5 -- points off the countdown's font, to fit inside the circle

-- The textures and animation of each way a spinner can be drawn, by their names' prefix in
-- Spinners.xml, and how its tip turns. The halves' tips start upside down, at the bottom.
local SIDES = {
    Full  = { prefix = "", tipStart = 0, tipTurn = -2 * math.pi },
    Left  = { prefix = "Left", tipStart = math.pi, tipTurn = -math.pi },
    Right = { prefix = "Right", tipStart = math.pi, tipTurn = math.pi },
}



-- Look

--- Makes `spinner`'s countdown a little smaller than its font.
---@param spinner Spinner
function Private.SetUpFonts(spinner)
    local font, size, flags = spinner.Countdown:GetFont()
    if font then spinner.Countdown:SetFont(font, size - COUNTDOWN_SHRINK, flags) end
end

--- Gathers each way `spinner` can be drawn (SIDES), and starts it as a whole circle.
---@param spinner Spinner
function Private.SetUpSides(spinner)
    spinner.sides = {}
    for side, info in pairs(SIDES) do
        spinner.sides[side] = {
            bar      = spinner[info.prefix .. "LoadBar"],
            glow     = spinner[info.prefix .. "LoadBarGlow"],
            tip      = spinner[info.prefix .. "SpinnerTip"],
            anim     = spinner[info.prefix .. "Anim"],
            tipStart = info.tipStart,
            tipTurn  = info.tipTurn,
        }
    end
    spinner.side = "Full"
    spinner.parts = spinner.sides.Full
end

--- Tints a spinner's circle, glow and tip with its Color setting, or leaves the game's own art
--- with Default Color.
---@param spinner Spinner
local function Tint(spinner)
    local gameColor = Config.Get(KeyOf(spinner, "GameColor")) == true
    local color = Config.Get(KeyOf(spinner, "Color"))
    local r, g, b = color.r, color.g, color.b
    if gameColor then r, g, b = 1, 1, 1 end
    for _, parts in pairs(spinner.sides) do
        for _, texture in ipairs({ parts.bar, parts.glow, parts.tip }) do
            texture:SetDesaturated(not gameColor)
            texture:SetVertexColor(r, g, b)
        end
    end
end

--- Puts `spinner` at its saved location, or its default one. A spinner that follows another sits on
--- top of it.
---@param spinner Spinner
function Private.Place(spinner)
    spinner:ClearAllPoints()
    if spinner.follows then
        spinner:SetPoint("CENTER", spinner.follows, "CENTER")
        return
    end
    local position = Config.GetPersistent().positions
    position = position and position[spinner.info.key]
    -- Positions are saved in the screen's scale, and the spinner's own scale changes its offsets.
    local scale = spinner:GetScale()
    spinner:SetPoint("CENTER", UIParent, "CENTER", (position and position.x or spinner.info.x) / scale,
        (position and position.y or spinner.info.y) / scale)
end

--- The spinner's opacity: its Opacity setting, or Fade Opacity while it's ready with When
--- Ready = Fade. Edit Mode shows it unfaded.
---@param spinner Spinner
function Private.RefreshAlpha(spinner)
    local alpha = Config.Get(KeyOf(Private.LookOf(spinner), "Opacity")) / 100
    local faded = Config.Get(Config.Key.ReadyStyle) == env.Enum.ReadyStyle.Faded
    if faded and not spinner.swinging and not Private.editing then
        alpha = Config.Get(Config.Key.ReadyOpacity) / 100
    end
    spinner:SetAlpha(alpha)
end



-- Combining the hands

--- Draws `spinner` as a whole circle or one half of it, ready to swing.
---@param spinner Spinner
---@param side string "Full", "Left" or "Right"
local function SetSide(spinner, side)
    if spinner.side == side then return end
    for _, parts in pairs(spinner.sides) do
        parts.anim:Stop()
        parts.bar:Hide()
        parts.glow:Hide()
        parts.tip:Hide()
    end
    spinner.side = side
    spinner.parts = spinner.sides[side]
    -- The main hand's background ring is the whole circle's.
    spinner.LoadBarBG:SetShown(side ~= "Left")
    Private.ShowReady(spinner)
end

--- With Combine With Main Hand, the off hand follows the main hand, on top of it with its size
--- and opacity. While an off hand weapon is equipped (or in Edit Mode) they split the circle like
--- the gamepad UI's: the off hand is the left half and the main hand the right.
function Private.RefreshLayout()
    local main = Private.bySwingType[Private.PlayerSwingType.MainHand]
    local off = Private.bySwingType[Private.PlayerSwingType.OffHand]
    if not (main and off) then return end
    local follows = Config.Get(Config.Key.CombineHands) and Private.IsUsed(main) and Private.IsUsed(off)
    local split = follows and (off.hasWeapon or Private.editing)
    SetSide(main, split and "Right" or "Full")
    SetSide(off, follows and "Left" or "Full")
    if (off.follows ~= nil) ~= (follows == true) then
        off.follows = follows and main or nil
        Private.RefreshLook()
    end
end



-- Showing

--- Whether an enemy you could attack is targeted. Secret answers count as yes.
local function HasEnemyTarget()
    local canAttack = UnitCanAttack("player", "target")
    if issecretvalue(canAttack) then return true end
    if canAttack ~= true then return false end
    local dead = UnitIsDead("target")
    return issecretvalue(dead) or not dead
end

--- Whether the Spinner Visibility settings want every spinner shown now: any ticked one is
--- true. Swing Recharging is each spinner's own (RefreshShown).
local function IsShowTime()
    local Key = Config.Key
    if Config.Get(Key.ShowAlways) then return true end
    if Config.Get(Key.ShowInCombat) and Private.inCombat then return true end
    return Config.Get(Key.ShowWithTarget) == true and HasEnemyTarget()
end

--- Shows each spinner when the settings say, and all of the turned on ones in Edit Mode. One
--- that follows another moves with it, so it can't be selected.
function Private.RefreshShown()
    Private.RefreshLayout()
    local on = Private.IsOn()
    local showTime = IsShowTime()
    local hideReady = Config.Get(Config.Key.ReadyStyle) == env.Enum.ReadyStyle.Hidden
    local whileRecharging = Config.Get(Config.Key.ShowRecharging) == true
    for _, spinner in ipairs(Private.spinners) do
        local enabled = on and Private.IsUsed(spinner)
        local edit = Private.editing and enabled
        local selectable = edit and not spinner.follows
        local selection = spinner.selection
        if selection and selectable and not selection:IsShown() then
            selection:ShowHighlighted()
        elseif selection and not selectable then
            selection:Hide()
        end
        local wanted = (showTime and (spinner.swinging or not hideReady)) or (whileRecharging and spinner.swinging)
        local shown = edit or (enabled and spinner.hasWeapon and wanted)
        spinner:SetShown(shown)
        Private.RefreshAlpha(spinner)
    end
end



-- Progress

--- Fills, empties or fades a spinner's circle (Idle Style), since its weapon is ready to swing.
---@param spinner Spinner
function Private.ShowReady(spinner)
    local parts = spinner.parts
    spinner.swinging = false
    parts.anim:Stop()
    parts.tip:SetRotation(parts.tipStart)
    local full = Config.Get(Config.Key.ReadyStyle) ~= env.Enum.ReadyStyle.Empty
    parts.bar:SetRadialProgressBarPercent(1)
    parts.glow:SetAlpha(1)
    -- Empty leaves only the background ring, since the bar still shows a sliver at 0. The tip
    -- only leads a swing, so a full circle is one even color.
    parts.bar:SetShown(full)
    parts.glow:SetShown(full)
    parts.tip:Hide()
    spinner.Countdown:Hide()
    spinner:SetScript("OnUpdate", nil)
    Private.RefreshAlpha(spinner)
end

--- The seconds left, in the middle of the circle.
---@param spinner Spinner
function Private.UpdateCountdown(spinner)
    local remaining = spinner.endTime - GetTime()
    spinner.Countdown:SetFormattedText("%.1f", remaining > 0 and remaining or 0)
end

--- Whether the Spinner Behavior setting is Drain.
---@return boolean
function Private.IsDrain()
    return Config.Get(Config.Key.FillDirection) == env.Enum.FillDirection.Drain
end

--- Sets a spinner's circle to how far its swing is, each frame. It fills, or drains when
--- `spinner.draining`. A draining swing is driven here instead of by its animation, and ends here.
---@param spinner Spinner
function Private.UpdateProgress(spinner)
    local parts = spinner.parts
    local now = GetTime()
    local length = spinner.endTime - spinner.startTime
    local done = length > 0 and (now - spinner.startTime) / length or 1
    done = math.min(math.max(done, 0), 1)
    if spinner.draining then done = 1 - done end
    parts.bar:SetRadialProgressBarPercent(done)
    parts.glow:SetAlpha(done)
    parts.tip:SetRotation(parts.tipStart + parts.tipTurn * done)
    if spinner.Countdown:IsShown() then Private.UpdateCountdown(spinner) end
    if spinner.swinging and now >= spinner.endTime then
        Private.ShowReady(spinner)
        Private.RefreshShown()
    end
end

--- Applies the look settings: each spinner's size, opacity, location and color, and the countdown.
function Private.RefreshLook()
    Private.RefreshLayout()
    for _, spinner in ipairs(Private.spinners) do
        spinner:SetScale(Config.Get(KeyOf(Private.LookOf(spinner), "Scale")) / 100)
        Private.RefreshAlpha(spinner)
        Private.Place(spinner)
        Tint(spinner)
        if not spinner.swinging then
            Private.ShowReady(spinner)
        elseif not Private.WantsCountdown(spinner) then
            spinner.Countdown:Hide()
            -- A draining swing still needs its updates.
            if spinner:GetScript("OnUpdate") == Private.UpdateCountdown then spinner:SetScript("OnUpdate", nil) end
        end
    end
end

--- Whether `spinner` shows its countdown. One that follows another leaves the middle to it.
---@param spinner Spinner
---@return boolean
function Private.WantsCountdown(spinner)
    return Config.Get(Config.Key.Countdown) == true and not spinner.follows
end
