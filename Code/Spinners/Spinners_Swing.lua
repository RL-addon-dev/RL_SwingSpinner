--[[
    Spinners (Spinners_Shared.lua): the swing spinners. Each fills as its weapon's swing comes
    round (PLAYER_SWING), with the game's animation, or drains with Spinner Behavior = Drain. They
    only show for weapons you have equipped. Combat is followed for Spinner Visibility.
]]

local env = select(2, ...)
local Private = env.AX_Modules:Import("@\\Spinners\\Private")

local driver = CreateFrame("Frame")



-- Weapons

--- Whether `spinner`'s weapon is equipped, from its attack speed. The speed is secret in combat,
--- so the last answer is kept until combat ends.
---@param spinner Spinner
---@param speed number?
local function SetHasWeapon(spinner, speed)
    if speed ~= nil and issecretvalue(speed) then return end
    spinner.hasWeapon = speed ~= nil and speed > 0
end

--- Which weapons are equipped. The main hand always swings, even unarmed. An off hand weapon
--- coming or going splits or joins a combined circle.
local function RefreshWeapons()
    local _, offHandSpeed, rangedSpeed = UnitAttackSpeed("player")
    local bySwingType, swingType = Private.bySwingType, Private.PlayerSwingType
    bySwingType[swingType.MainHand].hasWeapon = true
    SetHasWeapon(bySwingType[swingType.OffHand], offHandSpeed)
    SetHasWeapon(bySwingType[swingType.Ranged], rangedSpeed)
    Private.RefreshLayout()
end



-- Combat

--- Whether you're in combat, the way the game's own swing timer bars check: from the moment you
--- start attacking, not only once a fight is under way (PLAYER_REGEN_DISABLED, which waits for
--- the first hit). A secret answer counts as yes.
local function RefreshInCombat()
    local affecting = UnitAffectingCombat("player")
    Private.inCombat = issecretvalue(affecting) or affecting == true or InCombatLockdown() == true
end



-- Swings

---@param duration number
---@param swingType number
local function PlaySwing(duration, swingType)
    local spinner = Private.bySwingType[swingType]
    if not spinner or issecretvalue(duration) then return end
    local parts = spinner.parts
    spinner.swinging = true
    parts.bar:Show()
    parts.glow:Show()
    parts.tip:Show()
    spinner.startTime = GetTime()
    spinner.endTime = spinner.startTime + duration
    spinner.Countdown:SetShown(Private.WantsCountdown(spinner))
    Private.RefreshAlpha(spinner)
    if Private.IsDrain() then
        parts.anim:Stop()
        spinner.draining = true
        spinner:SetScript("OnUpdate", Private.UpdateProgress)
        Private.UpdateProgress(spinner)
        return
    end
    spinner.draining = false
    for _, part in ipairs({ parts.anim:GetAnimations() }) do
        part:SetDuration(duration)
    end
    parts.anim:Restart()
    if spinner.Countdown:IsShown() then
        Private.UpdateCountdown(spinner)
        spinner:SetScript("OnUpdate", Private.UpdateCountdown)
    end
end

--- Readies a swing spinner when its animation finishes, whole circle or half.
---@param spinner Spinner
function Private.SetUpSwing(spinner)
    for _, parts in pairs(spinner.sides) do
        parts.anim:SetScript("OnFinished", function()
            Private.ShowReady(spinner)
            Private.RefreshShown()
        end)
    end
end



-- Events

driver:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_SWING" then
        PlaySwing(...)
    elseif event == "PLAYER_IN_COMBAT_CHANGED" or event == "PLAYER_REGEN_DISABLED" then
        RefreshInCombat()
    elseif event == "PLAYER_REGEN_ENABLED" then
        RefreshInCombat()
        RefreshWeapons()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "UNIT_INVENTORY_CHANGED" then
        RefreshWeapons()
    end
    -- PLAYER_TARGET_CHANGED only changes what's shown.
    Private.RefreshShown()
end)

--- Listens for swings, combat, targets and gear, while the spinners are on.
---@param on boolean
function Private.RefreshSwingEvents(on)
    if not on then
        driver:UnregisterAllEvents()
        return
    end
    driver:RegisterEvent("PLAYER_SWING")
    driver:RegisterEvent("PLAYER_ENTERING_WORLD")
    driver:RegisterEvent("PLAYER_IN_COMBAT_CHANGED")
    driver:RegisterEvent("PLAYER_REGEN_DISABLED")
    driver:RegisterEvent("PLAYER_REGEN_ENABLED")
    driver:RegisterEvent("PLAYER_TARGET_CHANGED")
    driver:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
    RefreshInCombat()
    RefreshWeapons()
end
