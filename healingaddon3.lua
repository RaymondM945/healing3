local playerpetname = nil
local grouphavepet = false
local enableAddon = true
local dropdownValues = { 90, 85, 80, 75, 70, 65, 60, 55, 50 }
local StartHealthreshold = dropdownValues[1]

local Holylightthreshold = dropdownValues[1]

local testheal = false
local TestHealNames = {
	"player",
	"party1",
	"party2",
	"party3",
	"party4",
	"pet",
}

local Healtypes = {
	"Holy Light",
	"Flash of Light",
}

local selectedHealType = Healtypes[1]
local selectedHealTarget = TestHealNames[1]
local f = CreateFrame("Frame")

local box = CreateFrame("Frame", "MyCenterBox", UIParent)
box:SetSize(25, 25) -- width, height
box:SetPoint("CENTER") -- position at center of screen
box.texture = box:CreateTexture(nil, "BACKGROUND")
box.texture:SetAllPoints()
box.texture:SetColorTexture(0, 0, 0, 1)

local HolylightMap = {
	player = { 1, 0, 0 },
	party1 = { 0, 1, 0 },
	party2 = { 0, 0, 1 },
	party3 = { 1, 1, 1 },
	party4 = { 0.5, 0.5, 0.5 },
	pet = { 1, 1, 0 },
}
local FlashlightMap = {
	player = { 0.5, 1, 1 },
	party1 = { 0, 0.5, 1 },
	party2 = { 1, 0.5, 0 },
	party3 = { 0, 1, 0.5 },
	party4 = { 0.5, 0, 1 },
	pet = { 0, 1, 1 },
}

f:SetScript("OnUpdate", function(self, elapsed)
	if not enableAddon then
		return
	end

	if not testheal then
		box.texture:SetColorTexture(0, 0, 0, 1)
	end

	if IsInGroup() then
		box:Show()
		local lowesthp = 100
		local lowestunitname = "player"

		for i = 0, GetNumGroupMembers() - 1 do
			local unit = (i == 0) and "player" or "party" .. i
			if UnitExists(unit) and UnitIsConnected(unit) and UnitIsVisible(unit) then
				local name = UnitName(unit)
				local health = UnitHealth(unit)
				local maxHealth = UnitHealthMax(unit)
				local healthPercent = (health / maxHealth) * 100

				if healthPercent < lowesthp then
					lowesthp = healthPercent
					lowestunitname = unit
				end
			end
		end
		if UnitExists(playerpetname) then
			local petHealth = UnitHealth(playerpetname)
			local petMaxHealth = UnitHealthMax(playerpetname)
			local petHealthPercent = (petHealth / petMaxHealth) * 100

			if petHealthPercent < lowesthp then
				lowesthp = petHealthPercent
				lowestunitname = "pet"
			end
		end

		local mana = UnitPower("player", 0)
		local haveDebuff = false
		for i = 1, 40 do
			local name, _, _, debuffType = UnitDebuff("party2", i)

			if not name then
				break
			end

			if debuffType == "Magic" then
				print("Magic debuff found:", name)
				haveDebuff = true
			end
		end
		if haveDebuff then
			box.texture:SetColorTexture(1, 0.5, 0.5, 1)
		elseif mana >= 0 and lowesthp < StartHealthreshold then
			if lowesthp <= Holylightthreshold then
				local spellName = UnitCastingInfo("player")
				local usable, nomana = IsUsableSpell("Holy Light")

				if spellName ~= "Holy Light" and usable then
					local r, g, b = unpack(HolylightMap[lowestunitname] or { 0, 0, 0, 1 })
					box.texture:SetColorTexture(r, g, b, 1)
				else
					box.texture:SetColorTexture(0, 0, 0, 1)
				end
			else
				local spellName = GetSpellInfo(19750)
				if IsPlayerSpell(19750) then
					local spellName = UnitCastingInfo("player")
					local usable2, nomana2 = IsUsableSpell("Flash of Light")
					local r, g, b = unpack(FlashlightMap[lowestunitname] or { 0, 0, 0, 1 })
					if spellName ~= "Flash of Light" and usable2 then
						box.texture:SetColorTexture(r, g, b, 1)
					else
						box.texture:SetColorTexture(0, 0, 0, 1)
					end
				end
			end
		end
	else
		box:Hide()
	end
end)

local function scanGroupPets()
	grouphavepet = false
	for i = 0, 4 do
		local petUnit = (i == 0) and "playerpet" or "partypet" .. i

		if UnitExists(petUnit) then
			playerpetname = petUnit
			print("Pet found: " .. playerpetname)
			grouphavepet = true
		end
	end
	if not grouphavepet then
		playerpetname = nil
	end
end

f:RegisterEvent("UNIT_PET")
f:RegisterEvent("GROUP_ROSTER_UPDATE")

f:SetScript("OnEvent", function(self, event, unit)
	if event == "UNIT_PET" then
		scanGroupPets()
	elseif event == "GROUP_ROSTER_UPDATE" then
		C_Timer.After(0.2, scanGroupPets)
		C_Timer.After(2.0, scanGroupPets)
	end
end)

local checkbox = CreateFrame("CheckButton", nil, UIParent, "UICheckButtonTemplate")
checkbox:SetSize(24, 24)
checkbox:SetPoint("TOP", 0, -20)
checkbox.text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
checkbox.text:SetText("Enable Addon")
checkbox:SetChecked(enableAddon)
checkbox:SetScript("OnClick", function(self)
	if self:GetChecked() then
		print("Checkbox checked")
		enableAddon = true
		box:Show()
	else
		print("Checkbox unchecked")
		enableAddon = false
		box:Hide()
	end
end)

local dropdownLabel = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
dropdownLabel:SetPoint("BOTTOMLEFT", checkbox, "BOTTOMLEFT", 0, -25)
dropdownLabel:SetText("Begin Healing at:")

local dropdown = CreateFrame("Frame", "MyAddonDropdown", UIParent, "UIDropDownMenuTemplate")
dropdown:SetPoint("TOPLEFT", dropdownLabel, "BOTTOMLEFT", -15, -5)
UIDropDownMenu_SetWidth(dropdown, 100)
UIDropDownMenu_SetText(dropdown, tostring(StartHealthreshold))

UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	for _, value in ipairs(dropdownValues) do
		info.text = tostring(value)
		info.checked = (value == StartHealthreshold)
		info.func = function()
			StartHealthreshold = value
			UIDropDownMenu_SetText(dropdown, tostring(value))
			print("Selected:", StartHealthreshold)
		end
		UIDropDownMenu_AddButton(info)
	end
end)

local dropdownLabel2 = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
dropdownLabel2:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 15, -10)
dropdownLabel2:SetText("Begin Holy Light at:")

local dropdown2 = CreateFrame("Frame", "MyAddonDropdown2", UIParent, "UIDropDownMenuTemplate")
dropdown2:SetPoint("TOPLEFT", dropdownLabel2, "BOTTOMLEFT", -15, -5)

UIDropDownMenu_SetWidth(dropdown2, 100)
UIDropDownMenu_SetText(dropdown2, tostring(Holylightthreshold))

UIDropDownMenu_Initialize(dropdown2, function(self, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	for _, value in ipairs(dropdownValues) do
		info.text = tostring(value)
		info.checked = (value == Holylightthreshold)
		info.func = function()
			Holylightthreshold = value
			UIDropDownMenu_SetText(dropdown2, tostring(value))
			print("Holy Light starts at:", Holylightthreshold)
		end
		UIDropDownMenu_AddButton(info)
	end
end)

-- Checkbox under the second dropdown
local checkbox3 = CreateFrame("CheckButton", nil, UIParent, "UICheckButtonTemplate")
checkbox3:SetSize(24, 24)
checkbox3:SetPoint("TOPLEFT", dropdown2, "BOTTOMLEFT", 15, -10) -- position under dropdown2
checkbox3.text = checkbox3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
checkbox3.text:SetPoint("LEFT", checkbox3, "RIGHT", 4, 0)
checkbox3.text:SetText("Test Heal")
checkbox3:SetChecked(testheal)

checkbox3:SetScript("OnClick", function(self)
	if self:GetChecked() then
		testheal = true

		if selectedHealType == "Holy Light" then
			local color = HolylightMap[selectedHealTarget]
			if color then
				local r, g, b = unpack(color)
				box.texture:SetColorTexture(r, g, b, 1)
			else
				box.texture:SetColorTexture(0, 0, 0, 1)
			end
		elseif selectedHealType == "Flash of Light" then
			local color = FlashlightMap[selectedHealTarget]
			if color then
				local r, g, b = unpack(color)
				box.texture:SetColorTexture(r, g, b, 1)
			else
				box.texture:SetColorTexture(0, 0, 0, 1)
			end
		end
	else
		testheal = false
		box.texture:SetColorTexture(0, 0, 0, 1)
	end
end)

local healTypeLabel = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
healTypeLabel:SetPoint("TOPLEFT", checkbox3, "BOTTOMLEFT", 0, -10)
healTypeLabel:SetText("Heal Type:")

local healTypeDropdown = CreateFrame("Frame", "MyAddonHealTypeDropdown", UIParent, "UIDropDownMenuTemplate")
healTypeDropdown:SetPoint("TOPLEFT", healTypeLabel, "BOTTOMLEFT", -15, -5)

UIDropDownMenu_SetWidth(healTypeDropdown, 120)
UIDropDownMenu_SetText(healTypeDropdown, selectedHealType)

UIDropDownMenu_Initialize(healTypeDropdown, function(self, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	for _, value in ipairs(Healtypes) do
		info.text = value
		info.checked = (value == selectedHealType)
		info.func = function()
			selectedHealType = value
			UIDropDownMenu_SetText(healTypeDropdown, value)
			print("Selected Heal Type:", selectedHealType)
			if testheal then
				if selectedHealType == "Holy Light" then
					local color = HolylightMap[selectedHealTarget]
					if color then
						local r, g, b = unpack(color)
						box.texture:SetColorTexture(r, g, b, 1)
					else
						box.texture:SetColorTexture(0, 0, 0, 1)
					end
				elseif selectedHealType == "Flash of Light" then
					local color = FlashlightMap[selectedHealTarget]
					if color then
						local r, g, b = unpack(color)
						box.texture:SetColorTexture(r, g, b, 1)
					else
						box.texture:SetColorTexture(0, 0, 0, 1)
					end
				end
			end
		end
		UIDropDownMenu_AddButton(info)
	end
end)

-- Label for the dropdown
local healDropdownLabel = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
healDropdownLabel:SetPoint("TOPLEFT", healTypeDropdown, "BOTTOMLEFT", 15, -10)
healDropdownLabel:SetText("Test Heal on:")

-- Create the dropdown
local healDropdown = CreateFrame("Frame", "MyAddonHealDropdown", UIParent, "UIDropDownMenuTemplate")
healDropdown:SetPoint("TOPLEFT", healDropdownLabel, "BOTTOMLEFT", -15, -5)

UIDropDownMenu_SetWidth(healDropdown, 120)
UIDropDownMenu_SetText(healDropdown, selectedHealTarget)

UIDropDownMenu_Initialize(healDropdown, function(self, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	for _, value in ipairs(TestHealNames) do
		info.text = value
		info.checked = (value == selectedHealTarget)
		info.func = function()
			selectedHealTarget = value
			UIDropDownMenu_SetText(healDropdown, value)
			print("Selected Test Heal Target:", selectedHealTarget)

			if testheal then
				if selectedHealType == "Holy Light" then
					local color = HolylightMap[selectedHealTarget]
					if color then
						local r, g, b = unpack(color)
						box.texture:SetColorTexture(r, g, b, 1)
					else
						box.texture:SetColorTexture(0, 0, 0, 1)
					end
				elseif selectedHealType == "Flash of Light" then
					local color = FlashlightMap[selectedHealTarget]
					if color then
						local r, g, b = unpack(color)
						box.texture:SetColorTexture(r, g, b, 1)
					else
						box.texture:SetColorTexture(0, 0, 0, 1)
					end
				end
			end
		end
		UIDropDownMenu_AddButton(info)
	end
end)
