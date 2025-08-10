local ADDON_NAME, SLH = ...

-- Create a very small frame that can be toggled with /slh
function SLH:CreateMainFrame()
    if self.frame then return self.frame end

    local frame = CreateFrame("Frame", "SpectrumLootHelperFrame", UIParent, "BackdropTemplate")
    frame:SetSize(200, 80)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    frame:SetBackdropColor(0, 0, 0, 0.7)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Spectrum Loot Helper")

    self.frame = frame
    return frame
end

-- Create a simple settings panel with a toggle to allow operation outside raids
function SLH:CreateOptions()
    if self.optionsPanel then return end

    local panel = CreateFrame("Frame")
    panel.name = "Spectrum Loot Helper"

    local checkbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", 16, -16)
    checkbox.Text:SetText("Enable outside raid groups")
    checkbox:SetChecked(self.db.settings.allowOutsideRaid)
    checkbox:SetScript("OnClick", function(btn)
        SLH.db.settings.allowOutsideRaid = btn:GetChecked()
        if SLH.frame then
            if SLH:IsEnabled() then
                SLH.frame:Show()
            else
                SLH.frame:Hide()
            end
        end
    end)

    self.optionsPanel = panel
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(panel)
    end
end
