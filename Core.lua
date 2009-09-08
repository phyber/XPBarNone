-- Addon
XPBarNone = LibStub("AceAddon-3.0"):NewAddon("XPBarNone", "AceEvent-3.0", "AceConsole-3.0")
local self, XPBarNone = XPBarNone, XPBarNone
-- Libs
local L = LibStub("AceLocale-3.0"):GetLocale("XPBarNone")
local LQT = LibStub:GetLibrary("LibQTip-1.0")
local LSM3 = LibStub("LibSharedMedia-3.0")
-- Doodads
local _G = _G
local tonumber = tonumber
local tostring = tostring
local type = type
local ipairs = ipairs
local select = select
-- Strings
local string_format = string.format
local string_match = string.match
local string_len = string.len
local string_gmatch = string.gmatch
local string_reverse = string.reverse
local string_gsub = string.gsub
-- Maths
local math_ceil = math.ceil
local math_floor = math.floor
local math_min = math.min
local math_mod = mod
-- WoW Functions
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax
local UnitLevel = UnitLevel
local IsResting = IsResting
local IsShiftKeyDown = IsShiftKeyDown
local GetNumFactions = GetNumFactions
local GetFactionInfo = GetFactionInfo
local GetXPExhaustion = GetXPExhaustion
local IsControlKeyDown = IsControlKeyDown
local ExpandFactionHeader = ExpandFactionHeader
local CollapseFactionHeader = CollapseFactionHeader
local GetWatchedFactionInfo = GetWatchedFactionInfo
local SetWatchedFactionIndex = SetWatchedFactionIndex
-- Vars for averaging the kills to level
local lastXPValues = {}
local sessionkills = 0
-- Rep hex colours
local RepHexColours = {}
-- Used to fix some weird bar switching issue :)
local mouseovershift
-- Rep menu tooltip
local tooltip

-- For finding the max player level
-- 0: WoW Classic. Level 60
-- 1: The Burning Cruade. Level 70
-- 2: Wrath of the Lich King. Level 80
-- 3: Cataclysm. Level 85 (probably)
local maxPlayerLevel = MAX_PLAYER_LEVEL_TABLE[GetAccountExpansionLevel()]

-- Register our textures
LSM3:Register("statusbar", "BantoBar", "Interface\\AddOns\\XPBarNone\\Textures\\bantobar")
LSM3:Register("statusbar", "Charcoal", "Interface\\AddOns\\XPBarNone\\Textures\\charcoal")
LSM3:Register("statusbar", "Glaze", "Interface\\AddOns\\XPBarNone\\Textures\\glaze")
LSM3:Register("statusbar", "LiteStep", "Interface\\AddOns\\XPBarNone\\Textures\\litestep")
LSM3:Register("statusbar", "Marble", "Interface\\AddOns\\XPBarNone\\Textures\\marble")
LSM3:Register("statusbar", "Otravi", "Interface\\AddOns\\XPBarNone\\Textures\\otravi")
LSM3:Register("statusbar", "Perl", "Interface\\AddOns\\XPBarNone\\Textures\\perl")
LSM3:Register("statusbar", "Smooth", "Interface\\AddOns\\XPBarNone\\Textures\\smooth")
LSM3:Register("statusbar", "Smooth v2", "Interface\\AddOns\\XPBarNone\\Textures\\smoothv2")
LSM3:Register("statusbar", "Striped", "Interface\\AddOns\\XPBarNone\\Textures\\striped")
LSM3:Register("statusbar", "Waves", "Interface\\AddOns\\XPBarNone\\Textures\\waves")

-- SavedVariables stored here later
local db

-- Default settings
local defaults = {
	profile = {
		--General
		general = {
			border = false,
			texture = "Smooth",
			width = 1028,
			height = 20,
			fontsize = 14,
			fontoutline = false,
			posx = nil,
			posy = nil,
			scale = 1,
			strata = "HIGH",
			hidetext = false,
			dynamicbars = false,
			mouseover = false,
			locked = false,
			bubbles = false,
			clamptoscreen = true,
			commify = false,
			textposition = 50,
		},
		-- XP Bar specific
		xp = {
			xpstring = "Exp: [curXP]/[maxXP] ([restPC]) :: [curPC] through level [pLVL] :: [needXP] XP left :: [KTL] kills to level",
			indicaterest = true,
			showremaining = true,
			showzerorest = true,
		},
		-- Rep bar specific
		rep = {
			repstring = "Rep: [faction] ([standing]) [curRep]/[maxRep] :: [repPC]",
			autowatchrep = true,
			showrepbar = false,
		},
		-- Colours of the various bars
		-- We don't currently support alpha, but set it here so that we don't get
		-- pointless vars in the savedvariables file.
		colours = {
			normal = { r = 0.8, g = 0, b = 1, a = 1 },
			rested = { r = 0, g = 0.4, b = 1, a = 1 },
			resting = { r = 1.0, g = 0.82, b = 0.25, a = 1 },
			remaining = { r = 0.82, g = 0, b = 0, a = 1 },
			background = { r = 0.5, g = 0.5, b = 0.5, a = 0.5 },
			exalted = { r = 0, g = 0.77, b = 0.63, a = 1 },
		},
	}
}
-- Return an options table.
local function GetOptions(uiTypes, uiName, appName)
	if appName == "XPBarNone-General" then
		local options = {
			type = "group",
			name = GetAddOnMetadata("XPBarNone", "Title"),
			get = function(info) return db.general[info[#info]] end,
			set = function(info, value)
				db.general[info[#info]] = value
				self:UpdateXPBar()
			end,
			args = {
				xpbndesc = {
					type = "description",
					order = 0,
					name = GetAddOnMetadata("XPBarNone", "Notes"),
				},
				locked = {
					name = L["Lock"],
					desc = L["Toggle the locking."],
					type = "toggle",
					order = 100,
				},
				clamptoscreen = {
					name = L["Screen Clamp"],
					desc = L["Toggle screen clamping."],
					type = "toggle",
					order = 200,
				},
				commify = {
					name = L["Commify"],
					desc = L["Insert thousands separators into long numbers."],
					type = "toggle",
					order = 300,
				},
				border = {
					name = L["Border"],
					desc = L["Toggle the border."],
					type = "toggle",
					order = 400,
					set = function(info, value)
						db.general.border = value
						self:ToggleBorder()
					end,
				},
				bubbles = {
					name = L["Bubbles"],
					desc = L["Toggle bubbles on the XP bar."],
					type = "toggle",
					order = 500,
					set = function(info, value)
						db.general.bubbles = value
						self:ToggleBubbles()
					end,
				},
				scale = {
					name = L["Scale"],
					desc = L["Set the bar scale."],
					type = "range",
					order = 600,
					min = 0.5,
					max = 2,
					set = function(info, value)
						self:SavePosition()
						self.frame:SetScale(value)
						db.general.scale = value
						self:RestorePosition()
					end,
				},
				width = {
					name = L["Width"],
					desc = L["Set the bar width."],
					type = "range",
					order = 700,
					min = 100,
					max = 5000,
					step = 1,
					bigStep = 50,
					set = function(info, value)
						db.general.width = value
						self:SetWidth(value)
					end,
				},
				height = {
					name = L["Height"],
					desc = L["Set the bar height."],
					type = "range",
					order = 800,
					min = 10,
					max = 100,
					step = 1,
					bigStep = 5,
					set = function(info, value)
						db.general.height = value
						self:SetHeight(value)
					end
				},
				fontsize = {
					name = L["Font Size"],
					desc = L["Change the size of the text."],
					type = "range",
					order = 900,
					min = 5,
					max = 30,
					step = 1,
					bigStep = 5,
				},
				fontoutline = {
					name = L["Font Outline"],
					desc = L["Toggles the font outline."],
					type = "toggle",
					order = 1000,
				},
				textposition = {
					name = L["Text Position"],
					desc = L["Select the position of the text on XPBarNone."],
					type = "range",
					order = 1100,
					min = 0,
					max = 100,
					step = 1,
					bigStep = 5,
					set = function(info, value)
						db.general.textposition = value
						self:SetTextPosition(value)
					end,
				},
				mouseover = {
					name = L["Mouse Over"],
					desc = L["Toggles switching between XP bar and Rep bar when you mouse over XPBarNone."],
					type = "toggle",
					order = 1200,
					disabled = function() return db.general.dynamicbars end,
				},
				strata = {
					name = L["Frame Strata"],
					desc = L["Set the frame strata."],
					type = "select",
					order = 1300,
					values = {
						HIGH = "High",
						MEDIUM = "Medium",
						LOW = "Low",
						BACKGROUND = "Background",
					},
					style = "dropdown",
				},
				texture = {
					name = L["Texture"],
					desc = L["Set the bar texture."],
					type = "select",
					order = 1400,
					dialogControl = 'LSM30_Statusbar',
					values = AceGUIWidgetLSMlists.statusbar,
					style = "dropdown",
					set = function(info, value)
						db.general.texture = value
						self:SetTexture(value)
						self:UpdateXPBar()
					end,
				},
				hidetext = {
					name = L["Hide Text"],
					desc = L["Hide the text on the XP and Rep bars."],
					type = "toggle",
					order = 1500,
				},
				showzerorep = {
					name = L["Show Zero"],
					desc = L["Show zero values in the various Need tags, instead of an empty string"],
					type = "toggle",
					order = 1600,
				},
				dynamicbars = {
					name = L["Dynamic Bars"],
					desc = L["Show Rep bar on max level, XP bar on lower levels."],
					type = "toggle",
					order = 1700,
				},
			},
		}
		return options
	end
	if appName == "XPBarNone-XP" then
		local options = {
			type = "group",
			name = L["Experience"],
			get = function(info) return db.xp[info[#info]] end,
			set = function(info, value)
				db.xp[info[#info]] = value
				self:UpdateXPBar()
			end,
			args = {
				xpdesc = {
					type = "description",
					order = 0,
					name = L["Experience Bar related options"],
				},
				xpstring = {
					name = L["Customise Text"],
					desc = L["Customise the XP text string."],
					type = "input",
					order = 100,
					width = "full",
				},
				showremaining = {
					name = L["Remaining Rested XP"],
					desc = L["Toggle the display of remaining rested XP."],
					type = "toggle",
					order = 200,
				},
				indicaterest = {
					name = L["Rest Indication"],
					desc = L["Toggle the rest indication."],
					type = "toggle",
					order = 300,
				},
			},
		}
		return options
	end
	if appName == "XPBarNone-Rep" then
		local options = {
			type = "group",
			name = L["Reputation"],
			get = function(info) return db.rep[info[#info]] end,
			set = function(info, value)
				db.rep[info[#info]] = value 
				self:UpdateXPBar()
			end,
			args = {
				repdesc = {
					type = "description",
					order = 0,
					name = L["Reputation Bar related options"],
				},
				repstring = {
					name = L["Customise Text"],
					desc = L["Customise the Reputation text string."],
					type = "input",
					order = 100,
					width = "full",
				},
				autowatchrep = {
					name = L["Auto Watch Reputation"],
					desc = L["Automatically watch the factions you gain rep with."],
					type = "toggle",
					order = 200,
					set = function()
						db.rep.autowatchrep = not db.rep.autowatchrep
						XPBarNone:ToggleAutoWatch()
					end,
				},
				showrepbar = {
					name = L["Show Reputation"],
					desc = L["Show the reputation bar instead of the XP bar."],
					type = "toggle",
					order = 300,
					set = function()
						XPBarNone:ToggleShowReputation()
					end,
				},
			},
		}
		return options
	end
	if appName == "XPBarNone-Colours" then
		local options = {
			type = "group",
			name = "Colours",
			get = function(info) 
				return db.colours[info[#info]].r, db.colours[info[#info]].g, db.colours[info[#info]].b, db.colours[info[#info]].a or 1
			end,
			set = function(info, r, g, b, a)
				db.colours[info[#info]].r, db.colours[info[#info]].g, db.colours[info[#info]].b, db.colours[info[#info]].a = r, g, b, a
				self:UpdateXPBar()
			end,
			args = {
				coloursdesc = {
					type = "description",
					order = 0,
					name = "Set the colours for various XPBarNone bars.",
				},
				normal = {
					name = L["Normal"],
					desc = L["Set the colour of the normal bar."],
					type = "color",
					order = 100,
					hasAlpha = false,
				},
				rested = {
					name = L["Rested"],
					desc = L["Set the colour of the rested bar."],
					type = "color",
					order = 200,
					hasAlpha = false,
				},
				resting = {
					name = L["Resting"],
					desc = L["Set the colour of the resting bar."],
					type = "color",
					order = 300,
					hasAlpha = false,
				},
				remaining = {
					name = L["Remaining"],
					desc = L["Set the colour of the remaining bar."],
					type = "color",
					order = 400,
					hasAlpha = false,
				},
				exalted = {
					name = _G.FACTION_STANDING_LABEL8,
					desc = L["Set the colour of the Exalted reputation bar."],
					type = "color",
					order = 500,
					hasAlpha = false,
				},
			},
		}
		return options
	end
end

-- Set the font for the bar text
function XPBarNone:SetFontOptions()
	local font, size, flags = GameFontNormal:GetFont()
	if db.general.fontoutline then
		flags = "OUTLINE"
	end
	self.frame.bartext:SetFont(font, db.general.fontsize, flags)
end

-- Position of text along the XP Bar
function XPBarNone:SetTextPosition(percent)
	local width = db.general.width
	local posx = math_floor(((width / 100) * percent) - (width / 2))
	self.frame.bartext:ClearAllPoints()
	self.frame.bartext:SetPoint("CENTER", self.frame, "CENTER", posx or 0, 0)
end

-- Set bar textures
function XPBarNone:SetTexture(texture)
	local texturePath = LSM3:Fetch("statusbar", texture)
	self.frame.background:SetStatusBarTexture(texturePath)
	self.frame.remaining:SetStatusBarTexture(texturePath)
	self.frame.xpbar:SetStatusBarTexture(texturePath)
	self.frame.background:SetStatusBarColor(db.colours.background.r, db.colours.background.g, db.colours.background.b, db.colours.background.a)
end

-- Set bar widths
function XPBarNone:SetWidth(width)
	self.frame:SetWidth(width)
	self.frame.background:SetWidth(width - 4)
	self.frame.remaining:SetWidth(width - 4)
	self.frame.xpbar:SetWidth(width - 4)
	self.frame.bubbles:SetWidth(width - 4)
end

function XPBarNone:SetHeight(height)
	self.frame:SetHeight(height)
	self.frame.background:SetHeight(height - 4)
	self.frame.remaining:SetHeight(height - 4)
	self.frame.xpbar:SetHeight(height - 4)
	self.frame.bubbles:SetHeight(height - 4)
end

-- Toggle the border
function XPBarNone:ToggleBorder()
	if db.general.border then
		self.frame:SetBackdropBorderColor(1, 1, 1, 1)
	else
		self.frame:SetBackdropBorderColor(0, 0, 0, 0)
	end
end

-- Toggle the bubbles
function XPBarNone:ToggleBubbles()
	if db.general.bubbles then
		self.frame.bubbles:Show()
	else
		self.frame.bubbles:Hide()
	end
end

-- Toggle the screen clamp
function XPBarNone:ToggleClamp()
	self.frame:SetClampedToScreen(db.general.clamptoscreen and true or false)
end

-- Toggle between rep and xp bar.
function XPBarNone:ToggleShowReputation()
	if db.rep.showrepbar then
		db.rep.showrepbar = false
	else
		db.rep.showrepbar = true
	end
	self:UpdateXPBar()
end

-- Refreshes the config for profiles support, NYI
function XPBarNone:RefreshConfig()
	self.frame:SetFrameStrata(db.general.strata)
	self.frame:SetScale(db.general.scale)
	self:SetWidth(db.general.width)
	self:SetHeight(db.general.height)
	self:ToggleBorder()
	self:SetFontOptions()
	self:SetTextPosition(db.general.textposition)
	self:SetTexture(db.general.texture)
	self:ToggleBubbles()
	self:ToggleClamp()
	self:GenHexColours()
	self:RestorePosition()
end

function XPBarNone:OnInitialize()
	-- Get the DB.
	self.db = LibStub("AceDB-3.0"):New("XPBarNoneDB", defaults, "Defaults")
	db = self.db.profile
	-- Register options
	local myName = GetAddOnMetadata("XPBarNone", "Title")
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("XPBarNone-General", GetOptions)
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("XPBarNone-XP", GetOptions)
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("XPBarNone-Rep", GetOptions)
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("XPBarNone-Colours", GetOptions)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("XPBarNone-General", myName)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("XPBarNone-XP", "XP", myName)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("XPBarNone-Rep", "Reputation", myName)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("XPBarNone-Colours", "Colours", myName)
	-- Register a chat command to open options
	self:RegisterChatCommand("xpbn", function() InterfaceOptionsFrame_OpenToCategory(LibStub("AceConfigDialog-3.0").BlizOptions["XPBarNone-General"].frame) end)
	-- Profiles
	local popts = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("XPBarNone-Profiles", popts)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("XPBarNone-Profiles", "Profiles", myName)
	-- For profile support. NYI
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

function XPBarNone:OnEnable()
	-- Create the XP bar if it isn't created yet.
	if self.CreateXPBar then
		self:CreateXPBar()
	end
	-- Set the options on the bar.
	self:RefreshConfig()
	-- XP Events
	self:RegisterEvent("PLAYER_XP_UPDATE", "UpdateXPData")
	self:RegisterEvent("PLAYER_LEVEL_UP", "LevelUp")
	self:RegisterEvent("PLAYER_UPDATE_RESTING", "UpdateXPData")
	self:RegisterEvent("UPDATE_EXHAUSTION", "UpdateXPBar")
	-- Rep Events
	self:RegisterEvent("UPDATE_FACTION", "UpdateXPBar")
	-- Only register this one if we're auto watching rep.
	if db.rep.autowatchrep then
		self:RegisterEvent("COMBAT_TEXT_UPDATE")
	end
	-- Register some LSM3 callbacks
	LSM3.RegisterCallback(self, "LibSharedMedia_Registered", "MediaUpdate")
	LSM3.RegisterCallback(self, "LibSharedMedia_SetGlobal", function(callback, mtype, override)
		if mtype == "statusbar" and override ~= nil then
			self:SetTexture(override)
		end
	end)

	-- Check for dynamic bars.
	if db.general.dynamicbars then
		self:UpdateDynamicBars()
	end

	-- Show the bar.
	self:UpdateXPData()
	self.frame:Show()
end

function XPBarNone:OnDisable()
	self.frame:Hide()
	LSM3.UnregisterAllCallbacks(self)
end

-- Some small local functions
-- commify(num) Inserts thousands separators into numbers.
-- 1000000 -> 1,000,000. etc.
local function commify(num)
	if not db.general.commify or string_len(tostring(num)) <= 3 or type(num) ~= "number" then
		return num
	end
	local str = ""
	local count = 0
	for d in string_gmatch(string_reverse(tostring(num)), "%d") do
		if count ~= 0 and math_mod(count, 3) == 0 then
			str = str .. "," .. d
		else
			str = str .. d
		end
		count = count + 1
	end
	return string_reverse(str)
end

-- Tooltips for the rep menu
function XPBarNone:SetTooltip(tip)
	GameTooltip_SetDefaultAnchor(GameTooltip, WorldFrame)
	GameTooltip:SetText(tip[1], 1, 1, 1)
	GameTooltip:AddLine(tip[2])
	GameTooltip:Show()
end

function XPBarNone:HideTooltip()
	GameTooltip:FadeOut()
end

-- Get the number of kills to level
local function GetNumKTL()
	local remainingXP = XPBarNone.remXP
	local xp = 0
	for _, v in ipairs(lastXPValues) do
		xp = xp + v
	end
	local avgxp = xp / #lastXPValues
	return math_ceil(remainingXP / avgxp)
end

-- Get the XP bar text
local function GetXPText(restedXP)
	local text = db.xp.xpstring

	text = string_gsub(text, "%[curXP%]", commify(XPBarNone.cXP))
	text = string_gsub(text, "%[maxXP%]", commify(XPBarNone.nXP))

	if restedXP then
		text = string_gsub(text, "%[restXP%]", commify(restedXP))
		text = string_gsub(text, "%[restPC%]", string_format("%.1f%%%%", restedXP / XPBarNone.nXP * 100))
	else
		text = string_gsub(text, "%[restXP%]", db.xp.showzerorest and "0" or "")
		text = string_gsub(text, "%[restPC%]", db.xp.showzerorest and "0%%" or "")
	end

	text = string_gsub(text, "%[curPC%]", string_format("%.1f%%%%", XPBarNone.cXP / XPBarNone.nXP * 100))
	text = string_gsub(text, "%[needPC%]", string_format("%.1f%%%%", 100 - (XPBarNone.cXP / XPBarNone.nXP * 100)))
	text = string_gsub(text, "%[pLVL%]", UnitLevel("player"))
	text = string_gsub(text, "%[nLVL%]", UnitLevel("player") + 1)
	text = string_gsub(text, "%[mLVL%]", maxPlayerLevel)
	text = string_gsub(text, "%[needXP%]", commify(XPBarNone.remXP))

	local ktl = tonumber(string_format("%d", GetNumKTL()))
	if ktl <= 0 or not ktl then
		ktl = '?'
	end

	text = string_gsub(text, "%[KTL%]", commify(ktl))
	text = string_gsub(text, "%[BTL%]", string_format("%d", math_ceil(20 - ((XPBarNone.cXP / XPBarNone.nXP * 100) / 5))))

	return text
end

-- Set the watched faction based on the faction name
local function SetWatchedFactionName(faction)
	for i = 1, GetNumFactions() do
		-- name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = GetFactionInfo(factionIndex)
		local name,_,_,_,_,_,_,_,isHeader,_,_,isWatched,_ = GetFactionInfo(i)
		if name == faction then
			-- If it's not watched and it's not a header
			-- watch it.
			if not isWatched and not isHeader then
				SetWatchedFactionIndex(i)
				return
			else
				return
			end
		end
	end
end
-- GetRepText
-- Returns the text for the reputation bar after substituting the various tokens
local function GetRepText(repName, repStanding, repMin, repMax, repValue)
	local text = db.rep.repstring

	-- Now replace all the tokens
	text = string_gsub(text, "%[faction%]", repName)
	text = string_gsub(text, "%[standing%]", _G["FACTION_STANDING_LABEL"..repStanding])
	text = string_gsub(text, "%[curRep%]", commify(repValue))
	text = string_gsub(text, "%[maxRep%]", commify(repMax))
	text = string_gsub(text, "%[repPC%]", string_format("%.1f%%%%", repValue / repMax * 100))
	text = string_gsub(text, "%[needRep%]", commify(repMax - repValue))
	text = string_gsub(text, "%[needPC%]", string_format("%.1f%%%%", math_floor(100 - (repValue / repMax * 100))))

	return text
end

-- Get the text for the rep tooltip
local function GetRepTooltipText(standingText, bottom, top, earned)
	local maxRep = top - bottom
	local curRep = earned - bottom
	local repPercent = curRep / maxRep * 100

	return string_format("Standing: %s\nRep: %s/%s [%.1f%%]", standingText, commify(curRep), commify(maxRep), repPercent)
end

-- Toggle the collapsed sections in the rep menu
function XPBarNone:ToggleCollapse(faction)
	local isCollapsed = select(10, GetFactionInfo(faction))
	if isCollapsed then
		ExpandFactionHeader(faction)
	else
		CollapseFactionHeader(faction)
	end
end

function XPBarNone:SetWatchedFactionIndex(faction)
	SetWatchedFactionIndex(faction)
end

-- Get hex colours
local function GetRepHexColour(standing)
	return string_format("|cff%s", RepHexColours[standing])
end

-- Setup Rep colours
function XPBarNone:GenHexColours()
	for i = 1, 8 do
		local fbc
		if i == 8 then
			fbc = db.colours.exalted
		else
			fbc = FACTION_BAR_COLORS[i]
		end
		RepHexColours[i] = string_format("%2x%2x%2x", fbc.r * 255, fbc.g * 255, fbc.b * 255)
	end
end

-- OK, main functions.
-- XPBar creation
function XPBarNone:CreateXPBar()
	-- Check if the bar already exists before proceeding.
	if self.frame then return end

	-- Main Frame
	self.frame = CreateFrame("Frame", "XPBarNoneFrame", UIParent)
	self.frame:SetFrameStrata(db.general.strata)
	self.frame:SetMovable(true)
	self.frame:Hide()

	if db.general.scale then
		self.frame:SetScale(db.general.scale)
	end

	self.frame:ClearAllPoints()
	if not db.general.posx then
		self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	else
		self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.general.posx, db.general.posy)
	end
	self.frame:SetWidth(db.general.width)
	self.frame:SetHeight(db.general.height)

	self.frame:SetBackdrop({
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 12,
		insets = { left = 5, right = 5, top = 5, bottom = 5, },
	})

	-- Button
	self.frame.button = CreateFrame("Button", "XPBarNoneButton", self.frame)
	self.frame.button:SetAllPoints(self.frame)
	self.frame.button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self.frame.button:RegisterForDrag("LeftButton")
	self.frame.button:SetScript("OnClick", function()
		-- Paste currently displayed text to edit box on Shift-LeftClick
		if IsShiftKeyDown() and arg1 == "LeftButton" then
			if not ChatFrameEditBox:IsVisible() then
				ChatFrameEditBox:Show()
			end
			ChatFrameEditBox:Insert(self.frame.bartext:GetText())
		end
		-- Display options on Shift-RightClick
		if IsShiftKeyDown() and arg1 == "RightButton" then
			InterfaceOptionsFrame_OpenToCategory(LibStub("AceConfigDialog-3.0").BlizOptions["XPBarNone-General"].frame)
		end
		-- Display Reputation menu on Ctrl-RightClick
		if IsControlKeyDown() and arg1 == "RightButton" then
			self:MakeRepTooltip()
		end
	end)
	self.frame.button:SetScript("OnDragStart", function()
		if not db.general.locked then
			self.frame:StartMoving()
		end
	end)
	self.frame.button:SetScript("OnDragStop", function()
		self.frame:StopMovingOrSizing()
		self:SavePosition()
	end)
	self.frame.button:SetScript("OnEnter", function()
		if db.general.mouseover and not IsShiftKeyDown() and not IsControlKeyDown() then
			self:ToggleShowReputation()
		else
			mouseovershift = true
		end
	end)
	self.frame.button:SetScript("OnLeave", function()
		if db.general.mouseover and not mouseovershift then
			self:ToggleShowReputation()
		else
			mouseovershift = nil
		end
	end)

	-- Background
	self.frame.background = CreateFrame("StatusBar", "XPBarNoneBackground", self.frame)
	self.frame.background:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
	self.frame.background:SetWidth(self.frame:GetWidth() - 4)
	self.frame.background:SetHeight(self.frame:GetHeight() - 8)

	-- XP Bar
	self.frame.xpbar = CreateFrame("StatusBar", "XPBarNoneXPBar", self.frame)
	self.frame.xpbar:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
	self.frame.xpbar:SetWidth(self.frame:GetWidth() - 4)
	self.frame.xpbar:SetHeight(self.frame:GetHeight() - 8)

	-- Remaining Rested XP Bar
	self.frame.remaining = CreateFrame("StatusBar", "XPBarNoneRemaining", self.frame)
	self.frame.remaining:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
	self.frame.remaining:SetWidth(self.frame:GetWidth() - 4)
	self.frame.remaining:SetHeight(self.frame:GetHeight() - 8)

	-- Bubbles
	self.frame.bubbles = CreateFrame("StatusBar", "XPBarNoneBubbles", self.frame)
	self.frame.bubbles:SetStatusBarTexture("Interface\\AddOns\\XPBarNone\\Textures\\bubbles")
	self.frame.bubbles:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
	self.frame.bubbles:SetWidth(self.frame:GetWidth() - 4)
	self.frame.bubbles:SetHeight(self.frame:GetHeight() - 8)

	-- XP Bar Text
	self.frame.bartext = self.frame.button:CreateFontString("XPBarNoneText", "OVERLAY")
	self:SetFontOptions()
	self.frame.bartext:SetShadowOffset(1, -1)
	self:SetTextPosition(db.general.textposition)
	self.frame.bartext:SetTextColor(1, 1, 1, 1)

	-- Set frame levels.
	self.frame:SetFrameLevel(0)
	self.frame.background:SetFrameLevel(self.frame:GetFrameLevel() + 1)
	self.frame.remaining:SetFrameLevel(self.frame:GetFrameLevel() + 2)
	self.frame.xpbar:SetFrameLevel(self.frame:GetFrameLevel() + 3)
	self.frame.bubbles:SetFrameLevel(self.frame:GetFrameLevel() + 4)
	self.frame.button:SetFrameLevel(self.frame:GetFrameLevel() + 5)

	self:SetTexture(db.general.texture)
	self:ToggleBubbles()
	self:ToggleClamp()
	self:RestorePosition()
	
	-- Kill function after the bar is made.
	XPBarNone.CreateXPBar = nil
end

-- LSM3 Updates.
function XPBarNone:MediaUpdate()

end

-- Check for faction updates for the auto rep watching
function XPBarNone:COMBAT_TEXT_UPDATE(msgtype, faction, amount)
	-- Abort if it's not a FACTION update
	if msgtype ~= "FACTION" then
		return
	end
	if db.rep.autowatchrep then
		-- We don't want to watch factions we're losing rep with
		if string_match(amount, "^%-.*") then
			return
		end

		-- Everything ok? Watch the faction!
		SetWatchedFactionName(faction)
	end
end

function XPBarNone:UpdateXPData()
	local prevXP = self.cXP or 0
	self.cXP = UnitXP("player")
	self.nXP = UnitXPMax("player")
	self.remXP = self.nXP - self.cXP
	self.diffXP = self.cXP - prevXP

	if self.diffXP > 0 then
		lastXPValues[math_mod(sessionkills, 10) + 1] = self.diffXP
		sessionkills = sessionkills + 1
	end

	self:UpdateXPBar()
end

function XPBarNone:UpdateRepData()
	if not db.rep.showrepbar then
		return
	end

	local repName, repStanding, repMin, repMax, repValue = GetWatchedFactionInfo()

	if repName == nil then
		if self.frame.xpbar:IsVisible() then
			self.frame.xpbar:Hide()
		end
		self.frame.bartext:SetText(L["You need to select a faction to watch."])
		return
	end

	repMax = repMax - repMin
	repValue = repValue - repMin
	repMin = 0

	if not self.frame.xpbar:IsVisible() then
		self.frame.xpbar:Show()
	end

	self.frame.remaining:Hide()
	self.frame.xpbar:SetMinMaxValues(math_min(0, repValue), repMax)
	self.frame.xpbar:SetValue(repValue)

	-- Use our own colour for exalted.
	local repColour
	if repStanding == 8 then
		repColour = db.colours.exalted
	else
		repColour = FACTION_BAR_COLORS[repStanding]
	end
	self.frame.xpbar:SetStatusBarColor(repColour.r, repColour.g, repColour.b, repColour.a)

	if not db.general.hidetext then
		self.frame.bartext:SetText(GetRepText(repName, repStanding, repMin, repMax, repValue))
	else
		self.frame.bartext:SetText("")
	end
end

function XPBarNone:UpdateXPBar()
	-- menu refresh function
	if LQT:IsAcquired("XPBarNoneTT") then
		self:MakeRepTooltip()
	end

	if db.rep.showrepbar then
		self:UpdateRepData()
		return
	else
		if not self.frame.xpbar:IsVisible() then
			self.frame.xpbar:Show()
		end
	end

	local restedXP = GetXPExhaustion()

	if restedXP == nil then
		if self.frame.remaining:IsVisible() then
			self.frame.remaining:Hide()
		end
		local normal = db.colours.normal
		self.frame.xpbar:SetStatusBarColor(normal.r, normal.g, normal.b, normal.a)
	else
		self.frame.remaining:SetMinMaxValues(math_min(0, self.cXP), self.nXP)
		self.frame.remaining:SetValue(self.cXP + restedXP)

		local remaining = db.colours.remaining
		self.frame.remaining:SetStatusBarColor(remaining.r, remaining.g, remaining.b, remaining.a)

		-- Do we want to indicate rest?
		if IsResting() and db.general.indicaterest then
			local resting = db.colours.resting
			self.frame.xpbar:SetStatusBarColor(resting.r, resting.g, resting.b, resting.a)
		else
			local rested = db.colours.rested
			self.frame.xpbar:SetStatusBarColor(rested.r, rested.g, rested.b, rested.a)
		end

		-- Show remaining rested XP?
		if db.xp.showremaining then
			self.frame.remaining:Show()
		else
			self.frame.remaining:Hide()
		end
	end

	self.frame.xpbar:SetMinMaxValues(math_min(0, self.cXP), self.nXP)
	self.frame.xpbar:SetValue(self.cXP)

	-- Hide the text or not?
	if not db.general.hidetext then
		self.frame.bartext:SetText(GetXPText(restedXP))
	else
		self.frame.bartext:SetText("")
	end
end

-- When max level is hit, show only the rep bar.
function XPBarNone:LevelUp(level)
	if level == maxPlayerLevel then
		db.rep.showrepbar = true
		db.general.mouseover = false
	end
	self:UpdateXPBar()
end

-- Dynamic bars, switch between rep/level when using a single profile for all char.s
function XPBarNone:UpdateDynamicBars()
	if UnitLevel("player") == maxPlayerLevel then
		db.rep.showrepbar = true
		db.general.mouseover = false
	else
		db.rep.showrepbar = false
		db.general.mouseover = true
	end
end

-- Setup tips, etc.
function XPBarNone:MakeRepTooltip()
	if not LQT:IsAcquired("XPBarNoneTT") then
		tooltip = LQT:Acquire("XPBarNoneTT", 2, "CENTER", "LEFT")
	end
	tooltip:Clear()
	tooltip:Hide()
	tooltip:SetScale(1)
	self:DrawRepMenu()
	tooltip:SetAutoHideDelay(1, self.frame.button)
	tooltip:EnableMouse()
	tooltip:SmartAnchorTo(self.frame.button)
	tooltip:UpdateScrolling()
	tooltip:Show()
end

-- Reputation menu
function XPBarNone:DrawRepMenu()
	local linenum
	local checkIcon = "|TInterface\\Buttons\\UI-CheckBox-Check:24:24:1:-1|t"
	tooltip:Hide()
	tooltip:Clear()

	--Header
	linenum = tooltip:AddLine(nil)
	tooltip:SetCell(linenum, 1, L["Faction Listing"], tooltip:GetHeaderFont(), "CENTER", 2)

	-- Reputations
	for faction = 1, GetNumFactions() do
		local name,_,standing,bottom,top,earned,atWar,_,isHeader,isCollapsed,_,isWatched,isChild = GetFactionInfo(faction)
		if not isHeader then
			-- Faction
			local repColour
			if standing == 8 then
				repColour = db.colours.exalted
			else
				repColour = FACTION_BAR_COLORS[standing]
			end
			local standingText = _G["FACTION_STANDING_LABEL"..standing]
			local tipText = GetRepTooltipText(standingText, bottom, top, earned)

			linenum = tooltip:AddLine(nil)
			tooltip:SetCell(linenum, 1, isWatched and checkIcon or " ")
			tooltip:SetCell(linenum, 2, string_format("%s%s (%s)|r", GetRepHexColour(standing), name, standingText), GameTooltipTextSmall)
			tooltip:SetLineScript(linenum, "OnMouseUp", XPBarNone.SetWatchedFactionIndex, faction)
			tooltip:SetLineScript(linenum, "OnEnter", XPBarNone.SetTooltip, {name,tipText})
			tooltip:SetLineScript(linenum, "OnLeave", XPBarNone.HideTooltip)
		else
			-- Header
			local tipText, iconPath
			if isCollapsed then
				tipText = string_format(L["Click to expand %s faction listing"], name)
				iconPath = "|TInterface\\Buttons\\UI-PlusButton-Up:24:24:1:-1|t"
			else
				tipText = string_format(L["Click to collapse %s faction listing"], name)
				iconPath = "|TInterface\\Buttons\\UI-MinusButton-Up:24:24:1:-1|t"
			end

			linenum = tooltip:AddLine(iconPath, name)
			tooltip:SetLineScript(linenum, "OnMouseUp", XPBarNone.ToggleCollapse, faction)
			tooltip:SetLineScript(linenum, "OnEnter", XPBarNone.SetTooltip, {name,tipText})
			tooltip:SetLineScript(linenum, "OnLeave", XPBarNone.HideTooltip)
		end
	end

	-- Hint
	linenum = tooltip:AddLine(nil)
	tooltip:SetCell(linenum, 1, "|cff00ff00".. L["Hint: Click to set watched faction."] .."|r", nil, "CENTER", 2)
end

-- Bar positioning.
function XPBarNone:SavePosition()
	local x, y = self.frame:GetLeft(), self.frame:GetTop()
	local s = self.frame:GetEffectiveScale()

	x, y = x*s, y*s

	db.general.posx = x
	db.general.posy = y
end

function XPBarNone:RestorePosition()
	local x = db.general.posx
	local y = db.general.posy
	if not x or not y then return end

	local s = self.frame:GetEffectiveScale()

	x, y = x/s, y/s

	self.frame:ClearAllPoints()
	self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
end
