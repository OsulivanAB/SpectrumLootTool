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

    frame.rows = {}

    self.frame = frame
    return frame
end

-- Populate the main frame with the current group roster or the player when solo
function SLH:UpdateRoster()
    local frame = self:CreateMainFrame()
    -- hide existing rows
    for _, row in ipairs(frame.rows) do
        row:Hide()
    end

    local players = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name, _, _, _, _, classFile = GetRaidRosterInfo(i)
            if name then
                table.insert(players, { name = name, class = classFile })
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() do
            local unit = (i == GetNumGroupMembers()) and "player" or ("party" .. i)
            if UnitExists(unit) then
                local name = GetUnitName(unit, true)
                local _, classFile = UnitClass(unit)
                table.insert(players, { name = name, class = classFile })
            end
        end
    else
        local name = UnitName("player")
        local _, classFile = UnitClass("player")
        table.insert(players, { name = name, class = classFile })
    end

    for i, info in ipairs(players) do
        local row = frame.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, frame)
            row:SetSize(180, 20)
            row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.nameText:SetPoint("LEFT")
            row.valueText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.valueText:SetPoint("RIGHT")
            frame.rows[i] = row
        end
        row:SetPoint("TOPLEFT", 10, -30 - (i - 1) * 20)
        local color = RAID_CLASS_COLORS[info.class] or { r = 1, g = 1, b = 1 }
        row.nameText:SetText(info.name)
        row.nameText:SetTextColor(color.r, color.g, color.b)
        row.valueText:SetText(SLH.db.rolls[info.name] or 0)
        row:Show()
    end

    for i = #players + 1, #frame.rows do
        frame.rows[i]:Hide()
    end

    frame:SetHeight(40 + #players * 20)
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
