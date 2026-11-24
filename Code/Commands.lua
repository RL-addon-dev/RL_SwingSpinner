--[[
    The slash commands: /rlss and /swingspinner open the settings, or close
    them when open.
]]

local env = select(2, ...)
local SlashCommand = env.AX_Modules:Import("ax_modules\\slash-command")
local Setting = env.AX_Modules:Await("@\\Setting")

SlashCommand.AddFromSchema({
    {
        name     = "RLSWINGSPINNER",
        command  = { "rlss", "swingspinner" },
        callback = function() Setting.OpenSettingUI() end
    }
})
