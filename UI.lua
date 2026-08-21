local addonName, Procboi = ...

local Database = Procboi.Database
local UI = {}

Procboi.UI = UI

local WINDOW_WIDTH = 750
local WINDOW_HEIGHT = math.floor(WINDOW_WIDTH / 1.69)

local WINDOW_MIN_WIDTH = 650
local WINDOW_MIN_HEIGHT = math.floor(WINDOW_MIN_WIDTH / 1.69)
local WINDOW_MAX_WIDTH = 1100
local WINDOW_MAX_HEIGHT = math.floor(WINDOW_MAX_WIDTH / 1.69)

local LEFT_PERCENT = 0.30
local MIDDLE_PERCENT = 0.35
local RIGHT_PERCENT = 0.35

local CONTENT_PADDING = 10

local ROW_HEIGHT = 28

local COLORS = {
    background = { 0.08, 0.08, 0.08, 0.98 },
    tooltipBackground = { 0.08, 0.08, 0.08, 1 },
    panel = { 0.12, 0.12, 0.12, 1 },
    border = { 0.30, 0.30, 0.30, 1 },
    text = { 1, 1, 1 },
}

local MONO_FONT_PATH = "Interface\\AddOns\\Procboi\\Media\\FiraCode-Medium.ttf"

local function GetItemInfo(itemID)
    local name, link, _, _, _, _, _, _, _, texture = C_Item.GetItemInfo(itemID)

    return {
        id = itemID,
        name = name or ("Item " .. tostring(itemID)),
        link = link,
        texture = texture,
    }
end

local function CreateBackground(frame, color)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = {
            left = 2,
            right = 2,
            top = 2,
            bottom = 2,
        },
    })

    frame:SetBackdropColor(unpack(color or COLORS.panel))
    frame:SetBackdropBorderColor(unpack(COLORS.border))
end

local function CreateLabel(parent, text, size, color, fontFlags)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")

    label:SetText(text or "")
    label:SetFont(label:GetFont(), size or 14, fontFlags or "")
    label:SetTextColor(unpack(color or COLORS.text))
    label:SetJustifyH("LEFT")

    return label
end

local function CreateButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")

    button:SetSize(width or 100, height or 24)

    button:SetNormalFontObject("GameFontNormal")
    button:SetHighlightFontObject("GameFontHighlight")

    button:SetText(text)

    button:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 10,
    })

    button:SetBackdropColor(0.15, 0.15, 0.15, 1)
    button:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.22, 0.22, 0.22, 1)
    end)

    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 1)
    end)

    return button
end

local function CreateResizeGrip(frame)
    local resizeGrip = CreateFrame("Button", nil, frame, "BackdropTemplate")

    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)

    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeGrip:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)

    resizeGrip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)
end

local function ResizeChildButtons(parent)
    if not parent then
        return
    end

    local width = parent:GetWidth()

    for _, child in ipairs({ parent:GetChildren() }) do
        child:SetWidth(width)
    end
end

function UI:LayoutPanels()
    local frame = self.mainFrame

    if not frame then
        return
    end

    local leftPanel = self.leftPanel
    local middlePanel = self.middlePanel
    local rightPanel = self.rightPanel

    if not leftPanel or not middlePanel or not rightPanel then
        return
    end

    local totalWidth = frame:GetWidth()
    -- Padding
    local contentWidth = totalWidth - (CONTENT_PADDING * 2)

    -- Remove the two gaps between panels
    local panelWidth = contentWidth - (CONTENT_PADDING * 2)

    leftPanel:SetWidth(panelWidth * LEFT_PERCENT)
    middlePanel:SetWidth(panelWidth * MIDDLE_PERCENT)
    rightPanel:SetWidth(panelWidth * RIGHT_PERCENT)

    if self.summaryText then
        self.summaryText:SetWidth(
            middlePanel:GetWidth() - (CONTENT_PADDING * 2)
        )
    end

    ResizeChildButtons(self.itemList)
    ResizeChildButtons(self.sessionList)
end

local function CreateInfoTooltip(parent)
    local TOOLTIP_WIDTH = 450
    local TOOLTIP_HEIGHT = 250
    local SCROLLBAR_WIDTH = 14

    local tooltip = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    tooltip:SetSize(TOOLTIP_WIDTH, TOOLTIP_HEIGHT)
    tooltip:SetFrameStrata("TOOLTIP")
    tooltip:EnableMouse(true)

    tooltip:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
    })

    tooltip:SetBackdropBorderColor(unpack(COLORS.border))

    local background = tooltip:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 1)

    local scrollFrame = CreateFrame("ScrollFrame", nil, tooltip)
    scrollFrame:SetPoint("TOPLEFT", tooltip, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
    scrollFrame:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -(CONTENT_PADDING + SCROLLBAR_WIDTH), CONTENT_PADDING)
    scrollFrame:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scrollFrame)

    content:SetWidth(TOOLTIP_WIDTH - (CONTENT_PADDING * 2) - SCROLLBAR_WIDTH)
    content:SetHeight(1)
    scrollFrame:SetScrollChild(content)

    local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

    text:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    text:SetWidth(content:GetWidth())
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetWordWrap(true)
    text:SetTextColor(unpack(COLORS.text))

    tooltip.text = text
    tooltip.content = content
    tooltip.scrollFrame = scrollFrame

    local scrollBar = CreateFrame("Slider", nil, tooltip)
    scrollBar:SetWidth(SCROLLBAR_WIDTH)
    scrollBar:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -CONTENT_PADDING, -CONTENT_PADDING)
    scrollBar:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)

    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValueStep(1)
    scrollBar:SetObeyStepOnDrag(true)

    local track = scrollBar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetTexture("Interface\\Buttons\\UI-ScrollBar-Background")

    local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetWidth(SCROLLBAR_WIDTH)
    thumb:SetHeight(30)
    thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")

    scrollBar:SetThumbTexture(thumb)

    scrollBar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)

    tooltip.scrollBar = scrollBar

    local function ScrollBy(delta)
        local maxScroll = scrollFrame:GetVerticalScrollRange()

        if maxScroll <= 0 then
            return
        end

        local current = scrollFrame:GetVerticalScroll()

        local newValue = current - (delta * 30)

        if newValue < 0 then
            newValue = 0
        elseif newValue > maxScroll then
            newValue = maxScroll
        end

        scrollFrame:SetVerticalScroll(newValue)
        scrollBar:SetValue(newValue)
    end

    scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        ScrollBy(delta)
    end)

    -- Also allow scrolling when the mouse is over the tooltip
    -- itself, e.g. over the scrollbar/text area.
    tooltip:SetScript("OnMouseWheel", function(_, delta)
        ScrollBy(delta)
    end)

    function tooltip:UpdateScroll()
        local textHeight = text:GetStringHeight()

        content:SetHeight(math.max(1, textHeight + CONTENT_PADDING))

        scrollFrame:UpdateScrollChildRect()

        local maxScroll = scrollFrame:GetVerticalScrollRange()

        scrollBar:SetMinMaxValues(0, maxScroll)
        scrollBar:SetValue(0)
        scrollFrame:SetVerticalScroll(0)

        if maxScroll > 0 then
            scrollBar:Show()
        else
            scrollBar:Hide()
        end
    end

    tooltip:Hide()

    return tooltip
end


function UI:CreateInfoIcon()
    if self.infoButton or not self.title then
        return
    end

    local button = CreateFrame("Button", nil, self.mainFrame)

    button:SetSize(20, 20)
    button:SetPoint("RIGHT", self.title, "RIGHT", (CONTENT_PADDING * 4), 0)

    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexture("Interface\\Icons\\INV_Misc_Note_06")

    button:SetNormalTexture(texture)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetBlendMode("ADD")

    local infoText = [[
|cFFFFC000Procboi|r attempts to count crafting procs to estimate long-run bonus yields.

Alchemy has such a mechanic, e.g. Potion Master.
Exact (Potion Master) proc probabilities are not known, but we can estimate profitability using different bonus-yield scenarios.

|cFFFFC000Expected yield is:|r
    E[X] = 1*P(1)       where P(1) = 100% (guaranteed base craft)
            + 2*P(2)
            + 3*P(3)
            + 4*P(4)
            + 5*P(5)

|cFFFFC000Example Proc Rates|r
+1: 15.0%   +2: 2.0%   +3: 0.5%   +4: 0.1%

|cFFFFC000Example Expected Yield:|r 1.209 (+20.9%)

There is a community model assuming a 1/6 (16.67%) chance of each additional proc, implying around 20% long-run bonus yield.

|cFFFFC000Disclaimer|r
|cFF888888Procboi is provided for informational purposes only and without any guarantee of accuracy, usefulness, reliability, completeness, or fitness for any purpose.
Estimates, assumptions, and results (hypothetical or otherwise) may be incorrect or misleading.
Actual outcomes may differ materially, including no benefit or value whatsoever.
Use entirely at your own discretion and risk.|r
]]

    local tooltip = CreateInfoTooltip(button)

    tooltip.text:SetText(infoText)

    local hidePending = false

    local function ScheduleHide()
        hidePending = true
    end

    local function CancelHide()
        hidePending = false
    end

    tooltip:SetScript("OnEnter", function()
        CancelHide()
    end)

    tooltip:SetScript("OnLeave", function()
        ScheduleHide()
    end)

    button:SetScript("OnLeave", function()
        ScheduleHide()
    end)

    tooltip:SetScript("OnUpdate", function(self, elapsed)
        if not hidePending then
            return
        end

        self.hideTimer = (self.hideTimer or 0) + elapsed

        if self.hideTimer < 0.15 then
            return
        end

        self.hideTimer = 0

        if not button:IsMouseOver() and not tooltip:IsMouseOver() then
            tooltip:Hide()
            hidePending = false
        end
    end)

    button:SetScript("OnEnter", function()
        hidePending = false

        tooltip:ClearAllPoints()
        tooltip:SetPoint("TOPLEFT", button, "TOPLEFT", CONTENT_PADDING * 2, -CONTENT_PADDING)

        tooltip:Show()
        tooltip:UpdateScroll()
    end)

    self.infoButton = button
    self.infoTooltip = tooltip
end

function UI:CreateMainWindow()
    if self.mainFrame then
        return self.mainFrame
    end

    local frame = CreateFrame("Frame", "ProcboiMainFrame", UIParent, "BackdropTemplate")

    frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    frame:SetPoint("CENTER")

    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)

    frame:SetResizable(true)
    frame:SetResizeBounds(WINDOW_MIN_WIDTH, WINDOW_MIN_HEIGHT, WINDOW_MAX_WIDTH, WINDOW_MAX_HEIGHT)

    -- resize grip handle
    CreateResizeGrip(frame)

    CreateBackground(frame, COLORS.background)

    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
    end)

    frame:SetScript("OnSizeChanged", function()
        UI:LayoutPanels()
    end)

    -- Title / Close button
    local title = CreateLabel(frame, "Procboi", 18, { 1, 0.82, 0 })
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)

    self.title = title

    local closeButton = CreateButton(frame, "X", 28, 24)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -CONTENT_PADDING, -CONTENT_PADDING)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    self.closeButton = closeButton

    local importButton = CreateButton(frame, "Import", 55, 24)
    importButton:SetPoint("RIGHT", closeButton, "LEFT", -(CONTENT_PADDING * 4), 0)

    importButton:SetScript("OnClick", function()
        self:ShowImportDialog()
    end)

    self.importButton = importButton

    local exportButton = CreateButton(frame, "Export", 55, 24)
    exportButton:SetPoint("RIGHT", self.importButton, "LEFT", -(CONTENT_PADDING * 2), 0)

    exportButton:SetScript("OnClick", function()
        self:ShowExportDialog()
    end)

    self.exportButton = exportButton

    -- Left panel
    local leftPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    leftPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", CONTENT_PADDING, -(CONTENT_PADDING * 4))
    leftPanel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CONTENT_PADDING, CONTENT_PADDING)

    CreateBackground(leftPanel)

    self.leftPanel = leftPanel

    local leftTitle = CreateLabel(leftPanel, "Tracked", 14)
    leftTitle:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", CONTENT_PADDING, -14)

    -- Add Item Button
    local addButton = CreateButton(leftPanel, "+ Add", 70, 24)
    addButton:SetPoint("TOPRIGHT", leftPanel, "TOPRIGHT", -CONTENT_PADDING, -CONTENT_PADDING)

    addButton:SetScript("OnClick", function()
        self:ShowAddItemDialog()
    end)

    local itemList = CreateFrame("Frame", nil, leftPanel)
    itemList:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", CONTENT_PADDING, -(CONTENT_PADDING * 4))
    itemList:SetPoint("BOTTOMRIGHT", leftPanel, "BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)

    self.itemList = itemList

    -- Middle panel
    local middlePanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    middlePanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", CONTENT_PADDING, 0)
    middlePanel:SetPoint("BOTTOMLEFT", leftPanel, "BOTTOMRIGHT", CONTENT_PADDING, 0)

    CreateBackground(middlePanel)

    self.middlePanel = middlePanel

    local itemTitle = CreateLabel(middlePanel, "No item selected", 14)
    itemTitle:SetPoint("TOPLEFT", middlePanel, "TOPLEFT", CONTENT_PADDING, -14)

    local itemTitleHover = CreateFrame("Frame", nil, middlePanel)
    itemTitleHover:SetPoint("TOPLEFT", itemTitle, "TOPLEFT")
    itemTitleHover:SetPoint("BOTTOMRIGHT", itemTitle, "BOTTOMRIGHT")
    itemTitleHover:EnableMouse(true)

    itemTitleHover:SetScript("OnEnter", function()
        if self.itemLink then
            GameTooltip:SetOwner(itemTitleHover, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        end
    end)

    itemTitleHover:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.itemTitle = itemTitle

    local deleteItemButton = CreateButton(middlePanel, "Delete", 70, 24)
    deleteItemButton:SetPoint("TOPRIGHT", middlePanel, "TOPRIGHT", -CONTENT_PADDING, -CONTENT_PADDING)

    deleteItemButton:SetScript("OnClick", function()
        self:ShowDeleteItemDialog()
    end)

    deleteItemButton:Hide()

    self.deleteItemButton = deleteItemButton

    local summaryText = CreateLabel(middlePanel, "", 14)
    summaryText:SetPoint("TOPLEFT", middlePanel, "TOPLEFT", CONTENT_PADDING, -(CONTENT_PADDING * 4))

    summaryText:SetJustifyV("TOP")
    summaryText:SetFont(MONO_FONT_PATH, 11, "")
    summaryText:SetHeight(190)

    self.summaryText = summaryText

    local sessionsTitle = CreateLabel(middlePanel, "Crafting Sessions", 14)
    sessionsTitle:SetPoint("TOPLEFT", summaryText, "TOPLEFT", CONTENT_PADDING, -14)

    self.sessionsTitle = sessionsTitle

    local sessionScroll = CreateFrame("ScrollFrame", nil, middlePanel, "UIPanelScrollFrameTemplate")
    sessionScroll:SetPoint("TOPLEFT", sessionsTitle, "TOPLEFT", CONTENT_PADDING, -(CONTENT_PADDING * 2))
    sessionScroll:SetPoint("BOTTOMRIGHT", middlePanel, "BOTTOMRIGHT", -(CONTENT_PADDING * 3), CONTENT_PADDING)
    sessionScroll:Hide()

    local sessionList = CreateFrame("Frame", nil, sessionScroll)
    sessionList:SetWidth(sessionScroll:GetWidth() - CONTENT_PADDING)
    sessionList:SetHeight(1)

    sessionScroll:SetScrollChild(sessionList)

    sessionScroll:SetScript("OnSizeChanged", function(self, width)
        sessionList:SetWidth(width - CONTENT_PADDING)
    end)

    self.sessionScroll = sessionScroll
    self.sessionList = sessionList

    -- Right panel
    local rightPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    rightPanel:SetPoint("TOPLEFT", middlePanel, "TOPRIGHT", CONTENT_PADDING, 0)
    rightPanel:SetPoint("BOTTOMLEFT", middlePanel, "BOTTOMRIGHT", CONTENT_PADDING, 0)

    CreateBackground(rightPanel)

    self.rightPanel = rightPanel

    local sessionTitle = CreateLabel(rightPanel, "No session selected", 14)
    sessionTitle:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", CONTENT_PADDING, -14)

    self.sessionTitle = sessionTitle

    -- Delete Session Button
    local deleteSessionButton = CreateButton(rightPanel, "Delete", 70, 24)
    deleteSessionButton:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", -CONTENT_PADDING, -CONTENT_PADDING)

    deleteSessionButton:SetScript("OnClick", function()
        self:ShowDeleteSessionDialog()
    end)

    deleteSessionButton:Hide()

    self.deleteSessionButton = deleteSessionButton

    local sessionStats = CreateLabel(rightPanel, "", 14)
    sessionStats:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", CONTENT_PADDING, -(CONTENT_PADDING * 4))

    sessionStats:SetJustifyV("TOP")
    sessionStats:SetFont(MONO_FONT_PATH, 11, "")

    self.sessionStats = sessionStats

    self.mainFrame = frame

    self:CreateInfoIcon()
    self:LayoutPanels()

    frame:Hide()

    return frame
end

-- Refresh Item List
function UI:RefreshItemList()
    local parent = self.itemList

    if not parent then
        return
    end

    for _, child in ipairs({ parent:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local items = Database:GetItems()
    local itemIDs = {}

    for itemID in pairs(items) do
        table.insert(itemIDs, itemID)
    end

    table.sort(itemIDs, function(a, b)
        local itemA = items[a]
        local itemB = items[b]

        return (itemA.name or tostring(a)) < (itemB.name or tostring(b))
    end)

    local offsetHeight = 0
    local offsetWidth = parent:GetWidth()

    for _, itemID in ipairs(itemIDs) do
        local item = items[itemID]
        local info = GetItemInfo(itemID)

        if not item.name and info.name then
            item.name = info.name
        end

        local button = CreateButton(parent, info.name, offsetWidth, ROW_HEIGHT)
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -offsetHeight)
        button:SetText(info.name)

        button:SetScript("OnClick", function()
            self:SelectItem(itemID)
        end)

        offsetHeight = offsetHeight + ROW_HEIGHT + 2
    end
end

-- Select Item
function UI:SelectItem(itemID)
    self.selectedItemID = itemID
    self.selectedSession = nil

    self:RefreshItemList()
    self:RefreshItemOverview()
    self:RefreshSessionDetails()

    self.sessionTitle:SetText("No session selected")
    self.sessionStats:SetText("")
end

-- Item Overview
function UI:RefreshItemOverview()
    self.deleteItemButton:Hide()

    local itemID = self.selectedItemID

    if not itemID then
        self.itemTitle:SetText("No item selected")
        self.itemLink = nil
        self.summaryText:SetText("")
        self.sessionsTitle:SetText("Crafting Sessions")
        self:ClearSessionList()
        return
    end

    local item = Database:GetItem(itemID)

    if not item then
        self.selectedItemID = nil
        self.itemLink = nil
        self.itemTitle:SetText("No item selected")
        self.summaryText:SetText("")
        self:ClearSessionList()
        return
    end

    local info = GetItemInfo(itemID)

    if not item.name then
        item.name = info.name
    end

    self.itemLink = info.link
    self.itemTitle:SetText(info.link or item.name or tostring(itemID))

    local summary = Database:GetItemSummary(itemID)
    local stats = Database:GetStatistics(summary)

    self.summaryText:SetText(
        string.format(
            "|cFFFFC000 Statistics|r\n\n" ..
            "  |cFFC4C4C4Crafts   : %d\n" ..
            "  Produced : %d\n" ..
            "  Bonus    : +%d\n" ..
            "  Procs    : %d (%.2f%%)\n" ..
            "  Yield    : %.3f|r\n\n" ..
            "|cFFFFC000 Distribution|r\n\n" ..
            "  |cFFC4C4C4x1 : %d (%.2f%%)\n" ..
            "  x2 : %d (%.2f%%)\n" ..
            "  x3 : %d (%.2f%%)\n" ..
            "  x4 : %d (%.2f%%)\n" ..
            "  x5 : %d (%.2f%%)|r",
            stats.crafts,
            stats.totalProduced,
            stats.totalBonus,
            stats.procs,
            stats.procRate,
            stats.averageYield,

            summary.results[1] or 0, stats.percentages[1],
            summary.results[2] or 0, stats.percentages[2],
            summary.results[3] or 0, stats.percentages[3],
            summary.results[4] or 0, stats.percentages[4],
            summary.results[5] or 0, stats.percentages[5]
        )
    )

    local sumHeightOffset = -(CONTENT_PADDING * 4) - self.summaryText:GetStringHeight() - CONTENT_PADDING

    self.sessionsTitle:ClearAllPoints()
    self.sessionsTitle:SetPoint("TOPLEFT", self.middlePanel, "TOPLEFT", CONTENT_PADDING, sumHeightOffset)

    self:RefreshSessionList()
    self.deleteItemButton:Show()
end

-- Session List
function UI:ClearSessionList()
    if not self.sessionList then
        return
    end

    for _, child in ipairs({ self.sessionList:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
end

function UI:RefreshSessionList()
    self:ClearSessionList()

    local itemID = self.selectedItemID

    if not itemID then
        return
    end

    local dates = Database:GetSessionDates(itemID)

    local offsetHeight = 0
    local offsetWidth = self.sessionList:GetWidth()
    local buttonHeight = math.floor(ROW_HEIGHT / 1.4)

    for _, date in ipairs(dates) do
        local button = CreateButton(self.sessionList, date, offsetWidth, buttonHeight)
        button:SetPoint("TOPLEFT", self.sessionList, "TOPLEFT", 0, -offsetHeight)
        button:SetText(date)

        button:SetScript("OnClick", function()
            self:SelectSession(date)
        end)

        offsetHeight = offsetHeight + buttonHeight + 2
    end

    self.sessionList:SetHeight(offsetHeight)
    self.sessionScroll:UpdateScrollChildRect()
    self.sessionScroll:Show()
end

-- Select Session
function UI:SelectSession(date)
    self.selectedSession = date

    self:RefreshSessionList()
    self:RefreshSessionDetails()
end

-- Session Details
function UI:RefreshSessionDetails()
    self.deleteSessionButton:Hide()

    local itemID = self.selectedItemID
    local date = self.selectedSession

    if not itemID or not date then
        self.sessionTitle:SetText("No session selected")
        self.sessionStats:SetText("")
        return
    end

    local session = Database:GetSession(itemID, date)

    if not session then
        self.sessionTitle:SetText("No session selected")
        self.sessionStats:SetText("")
        return
    end

    local stats = Database:GetStatistics(session)

    self.sessionTitle:SetText(date)

    self.sessionStats:SetText(
        string.format(
            "|cFFFFC000 [Session] Statistics|r\n\n" ..
            "  |cFFC4C4C4Crafts   : %d\n" ..
            "  Produced : %d\n" ..
            "  Bonus    : +%d\n" ..
            "  Procs    : %d (%.2f%%)\n" ..
            "  Yield    : %.3f|r\n\n" ..
            "|cFFFFC000 [Session] Distribution|r\n\n" ..
            "  |cFFC4C4C4x1: %d (%.2f%%)\n" ..
            "  x2: %d (%.2f%%)\n" ..
            "  x3: %d (%.2f%%)\n" ..
            "  x4: %d (%.2f%%)\n" ..
            "  x5: %d (%.2f%%)|r",
            stats.crafts,
            stats.totalProduced,
            stats.totalBonus,
            stats.procs,
            stats.procRate,
            stats.averageYield,

            session.results[1] or 0, stats.percentages[1],
            session.results[2] or 0, stats.percentages[2],
            session.results[3] or 0, stats.percentages[3],
            session.results[4] or 0, stats.percentages[4],
            session.results[5] or 0, stats.percentages[5]
        )
    )

    self.deleteSessionButton:Show()
end

function UI:CreateSimpleDialog(frameName, anchor, title, width, height)
    if not self.mainFrame then
        return
    end

    local dialog = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")

    dialog:SetSize(width, height)
    dialog:SetPoint("BOTTOMLEFT", anchor or self.mainFrame, "BOTTOMLEFT", CONTENT_PADDING, CONTENT_PADDING)
    dialog:SetFrameStrata("TOOLTIP")
    dialog:SetMovable(true)
    dialog:EnableMouse(true)

    dialog:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)

    dialog:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
    end)

    local helpText = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    helpText:SetPoint("TOPLEFT", dialog, "TOPLEFT", CONTENT_PADDING * 2, -(CONTENT_PADDING * 3))
    helpText:SetPoint("RIGHT", dialog, "RIGHT", -CONTENT_PADDING * 2, 0)
    helpText:SetJustifyH("LEFT")
    helpText:SetWordWrap(true)
    helpText:SetText("")

    dialog.helpText = helpText

    CreateBackground(dialog, COLORS.background)

    if title then
        local titleLabel = CreateLabel(dialog, title, 14)
        titleLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
    end

    local closeButton = CreateButton(dialog, "Close", 80, 26)
    closeButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", (CONTENT_PADDING * 2), CONTENT_PADDING)

    closeButton:SetScript("OnClick", function()
        dialog:Hide()
    end)

    dialog:Hide()

    return dialog
end

function UI:CreateEditBox(parent, autoFocus)
    local input = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    input:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PADDING, -(CONTENT_PADDING * 3))
    input:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING * 5)

    input:SetMultiLine(true)
    input:SetAutoFocus(autoFocus or false)
    input:SetFont(MONO_FONT_PATH, 11, "")
    input:SetTextInsets(6, 6, 6, 6)
    input:SetJustifyH("LEFT")
    input:SetJustifyV("TOP")

    input:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 10,
    })

    input:SetBackdropColor(0.05, 0.05, 0.05, 1)
    input:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

    input:SetScript("OnEscapePressed", function(self)
        parent:Hide()
    end)

    return input
end

function UI:CreateExportDialog()
    if self.exportDialog then
        return self.exportDialog
    end

    local dialog = self:CreateSimpleDialog("ProcboiExportDialog", nil, "Export Database", 500, 320)
    local input = self:CreateEditBox(dialog)

    self.exportDialog = dialog
    self.exportInput = input

    self.exportDialog:SetScript("OnShow", function()
        input:SetText(Database:Export())
        input:SetFocus()
        input:HighlightText()
    end)

    return dialog
end

function UI:ShowExportDialog()
    self:CreateExportDialog()
    self.exportDialog:Show()
end

function UI:CreateImportDialog()
    if self.importDialog then
        return self.importDialog
    end

    local warning = self:CreateSimpleDialog("ProcboiImportWarningDialog", nil, nil, 280, 140)
    local dialog = self:CreateSimpleDialog("ProcboiImportDialog", nil, "Import Database", 500, 320)
    local input = self:CreateEditBox(dialog, true)
    local importButton = CreateButton(dialog, "Import", 80, 26)
    importButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -(CONTENT_PADDING * 2), CONTENT_PADDING)
    local warningYesButton = CreateButton(warning, "Yes", 80, 26)
    warningYesButton:SetPoint("BOTTOMRIGHT", warning, "BOTTOMRIGHT", -(CONTENT_PADDING * 2), CONTENT_PADDING)

    self.importWarningDialog = warning
    self.importDialog = dialog
    self.importInput = input
    self.importImportButton = importButton

    importButton:SetScript("OnClick", function()
        if self.importConfirmed then
            self:ImportFromDialog()
        else
            self.importWarningDialog:SetFrameLevel(self.importDialog:GetFrameLevel() + 1)
            self.importWarningDialog:Show()
        end
    end)

    warningYesButton:SetScript("OnClick", function()
        self.importConfirmed = true
        self.importImportButton:SetText("Import Now")
        self.importWarningDialog:Hide()
    end)

    self.importDialog:SetScript("OnShow", function()
        input:SetText("")
        input:SetFocus()
    end)

    return dialog
end

function UI:ShowImportDialog()
    self:CreateImportDialog()
    self.importConfirmed = nil
    self.importWarningDialog.helpText:SetText(
        "Import this database?\n\n" ..
        "|cFFFF4040This will replace your current database. " ..
        "You will lose all current data!|r"
    )
    self.importDialog:Show()
end

function UI:ImportFromDialog()
    local text = self.importInput:GetText()

    if not text or strtrim(text) == "" then
        return
    end

    local success, errorMessage = Database:Import(text)

    if not success then
        print("|cFFFF0000Procboi import failed:|r " .. errorMessage)
        return
    end

    self.importDialog:Hide()
    self.importWarningDialog:Hide()

    self.selectedItemID = nil
    self.selectedSession = nil
    self.importConfirmed = nil

    self:RefreshItemList()
    self:RefreshItemOverview()
    self:RefreshSessionDetails()
end

-- Add Item Dialog
function UI:CreateAddItemDialog()
    if self.addItemDialog then
        return self.addItemDialog
    end

    local dialog = self:CreateSimpleDialog("ProcboiAddItemDialog", nil, "Add Tracked Item", 280, 140)

    local addButton = CreateButton(dialog, "Add", 80, 26)
    addButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -(CONTENT_PADDING * 2), CONTENT_PADDING)

    local input = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    input:SetSize(220, 30)
    input:SetPoint("CENTER", dialog, "CENTER", 0, -CONTENT_PADDING)
    input:SetAutoFocus(true)
    input:SetMaxLetters(100)

    self.addItemDialog = dialog
    self.addItemInput = input

    input:SetScript("OnEnterPressed", function()
        self:AddItemFromDialog()
    end)

    input:SetScript("OnEscapePressed", function()
        self.addItemDialog:Hide()
    end)

    addButton:SetScript("OnClick", function()
        self:AddItemFromDialog()
    end)

    self.addItemDialog:SetScript("OnShow", function()
        input:SetText("")
        input:SetFocus()
    end)

    return dialog
end

function UI:ShowAddItemDialog()
    self:CreateAddItemDialog()
    self.addItemDialog.helpText:SetText("Enter an item name or item ID.")
    self.addItemDialog:Show()
end

function UI:AddItemFromDialog()
    local value = strtrim(self.addItemInput:GetText())

    if value == "" then
        return
    end

    local itemID = C_Item.GetItemInfoInstant(value)

    if not itemID then
        self.addItemDialog.helpText:SetText("Could not identify that item.")
        return
    end

    local itemName = C_Item.GetItemInfo(itemID)

    if not itemName then
        itemName = value
    end

    if Database:AddItem(itemID, itemName) then
        self.addItemDialog:Hide()
        self:RefreshItemList()
        self:SelectItem(itemID)
    else
        self.addItemDialog.helpText:SetText("Item is already tracked.")
    end
end

-- Delete Item Dialog
function UI:CreateDeleteItemDialog()
    if self.deleteItemDialog then
        return self.deleteItemDialog
    end

    local dialog = self:CreateSimpleDialog("ProcboiDeleteItemDialog", nil, "Delete Tracked Item", 280, 140)
    local yesButton = CreateButton(dialog, "Yes", 80, 26)
    yesButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -(CONTENT_PADDING * 2), CONTENT_PADDING)

    self.deleteItemDialog = dialog

    yesButton:SetScript("OnClick", function()
        self:DeleteItemFromDialog()
    end)

    return dialog
end

function UI:ShowDeleteItemDialog()
    local itemID = self.selectedItemID

    if not itemID then
        return
    end

    local item = Database:GetItem(itemID)

    if not item then
        return
    end

    self:CreateDeleteItemDialog()

    self.deleteItemDialog.helpText:SetText(
        "Delete |cFFFFC000" .. (item.name or tostring(itemID)) .. "|r?\n\n" ..
        "|cFFFF4040This cannot be undone. " .. "You will lose all data for this item!|r"
    )

    self.deleteItemDialog:Show()
end

function UI:DeleteItemFromDialog()
    local itemID = self.selectedItemID

    if not itemID then
        self.deleteItemDialog:Hide()
        return
    end

    if Database:DeleteItem(itemID) then
        self.deleteItemDialog:Hide()

        self.selectedItemID = nil
        self.selectedSession = nil

        self:RefreshItemList()
        self:RefreshItemOverview()
        self:RefreshSessionDetails()
    end
end

-- Delete Session Dialog
function UI:CreateDeleteSessionDialog()
    if self.deleteSessionDialog then
        return self.deleteSessionDialog
    end

    local dialog = self:CreateSimpleDialog("ProcboiDeleteSessionDialog", nil, "Delete Tracked Item", 280, 140)
    local yesButton = CreateButton(dialog, "Yes", 80, 26)
    yesButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -(CONTENT_PADDING * 2), CONTENT_PADDING)

    self.deleteSessionDialog = dialog

    yesButton:SetScript("OnClick", function()
        self:DeleteSessionFromDialog()
    end)

    return dialog
end

function UI:ShowDeleteSessionDialog()
    local date = self.selectedSession
    local itemID = self.selectedItemID

    if not date or not itemID then
        return
    end

    local item = Database:GetItem(itemID)

    if not item then
        return
    end

    self:CreateDeleteSessionDialog()

    self.deleteSessionDialog.helpText:SetText(
        "Delete |cFFFFC000" .. date .. "|r from |cFFFFC000" .. (item.name or tostring(itemID)) .. "|r?\n\n"
        .. "|cFFFF4040This cannot be undone. " .. "You will lose all data from this session!|r"
    )

    self.deleteSessionDialog:Show()
end

function UI:DeleteSessionFromDialog()
    local date = self.selectedSession
    local itemID = self.selectedItemID

    if not date or not itemID then
        self.deleteSessionDialog:Hide()
        return
    end

    if Database:DeleteSession(itemID, date) then
        self.deleteSessionDialog:Hide()

        self.selectedSession = nil

        self:RefreshSessionDetails()
        self:RefreshItemOverview()
    end
end

-- Show / Hide
function UI:Show()
    self:CreateMainWindow()
    self:CreateAddItemDialog()

    self:RefreshItemList()

    self.mainFrame:Show()
end

function UI:Hide()
    if self.mainFrame then
        self.mainFrame:Hide()
    end
end

function UI:Toggle()
    if not self.mainFrame then
        self:Show()
        return
    end

    if self.mainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end
