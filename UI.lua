local ADDON_NAME, SLH = ...

-- Create a very small frame that can be toggled with /slh
function SLH:CreateMainFrame()
	if self.frame then
		self.Debug:LogDebug("UI", "Main frame already exists, returning existing frame", {
			frameExists = true,
		})
		return self.frame
	end

	self.Debug:LogInfo("UI", "Creating main frame", {
		addonName = ADDON_NAME,
	})

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
			SLH.Debug:LogDebug("UI", "Frame drag started", {
				locked = SLH.db.settings.locked,
			})
		else
			SLH.Debug:LogDebug("UI", "Frame drag attempt blocked - frame is locked", {
				locked = SLH.db.settings.locked,
			})
		end
	end)
	frame:SetScript("OnDragStop", function(f)
		f:StopMovingOrSizing()
		local point, _, _, x, y = f:GetPoint()
		SLH.db.settings.position = { point = point, x = x, y = y }
		SLH.Debug:LogInfo("UI", "Frame position updated", {
			newPosition = { point = point, x = x, y = y },
			previousPosition = pos,
		})
	end)

	-- Right-click for refresh (helpful for officer status issues)
	frame:SetScript("OnMouseUp", function(f, button)
		if button == "RightButton" then
			SLH.Debug:LogInfo("UI", "Right-click refresh triggered", {
				button = button,
			})
			SLH:RefreshOfficerStatus()
			print("|cff00ff00Right-click to refresh officer status|r")
		end
	end)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", 0, -10)
	title:SetText("Spectrum Loot Helper")

	frame.rows = {}

	self.frame = frame

	self.Debug:LogInfo("UI", "Main frame created successfully", {
		frameSize = { width = 200, height = 80 },
		position = pos,
		movable = true,
		locked = self.db.settings.locked,
	})

	return frame
end

-- Populate the main frame with the current group roster or the player when solo
function SLH:UpdateRoster()
	local frame = self:CreateMainFrame()

	self.Debug:LogDebug("UI", "Starting roster update", {
		frameExists = frame ~= nil,
		existingRowCount = #frame.rows,
	})

	-- hide existing rows
	for _, row in ipairs(frame.rows) do
		row:Hide()
	end

	local players = {}
	if IsInRaid() then
		local raidSize = GetNumGroupMembers()
		self.Debug:LogDebug("UI", "Updating roster for raid group", {
			groupType = "raid",
			memberCount = raidSize,
		})
		for i = 1, raidSize do
			local name, _, _, _, _, classFile = GetRaidRosterInfo(i)
			if name then
				table.insert(players, { name = name, class = classFile })
			end
		end
	elseif IsInGroup() then
		local partySize = GetNumGroupMembers()
		self.Debug:LogDebug("UI", "Updating roster for party group", {
			groupType = "party",
			memberCount = partySize,
		})
		for i = 1, partySize do
			local unit = (i == partySize) and "player" or ("party" .. i)
			if UnitExists(unit) then
				local name = GetUnitName(unit, true)
				local _, classFile = UnitClass(unit)
				table.insert(players, { name = name, class = classFile })
			end
		end
	else
		self.Debug:LogDebug("UI", "Updating roster for solo player", {
			groupType = "solo",
		})
		local name = UnitName("player")
		local _, classFile = UnitClass("player")
		table.insert(players, { name = name, class = classFile })
	end

	self.Debug:LogInfo("UI", "Roster data collected", {
		playerCount = #players,
		players = players,
	})

	for i, info in ipairs(players) do
		local row = frame.rows[i]
		if not row then
			self.Debug:LogDebug("UI", "Creating new UI row", {
				rowIndex = i,
				playerName = info.name,
				playerClass = info.class,
			})

			row = CreateFrame("Frame", nil, frame)
			row:SetSize(180, 20)
			row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			row.nameText:SetPoint("LEFT")
			row.upButton = CreateFrame("Button", nil, row, "UIPanelScrollUpButtonTemplate")
			row.upButton:SetSize(16, 16)
			row.upButton:SetPoint("RIGHT", row, "RIGHT", -2, 0)
			row.downButton = CreateFrame("Button", nil, row, "UIPanelScrollDownButtonTemplate")
			row.downButton:SetSize(16, 16)
			row.downButton:SetPoint("RIGHT", row.upButton, "LEFT", -2, 0)
			row.valueText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			row.valueText:SetPoint("RIGHT", row.downButton, "LEFT", -2, 0)
			frame.rows[i] = row
		else
			self.Debug:LogDebug("UI", "Reusing existing UI row", {
				rowIndex = i,
				playerName = info.name,
				playerClass = info.class,
			})
		end

		row:SetPoint("TOPLEFT", 10, -30 - (i - 1) * 20)
		local color = RAID_CLASS_COLORS[info.class] or { r = 1, g = 1, b = 1 }
		row.nameText:SetText(info.name)
		row.nameText:SetTextColor(color.r, color.g, color.b)
		row.playerName = info.name
		row.upButton:SetScript("OnClick", function()
			self.Debug:LogDebug("UI", "Up button clicked", {
				playerName = row.playerName,
				officerName = UnitName("player"),
			})
			SLH:AdjustRoll(row.playerName, 1, UnitName("player"))
		end)
		row.downButton:SetScript("OnClick", function()
			self.Debug:LogDebug("UI", "Down button clicked", {
				playerName = row.playerName,
				officerName = UnitName("player"),
			})
			SLH:AdjustRoll(row.playerName, -1, UnitName("player"))
		end)

		-- Check if player is an officer and show/hide arrows accordingly
		-- Use a more robust check with fallback for reliability
		local isOfficer = SLH:IsOfficer("player")
		self.Debug:LogDebug("UI", "Officer status check for UI controls", {
			playerName = info.name,
			isOfficer = isOfficer,
			unit = "player",
		})

		if isOfficer then
			row.upButton:Show()
			row.downButton:Show()
		else
			row.upButton:Hide()
			row.downButton:Hide()
		end

		local rollValue = SLH.db.rolls[info.name] or 0
		row.valueText:SetText(rollValue)
		row:Show()

		self.Debug:LogDebug("UI", "UI row configured", {
			playerName = info.name,
			playerClass = info.class,
			rollValue = rollValue,
			buttonsVisible = isOfficer,
			rowIndex = i,
		})
	end

	-- Hide excess rows
	local hiddenCount = 0
	for i = #players + 1, #frame.rows do
		frame.rows[i]:Hide()
		hiddenCount = hiddenCount + 1
	end

	local newHeight = 40 + #players * 20
	frame:SetHeight(newHeight)

	self.Debug:LogInfo("UI", "Roster update completed", {
		visiblePlayers = #players,
		hiddenRows = hiddenCount,
		newFrameHeight = newHeight,
		groupType = IsInRaid() and "raid" or (IsInGroup() and "party" or "solo"),
	})
end

-- Create a simple settings panel with a toggle to allow operation outside raids
function SLH:CreateOptions()
	if self.optionsPanel then
		self.Debug:LogDebug("UI", "Options panel already exists, skipping creation", {
			panelExists = true,
		})
		return
	end

	self.Debug:LogInfo("UI", "Creating options panel", {})

	local panel = CreateFrame("Frame")
	panel.name = "Spectrum Loot Helper"

	local checkbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
	checkbox:SetPoint("TOPLEFT", 16, -16)
	checkbox.Text:SetText("Enable outside raid groups")
	checkbox:SetChecked(self.db.settings.allowOutsideRaid)
	checkbox:SetScript("OnClick", function(btn)
		local newValue = btn:GetChecked()
		local oldValue = SLH.db.settings.allowOutsideRaid
		SLH.db.settings.allowOutsideRaid = newValue

		self.Debug:LogInfo("UI", "Allow outside raid setting changed", {
			oldValue = oldValue,
			newValue = newValue,
			frameExists = SLH.frame ~= nil,
		})

		if SLH.frame then
			if SLH:IsEnabled() then
				SLH.frame:Show()
				self.Debug:LogDebug("UI", "Frame shown due to setting change", {})
			else
				SLH.frame:Hide()
				self.Debug:LogDebug("UI", "Frame hidden due to setting change", {})
			end
		end
	end)

	local lockCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
	lockCheckbox:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 0, -8)
	lockCheckbox.Text:SetText("Lock frame position")
	lockCheckbox:SetChecked(self.db.settings.locked)
	lockCheckbox:SetScript("OnClick", function(btn)
		local newValue = btn:GetChecked()
		local oldValue = SLH.db.settings.locked
		SLH.db.settings.locked = newValue

		self.Debug:LogInfo("UI", "Lock frame setting changed", {
			oldValue = oldValue,
			newValue = newValue,
		})
	end)

	self.optionsPanel = panel

	-- Register with appropriate settings system based on WoW version
	if Settings and Settings.RegisterCanvasLayoutCategory then
		local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
		Settings.RegisterAddOnCategory(category)
		self.Debug:LogInfo("UI", "Options panel registered with new Settings API", {
			panelName = panel.name,
		})
	else
		InterfaceOptions_AddCategory(panel)
		self.Debug:LogInfo("UI", "Options panel registered with legacy InterfaceOptions API", {
			panelName = panel.name,
		})
	end

	self.Debug:LogInfo("UI", "Options panel created successfully", {
		allowOutsideRaid = self.db.settings.allowOutsideRaid,
		locked = self.db.settings.locked,
	})
end
