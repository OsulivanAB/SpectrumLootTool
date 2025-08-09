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
