--[[
    The slash commands: /wss, /swingspinner and /weaponswingspinner open the settings, or close
    them when open.
]]

local env = select(2, ...)
local SlashCommand = env.AX_Modules:Import("ax_modules\\slash-command")
local Setting = env.AX_Modules:Await("@\\Setting")

SlashCommand.AddFromSchema({
    {
        name     = "RLWEAPONSWINGSPINNER",
        command  = { "wss", "swingspinner", "weaponswingspinner" },
        callback = function() Setting.OpenSettingUI() end
    }
})
