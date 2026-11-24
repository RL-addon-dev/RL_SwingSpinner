--[[
    The public API, for other addons and macros. It's the global RLWeaponSwingSpinnerAPI.

        RLWeaponSwingSpinnerAPI.OpenSettingUI()   opens the settings window, or closes it when open

    RLWeaponSwingSpinnerAPI_OpenSettingUI is the same function, as a plain global for the .toc's
    AddonCompartmentFunc (the minimap addon drawer).
]]

local env = select(2, ...)

---@class RLWeaponSwingSpinnerAPI
---@field OpenSettingUI fun() opens the settings window, or closes it when it's open
RLWeaponSwingSpinnerAPI = RLWeaponSwingSpinnerAPI or {}

do
    local Setting = env.AX_Modules:Await("@\\Setting")
    RLWeaponSwingSpinnerAPI_OpenSettingUI = Setting.OpenSettingUI
    RLWeaponSwingSpinnerAPI.OpenSettingUI = Setting.OpenSettingUI
end
