--[[
    The public API, for other addons and macros. It's the global RLSwingSpinnerAPI.

        RLSwingSpinnerAPI.OpenSettingUI()   opens the settings window, or closes it when open

    RLSwingSpinnerAPI_OpenSettingUI is the same function, as a plain global for the .toc's
    AddonCompartmentFunc (the minimap addon drawer).
]]

local env = select(2, ...)

---@class RLSwingSpinnerAPI
---@field OpenSettingUI fun() opens the settings window, or closes it when it's open
RLSwingSpinnerAPI = RLSwingSpinnerAPI or {}

do
    local Setting = env.AX_Modules:Await("@\\Setting")
    RLSwingSpinnerAPI_OpenSettingUI = Setting.OpenSettingUI
    RLSwingSpinnerAPI.OpenSettingUI = Setting.OpenSettingUI
end
