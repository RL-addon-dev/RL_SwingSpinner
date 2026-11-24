--[[
    Setting_Schema: the settings, in the General tab, a tab for each spinner, and About.

    The schema's format (every widget type and field) is in libs\AX_Settings\README.md, with a
    full example in libs\AX_Settings\Examples\Schema.example.lua.
]]

local env = select(2, ...)
local Config = env.Config
local L = env.L
local CallbackRegistry = env.AX_Modules:Import("ax_modules\\callback-registry")
local Setting_Define = env.AX_Modules:Import("@\\Setting\\Define")
local Setting_Enum = env.AX_Modules:Import("@\\Setting\\Enum")
local Spinners = env.AX_Modules:Import("@\\Spinners")
local Setting_Schema = env.AX_Modules:New("@\\Setting\\Schema")

local WidgetType = Setting_Enum.WidgetType

local function RefreshShown()
    CallbackRegistry.Trigger(Setting_Enum.Event.Refresh)
end

-- The other Spinner Visibility checkboxes are off while Always is ticked.
local function IsAlways() return Config.Get(Config.Key.ShowAlways) == true end
Config.OnChange(Config.Key.ShowAlways, RefreshShown)

-- Fade Opacity only shows with Idle Style = Fade.
local function IsFaded() return Config.Get(Config.Key.ReadyStyle) == env.Enum.ReadyStyle.Faded end
Config.OnChange(Config.Key.ReadyStyle, RefreshShown)



-- Row builders

--- A row's description, L[nameKey .. " - Description"], or none when it has no text.
---@param nameKey string
---@return table?
local function Description(nameKey)
    local text = L[nameKey .. " - Description"]
    return text and Setting_Define.Descriptor{ description = text } or nil
end

--- A checkbox row. Its name is L[nameKey], and its description L[nameKey .. " - Description"].
---@param nameKey string
---@param key string a Config.Key value
---@param showWhen function?
---@param disableWhen function?
---@return table
local function CheckButton(nameKey, key, showWhen, disableWhen)
    return {
        widgetName        = L[nameKey],
        widgetDescription = Description(nameKey),
        widgetType        = WidgetType.CheckButton,
        key               = key,
        showWhen          = showWhen,
        disableWhen       = disableWhen
    }
end

--- A dropdown row. Its options are L[nameKey .. " - <n>"], in the order of their Enum values.
---@param nameKey string
---@param key string a Config.Key value
---@param count number how many options
---@param showWhen function?
---@return table
local function Dropdown(nameKey, key, count, showWhen)
    local options = {}
    for i = 1, count do options[i] = L[nameKey .. " - " .. i] end
    return {
        widgetName               = L[nameKey],
        widgetDescription        = Description(nameKey),
        widgetType               = WidgetType.SelectionMenu,
        widgetSelectionMenu_data = options,
        key                      = key,
        showWhen                 = showWhen
    }
end

--- A percent slider row.
---@param nameKey string
---@param key string a Config.Key value
---@param min number
---@param max number
---@param showWhen function
---@return table
local function Percent(nameKey, key, min, max, showWhen)
    return {
        widgetName                 = L[nameKey],
        widgetDescription          = Description(nameKey),
        widgetType                 = WidgetType.Range,
        widgetRange_min            = min,
        widgetRange_max            = max,
        widgetRange_step           = Spinners.PERCENT_STEP,
        widgetRange_textFormatting = "%s%%",
        key                        = key,
        showWhen                   = showWhen
    }
end

--- A button row. Its button's text is L[nameKey .. " - Button"].
---@param nameKey string
---@param onClick function
---@return table
local function Button(nameKey, onClick)
    return {
        widgetName        = L[nameKey],
        widgetDescription = Description(nameKey),
        widgetType        = WidgetType.Button,
        widgetButton_text = L[nameKey .. " - Button"],
        set               = onClick
    }
end

--- A spinner's tab: whether it's used, then its settings, which only show while it is.
---@param key string "MainHand", "OffHand" or "Ranged"
---@param extra table? a row after Enable
---@param hasOwnLook function? whether its size and opacity are its own, so they show
---@return table
local function SpinnerTab(key, extra, hasOwnLook)
    local function IsUsed() return Config.Get(Config.Key[key]) end
    local function ShowLook() return IsUsed() and (not hasOwnLook or hasOwnLook()) end
    local function ShowColor() return IsUsed() and not Config.Get(Config.Key[key .. "GameColor"]) end
    Config.OnChange(Config.Key[key], RefreshShown)
    Config.OnChange(Config.Key[key .. "GameColor"], RefreshShown)
    -- Edit Mode's dialog changes the size and opacity too.
    Config.OnChange(Config.Key[key .. "Scale"], RefreshShown)
    Config.OnChange(Config.Key[key .. "Opacity"], RefreshShown)
    local settings = {
        widgetName = L["Spinner - " .. key],
        widgetType = WidgetType.Container,
        children   = {
            -- Its description says when this spinner shows.
            {
                widgetName        = L["Config - Spinner - Enable"],
                widgetDescription = Description("Config - Spinner - Enable - " .. key),
                widgetType        = WidgetType.CheckButton,
                key               = Config.Key[key]
            },
            CheckButton("Config - Spinner - GameColor", Config.Key[key .. "GameColor"], IsUsed),
            {
                widgetName = L["Config - Spinner - Color"],
                widgetType = WidgetType.ColorInput,
                key        = Config.Key[key .. "Color"],
                -- The picker can hand back the same table again, which the saved variables don't
                -- see as a change.
                set        = function() Spinners.RefreshAll() end,
                showWhen   = ShowColor
            },
            Percent("Config - Spinner - Size", Config.Key[key .. "Scale"],
                Spinners.SCALE_MIN, Spinners.SCALE_MAX, ShowLook),
            Percent("Config - Spinner - Opacity", Config.Key[key .. "Opacity"],
                Spinners.OPACITY_MIN, Spinners.OPACITY_MAX, ShowLook),
        }
    }
    if extra then
        extra.showWhen = IsUsed
        table.insert(settings.children, 2, extra)
    end
    return {
        widgetName = L["Spinner - " .. key],
        widgetType = WidgetType.Tab,
        children   = { settings }
    }
end

-- The off hand's own size and opacity hide while it's combined with the main hand, whose apply.
local function IsOffHandOwnLook()
    return not (Config.Get(Config.Key.CombineHands) and Config.Get(Config.Key.MainHand))
end
Config.OnChange(Config.Key.CombineHands, RefreshShown)

--- An About tab text row, on the page's background.
---@param nameKey string
---@return table
local function Credit(nameKey)
    return {
        widgetName        = L[nameKey],
        widgetType        = WidgetType.Text,
        widgetDescription = Description(nameKey),
        widgetTransparent = true
    }
end



Setting_Schema.SCHEMA = {
    {
        widgetName = L["Config - General"],
        widgetType = WidgetType.Tab,
        children   = {
            {
                widgetName = L["Config - ShowWhen"],
                widgetType = WidgetType.Container,
                children   = {
                    CheckButton("Config - ShowAlways", Config.Key.ShowAlways),
                    CheckButton("Config - ShowWithTarget", Config.Key.ShowWithTarget, nil, IsAlways),
                    CheckButton("Config - ShowInCombat", Config.Key.ShowInCombat, nil, IsAlways),
                    CheckButton("Config - ShowRecharging", Config.Key.ShowRecharging, nil, IsAlways),
                }
            },
            {
                widgetName = L["Config - General"],
                widgetType = WidgetType.Container,
                children   = {
                    Dropdown("Config - ReadyStyle", Config.Key.ReadyStyle, 4),
                    Percent("Config - ReadyOpacity", Config.Key.ReadyOpacity,
                        Spinners.READY_OPACITY_MIN, Spinners.READY_OPACITY_MAX, IsFaded),
                    Dropdown("Config - FillDirection", Config.Key.FillDirection, 2),
                    CheckButton("Config - Countdown", Config.Key.Countdown),
                }
            },
            {
                widgetName = L["Config - Position"],
                widgetType = WidgetType.Container,
                children   = {
                    {
                        widgetName        = L["Config - Position - EditMode"],
                        widgetDescription = Description("Config - Position - EditMode"),
                        widgetType        = WidgetType.Text
                    },
                    Button("Config - Position - Reset", Spinners.ResetPositions),
                }
            },
        }
    },
    SpinnerTab("MainHand"),
    SpinnerTab("OffHand", CheckButton("Config - CombineHands", Config.Key.CombineHands), IsOffHandOwnLook),
    SpinnerTab("Ranged"),
    {
        widgetName         = L["Config - About"],
        widgetType         = WidgetType.Tab,
        widgetTab_isFooter = true,
        children           = {
            {
                widgetName       = L["Config - About"],
                widgetType       = WidgetType.Title,
                widgetTitle_info = Setting_Define.TitleInfo{
                    imagePath = env.ICON, text = env.NAME_ALT, subtext = env.VERSION_STRING
                }
            },
            {
                widgetName        = L["Config - About - Inspirations"],
                widgetType        = WidgetType.Container,
                widgetTransparent = true,
                children          = { Credit("Config - About - Inspirations - WaypointUI") }
            },
            {
                widgetName        = L["Config - About - Developer"],
                widgetType        = WidgetType.Container,
                widgetTransparent = true,
                children          = { Credit("Config - About - Developer - Name") }
            },
        }
    },
}
