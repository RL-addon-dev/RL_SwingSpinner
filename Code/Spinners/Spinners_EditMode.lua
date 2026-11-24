--[[
    Spinners (Spinners_Shared.lua) in Edit Mode: each spinner can be dragged, and clicking one
    selects it and opens a small dialog with its size, opacity and Reset Position. The dialog is
    like Edit Mode's own settings dialog, built from the same templates.

    The spinners are never registered as Edit Mode systems, so Edit Mode itself is never tainted.
]]

local env = select(2, ...)
local Config = env.Config
local L = env.L
local Spinners = env.AX_Modules:Import("@\\Spinners")
local Private = env.AX_Modules:Import("@\\Spinners\\Private")

local KeyOf = Private.KeyOf

local SELECTION_PADDING = 12 -- the circle is too small for Edit Mode's label
local DIALOG_WIDTH, DIALOG_PADDING, ROW_HEIGHT = 320, 16, 36



-- The dialog

---@class SpinnerDialog : Frame
---@field Title FontString
---@field CloseButton Button
---@field ResetButton Button

---@class SpinnerDialogSlider : Frame
---@field Init fun(self, value: number, minValue: number, maxValue: number, steps: number, formatters: table)
---@field RegisterCallback fun(self, event: string, callback: function, owner: any)

local selected ---@type Spinner? the spinner whose dialog is open
local Dialog ---@type SpinnerDialog
local dialogSliders = {} -- { setting, slider, min, max }
local settingFromDialog = false -- a dialog slider is saving, so the dialog isn't filled again

--- A labelled slider row in the dialog, for the selected spinner's `setting`.
---@param row number
---@param label string
---@param setting string "Scale" or "Opacity"
---@param min number
---@param max number
local function AddDialogSlider(row, label, setting, min, max)
    local top = -52 - (row - 1) * ROW_HEIGHT
    local text = Dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOPLEFT", DIALOG_PADDING, top)
    text:SetWidth(70)
    text:SetJustifyH("LEFT")
    text:SetText(label)

    local slider = CreateFrame("Frame", nil, Dialog, "MinimalSliderWithSteppersTemplate") --[[@as SpinnerDialogSlider]]
    slider:SetPoint("LEFT", text, "RIGHT", 8, 0)
    slider:SetPoint("RIGHT", Dialog, "RIGHT", -DIALOG_PADDING - 30, 0)
    slider:SetHeight(32)
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        if not selected then return end
        local key = KeyOf(selected, setting)
        if value == Config.Get(key) then return end
        settingFromDialog = true
        Config.Set(key, value)
        settingFromDialog = false
    end, Dialog)
    dialogSliders[#dialogSliders + 1] = { setting = setting, slider = slider, min = min, max = max }
end

local function CreateDialog()
    Dialog = CreateFrame("Frame", nil, UIParent, "DialogBorderTranslucentTemplate") --[[@as SpinnerDialog]]
    Dialog:SetSize(DIALOG_WIDTH, 52 + 2 * ROW_HEIGHT + 24 + 2 * DIALOG_PADDING)
    Dialog:SetFrameStrata("DIALOG")
    Dialog:SetClampedToScreen(true)
    Dialog:EnableMouse(true)
    Dialog:Hide()

    Dialog.Title = Dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    Dialog.Title:SetPoint("TOP", 0, -DIALOG_PADDING)

    Dialog.CloseButton = CreateFrame("Button", nil, Dialog, "UIPanelCloseButton") --[[@as Button]]
    Dialog.CloseButton:SetPoint("TOPRIGHT", -2, -2)

    AddDialogSlider(1, L["Config - Spinner - Size"], "Scale", Spinners.SCALE_MIN, Spinners.SCALE_MAX)
    AddDialogSlider(2, L["Config - Spinner - Opacity"], "Opacity", Spinners.OPACITY_MIN, Spinners.OPACITY_MAX)

    Dialog.ResetButton = CreateFrame("Button", nil, Dialog, "UIPanelButtonTemplate") --[[@as Button]]
    Dialog.ResetButton:SetSize(DIALOG_WIDTH - 2 * DIALOG_PADDING, 24)
    Dialog.ResetButton:SetPoint("BOTTOM", 0, DIALOG_PADDING)
    Dialog.ResetButton:SetText(HUD_EDIT_MODE_RESET_POSITION)
    Dialog.ResetButton:SetScript("OnClick", function()
        if not selected then return end
        local positions = Config.GetPersistent().positions
        if positions then positions[selected.info.key] = nil end
        Private.Place(selected)
    end)
end

local function FormatPercent(value)
    return value .. "%"
end

--- Fills the dialog for the selected spinner, after a setting changed.
function Private.RefreshDialog()
    if settingFromDialog or not (selected and Dialog and Dialog:IsShown()) then return end
    Dialog.Title:SetText(selected.info.label)
    for _, row in ipairs(dialogSliders) do
        row.slider:Init(Config.Get(KeyOf(selected, row.setting)), row.min, row.max,
            (row.max - row.min) / Spinners.PERCENT_STEP,
            { [MinimalSliderWithSteppersMixin.Label.Right] = FormatPercent })
    end
end

---@param spinner Spinner
local function OpenDialog(spinner)
    if not Dialog then CreateDialog() end
    selected = spinner
    Dialog:ClearAllPoints()
    Dialog:SetPoint("LEFT", spinner.selection, "RIGHT", 16, 0)
    Dialog:Show()
    Private.RefreshDialog()
end

local function CloseDialog()
    selected = nil
    if Dialog then Dialog:Hide() end
end



-- Selecting and dragging

--- Shows `spinner` as selected with its dialog, and the other spinners as not.
---@param spinner Spinner?
local function Select(spinner)
    for _, other in ipairs(Private.spinners) do
        if other.selection and other.selection:IsShown() then
            if other == spinner then other.selection:ShowSelected() else other.selection:ShowHighlighted() end
        end
    end
    if spinner then OpenDialog(spinner) else CloseDialog() end
end

---@param spinner Spinner
local function OnDropped(spinner)
    spinner:StopMovingOrSizing()
    local x, y = spinner:GetCenter()
    local parentX, parentY = UIParent:GetCenter()
    local scale = spinner:GetScale()
    local persistent = Config.GetPersistent()
    persistent.positions = persistent.positions or {}
    persistent.positions[spinner.info.key] = { x = x * scale - parentX, y = y * scale - parentY }
    Private.Place(spinner)
end

--- Lets `spinner` be dragged and selected in Edit Mode.
---@param spinner Spinner
function Private.AddToEditMode(spinner)
    if not EditModeManagerFrame then return end
    spinner:SetMovable(true)
    spinner:SetClampedToScreen(true)

    local selection = CreateFrame("Frame", nil, spinner, "EditModeSystemSelectionTemplate") --[[@as SpinnerSelection]]
    selection:SetPoint("TOPLEFT", -SELECTION_PADDING, SELECTION_PADDING)
    selection:SetPoint("BOTTOMRIGHT", SELECTION_PADDING, -SELECTION_PADDING)
    selection:SetFrameLevel(spinner:GetFrameLevel() + 10)
    selection:Hide()
    -- Blizzard's label asks its system for a name, and the spinner isn't one.
    selection.GetLabelText = function() return spinner.info.label end
    selection:SetScript("OnMouseDown", function()
        EditModeManagerFrame:ClearSelectedSystem()
        Select(spinner)
    end)
    selection:SetScript("OnDragStart", function() spinner:StartMoving() end)
    selection:SetScript("OnDragStop", function() OnDropped(spinner) end)
    selection:SetScript("OnEnter", function(self) self:ShowEditInstructions(true) end)
    selection:SetScript("OnLeave", function(self) self:ShowEditInstructions(false) end)
    spinner.selection = selection
end



-- Edit Mode opening and closing

--- Follows Edit Mode opening, closing, and other frames being selected.
function Private.SetUpEditMode()
    if not EditModeManagerFrame then return end
    EventRegistry:RegisterCallback("EditMode.Enter", function()
        Private.editing = true
        Private.RefreshShown()
    end, Private)
    EventRegistry:RegisterCallback("EditMode.Exit", function()
        Private.editing = false
        Select(nil)
        Private.RefreshShown()
    end, Private)
    -- Selecting anything else unselects the spinners: Blizzard's systems select through
    -- SelectSystem, and other addons' frames (RL Radial Menu, LibEditMode) clear Blizzard's
    -- selection first. A spinner clears it too, then selects itself after.
    hooksecurefunc(EditModeManagerFrame, "SelectSystem", function() Select(nil) end)
    hooksecurefunc(EditModeManagerFrame, "ClearSelectedSystem", function() Select(nil) end)
    -- Blizzard's settings dialog opens for every system that's selected, however it was.
    if EditModeSystemSettingsDialog then
        hooksecurefunc(EditModeSystemSettingsDialog, "AttachToSystemFrame", function() Select(nil) end)
    end
end
