local addonName, Procboi = ...

local Database = Procboi.Database
local Tracker = {}

Procboi.Tracker = Tracker

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("CHAT_MSG_LOOT")

eventFrame:SetScript("OnEvent", function(self, event, message)
    Tracker:HandleLootMessage(message)
end)

function Tracker:HandleLootMessage(message)
    -- Only our own crafts
    if not message or not string.match(message, "^You create:") then
        return
    end

    -- |cffxxxxxx|Htype:payload|h[text]|h|r
    local itemLink = string.match(message, "(|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h|r)")

    if not itemLink then
        return
    end

    -- item ID is part of itemLink
    -- /run local _,l=GetItemInfo("Super Mana Potion"); local p=gsub(l,"\124","\124\124"); DEFAULT_CHAT_FRAME:AddMessage(p)
    -- |cffffffff|Hitem:22832::::::::68::::::::::|h[Super Mana Potion]|h|r
    local itemID = tonumber(string.match(itemLink, "|Hitem:(%d+)"))

    if not itemID then
        return
    end

    -- No xN means one item
    local quantity = tonumber(string.match(message, "x(%d+)")) or 1
    local dateValue = date("%Y-%m-%d")

    Database:RecordCraft(itemID, dateValue, quantity)

    local ui = Procboi.UI

    if ui
        and ui.mainFrame
        and ui.mainFrame:IsShown()
    then
        if ui.selectedItemID == itemID then
            ui:RefreshItemOverview()
        end

        if ui.selectedSession == dateValue then
            ui:RefreshSessionDetails()
        end
    end
end
