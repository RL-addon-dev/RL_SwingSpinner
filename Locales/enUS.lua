-- The English strings, and the base for other locales: a key they don't translate shows this
-- text. Grouped by area, as the settings show them, and sorted by key within each group.



local env = select(2, ...)
local L = env.L

-- Spinners
L["Spinner - MainHand"] = "Main Hand"
L["Spinner - OffHand"] = "Off Hand"
L["Spinner - Ranged"] = "Ranged"

-- General
L["Config - Countdown"] = "Show Countdown"
L["Config - FillDirection"] = "Spinner Behavior"
L["Config - FillDirection - 1"] = "Fill"
L["Config - FillDirection - 2"] = "Drain"
L["Config - General"] = "General"
L["Config - ReadyOpacity"] = "Fade Opacity"
L["Config - ReadyStyle"] = "Idle Style"
L["Config - ReadyStyle - 1"] = "Empty"
L["Config - ReadyStyle - 2"] = "Fade"
L["Config - ReadyStyle - 3"] = "Full"
L["Config - ReadyStyle - 4"] = "Hidden"
L["Config - ReadyStyle - Description"] = "How a spinner looks once its weapon is ready to swing."

-- Spinner Visibility
L["Config - ShowAlways"] = "Always"
L["Config - ShowAlways - Description"] = "Spinners show all the time, for weapons you have equipped."
L["Config - ShowInCombat"] = "In Combat"
L["Config - ShowInCombat - Description"] =
"Spinners show while you're in combat, whether you start the fight or an enemy attacks you."
L["Config - ShowRecharging"] = "Swing Recharging"
L["Config - ShowRecharging - Description"] = "Each spinner shows while its next swing fills."
L["Config - ShowWhen"] = "Spinner Visibility"
L["Config - ShowWithTarget"] = "Enemy Targeted"
L["Config - ShowWithTarget - Description"] = "An enemy you can attack is targeted."

-- Position
L["Config - Position"] = "Position"
L["Config - Position - EditMode"] = "Edit Mode"
L["Config - Position - EditMode - Description"] =
"Open Edit Mode to drag each spinner where you want it. Click one to change its size and opacity."
L["Config - Position - Reset"] = "Reset Positions"
L["Config - Position - Reset - Button"] = "Reset"

-- Each spinner
L["Config - CombineHands"] = "Combine With Main Hand"
L["Config - CombineHands - Description"] =
"Shares the main hand's circle as its left half. " ..
"It uses the main hand's location, size and opacity."
L["Config - Spinner - Color"] = "Color"
L["Config - Spinner - GameColor"] = "Default Color"
L["Config - Spinner - GameColor - Description"] = "Uses the game's own colors. Untick it to pick your own."
L["Config - Spinner - Opacity"] = "Opacity"
L["Config - Spinner - Enable"] = "Enable"
L["Config - Spinner - Enable - MainHand - Description"] =
"Spinner shows for main hand swings, with a main hand weapon equipped or unarmed."
L["Config - Spinner - Enable - OffHand - Description"] = "Spinner only shows when an off hand weapon is equipped."
L["Config - Spinner - Enable - Ranged - Description"] = "Spinner only shows when a ranged weapon is equipped."
L["Config - Spinner - Size"] = "Size"

-- About
L["Config - About"] = "About"
L["Config - About - Developer"] = "Developer"
L["Config - About - Developer - Name"] = "RL"
L["Config - About - Developer - Name - Description"] = "Just a dude doing this for fun"
L["Config - About - Inspirations"] = "Addon Inspirations"
L["Config - About - Inspirations - WaypointUI"] = "WaypointUI by AdaptiveX"
L["Config - About - Inspirations - WaypointUI - Description"] =
"Core of this addon's settings UI was based on AdaptiveX's hard work."
