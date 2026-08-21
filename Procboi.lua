local addonName, Procboi = ...

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon ~= addonName then
        return
    end

    Procboi.Database:Initialize()

    self:UnregisterEvent("ADDON_LOADED")
end)
