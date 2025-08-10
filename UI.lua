local ADDON_NAME, SLH = ...

-- Create a very small frame that can be toggled with /slh
function SLH:CreateMainFrame()
    if self.frame then return self.frame end

    local frame = CreateFrame("Frame", "SpectrumLootHelperFrame", UIParent, "BackdropTemplate")
    frame:SetSize(200, 80)
    local pos = self.db.settings.position
    frame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    frame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(f)
        if not SLH.db.settings.locked then
            f:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local point, _, _, x, y = f:GetPoint()
        SLH.db.settings.position = { point = point, x = x, y = y }
    end)

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

    local lockCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    lockCheckbox:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 0, -8)
    lockCheckbox.Text:SetText("Lock frame position")
    lockCheckbox:SetChecked(self.db.settings.locked)
    lockCheckbox:SetScript("OnClick", function(btn)
        SLH.db.settings.locked = btn:GetChecked()
    end)

    self.optionsPanel = panel
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(panel)
    end
end
