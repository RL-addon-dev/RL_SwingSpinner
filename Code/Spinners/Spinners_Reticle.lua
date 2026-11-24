--[[
    Spinners (Spinners_Shared.lua): the gamepad UI's own swing timer, the circle on its reticle.
    It's hidden each time it shows while any spinner is turned on, so the two don't show at once.
    Nothing about it is changed, so it works as before with the spinners off.
]]

local env = select(2, ...)
local Private = env.AX_Modules:Import("@\\Spinners\\Private")

--- Whether any spinner is turned on.
---@return boolean
local function AnyUsed()
    if not Private.IsOn() then return false end
    for _, spinner in ipairs(Private.spinners) do
        if Private.IsUsed(spinner) then return true end
    end
    return false
end

---@param timer Frame
local function OnReticleTimerShow(timer)
    if AnyUsed() then timer:Hide() end
end

--- Hooks the reticle's swing timer, once Blizzard_Gamepad has made it.
---@return boolean hooked
local function Hook()
    local reticle = _G["GamepadReticle"]
    local timer = reticle and reticle.SwingTimer
    if not timer then return false end
    timer:HookScript("OnShow", OnReticleTimerShow)
    if timer:IsShown() then OnReticleTimerShow(timer) end
    return true
end

--- Hides the reticle's swing timer from now on, or once Blizzard_Gamepad loads.
function Private.SetUpReticle()
    if Hook() then return end
    local waiter = CreateFrame("Frame")
    waiter:RegisterEvent("ADDON_LOADED")
    waiter:SetScript("OnEvent", function(self, _, name)
        if name == "Blizzard_Gamepad" and Hook() then self:UnregisterAllEvents() end
    end)
end
