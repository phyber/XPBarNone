-- Addon
XPBarNone = LibStub("AceAddon-3.0"):NewAddon("XPBarNone", "AceEvent-3.0", "AceConsole-3.0")
local self, XPBarNone = XPBarNone, XPBarNone
-- Libs
local L = LibStub("AceLocale-3.0"):GetLocale("XPBarNone")
local LSM3 = LibStub("LibSharedMedia-3.0")
local LQT = LibStub:GetLibrary("LibQTip-1.0")
-- Doodads
local _G = _G
local ipairs = ipairs
local select = select
local tonumber = tonumber
local tostring = tostring
local type = type
-- Maths
local math_ceil = math.ceil
local math_floor = math.floor
local math_huge = math.huge
local math_min = math.min
-- WoW Functions
local BreakUpLargeNumbers = BreakUpLargeNumbers
local CollapseFactionHeader = CollapseFactionHeader
local ExpandFactionHeader = ExpandFactionHeader
local GetGuildInfo = GetGuildInfo
local GetNumFactions = GetNumFactions
local GetFactionInfo = GetFactionInfo
local GetFactionInfoByID = GetFactionInfoByID
local GetFactionParagonInfo = C_Reputation.GetFactionParagonInfo
local GetFriendshipReputation = GetFriendshipReputation
local GetMouseButtonClicked = GetMouseButtonClicked
local GetWatchedFactionInfo = GetWatchedFactionInfo
local GetXPExhaustion = GetXPExhaustion
local IsControlKeyDown = IsControlKeyDown
local IsFactionParagon = C_Reputation.IsFactionParagon
local IsResting = IsResting
local IsShiftKeyDown = IsShiftKeyDown
local IsXPUserDisabled = IsXPUserDisabled
local SetWatchedFactionIndex = SetWatchedFactionIndex
local UnitLevel = UnitLevel
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax
-- WoW constants
local BACKGROUND = BACKGROUND
local FACTION_ALLIANCE = FACTION_ALLIANCE
local FACTION_BAR_COLORS = FACTION_BAR_COLORS
local FACTION_HORDE = FACTION_HORDE
local GUILD = GUILD
-- Vars for averaging the kills to level
local lastXPValues = {}
local sessionkills = 0
-- Rep hex colours
-- Hex colours are automatically generated and cached on access.
local STANDING_EXALTED = 8
local repHexColour
-- Used to fix some weird bar switching issue :)
local mouseovershift
-- Rep menu tooltip
local tooltip

-- For finding the max player level
-- 0: WoW Classic. Level 60
-- 1: The Burning Cruade. Level 70
-- 2: Wrath of the Lich King. Level 80
-- 3: Cataclysm. Level 85
-- 4: Mists of Pandaria. Level 90
-- 5: Warlords of Draenor. Level 100
-- 6: Legion. Level 110
local maxPlayerLevel = MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]

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
            autotrackguild = false,
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
            xptext = { r = 1, g = 1, b = 1, a = 1 },
            reptext = { r = 1, g = 1, b = 1, a = 1 },
        },
        -- Reputation menu options
        repmenu = {
            scale = 1,
            autohidedelay = 1,
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
                    set = function(info, value)
                        db.general.fontsize = value
                        self:SetFontOptions()
                    end,
                },
                fontoutline = {
                    name = L["Font Outline"],
                    desc = L["Toggles the font outline."],
                    type = "toggle",
                    order = 1000,
                    set = function(info, value)
                        db.general.fontoutline = value
                        self:SetFontOptions()
                    end,
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
                font = {
                    name = L["Font"],
                    desc = L["Set the font."],
                    type = "select",
                    order = 1450,
                    dialogControl = 'LSM30_Font',
                    values = AceGUIWidgetLSMlists.font,
                    style = "dropdown",
                    set = function(info, value)
                        db.general.font = value
                        self:SetFontOptions()
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
            name = L["Reputation Bar"],
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
                autotrackguild = {
                    name = L["Auto Track Guild Reputation"],
                    desc = L["Automatically track your guild reputation increases."],
                    type = "toggle",
                    order = 250,
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
            name = L["Bar Colours"],
            get = function(info)
                return db.colours[info[#info]].r, db.colours[info[#info]].g, db.colours[info[#info]].b, db.colours[info[#info]].a or 1
            end,
            set = function(info, r, g, b, a)
                db.colours[info[#info]].r, db.colours[info[#info]].g, db.colours[info[#info]].b, db.colours[info[#info]].a = r, g, b, a
                repHexColour[STANDING_EXALTED] = nil
                local bgc = db.colours.background
                self.frame.background:SetStatusBarColor(
                bgc.r,
                bgc.g,
                bgc.b,
                bgc.a
                )
                self:UpdateXPBar()
            end,
            args = {
                coloursdesc = {
                    type = "description",
                    order = 0,
                    name = L["Set the colours for various XPBarNone bars."],
                },
                normal = {
                    name = L["Normal"],
                    desc = L["Set the colour of the normal bar."],
                    type = "color",
                    order = 100,
                    hasAlpha = true,
                },
                rested = {
                    name = L["Rested"],
                    desc = L["Set the colour of the rested bar."],
                    type = "color",
                    order = 200,
                    hasAlpha = true,
                },
                resting = {
                    name = L["Resting"],
                    desc = L["Set the colour of the resting bar."],
                    type = "color",
                    order = 300,
                    hasAlpha = true,
                },
                remaining = {
                    name = L["Remaining"],
                    desc = L["Set the colour of the remaining bar."],
                    type = "color",
                    order = 400,
                    hasAlpha = true,
                },
                exalted = {
                    name = _G.FACTION_STANDING_LABEL8,
                    desc = L["Set the colour of the Exalted reputation bar."],
                    type = "color",
                    order = 500,
                    hasAlpha = true,
                },
                xptext = {
                    name = "XP Text",
                    desc = L["Set the colour of the XP text."],
                    type = "color",
                    order = 600,
                    hasAlpha = true,
                },
                reptext = {
                    name = "Rep Text",
                    desc = L["Set the colour of the Reputation text."],
                    type = "color",
                    order = 700,
                    hasAlpha = true,
                },
                background = {
                    name = BACKGROUND,
                    desc = L["Set the colour of the background bar."],
                    type = "color",
                    order = 800,
                    hasAlpha = true,
                },
            },
        }
        return options
    end
    if appName == "XPBarNone-RepMenu" then
        local options = {
            type = "group",
            name = L["Reputation Menu"],
            get = function(info) return db.repmenu[info[#info]] end,
            set = function(info, value) db.repmenu[info[#info]] = value end,
            args = {
                repmenudesc = {
                    type = "description",
                    order = 0,
                    name = L["Configure the reputation menu."],
                },
                scale = {
                    name = L["Scale"],
                    desc = L["Set the scale of the reputation menu."],
                    type = "range",
                    order = 100,
                    min = 0.5,
                    max = 2,
                    step = 0.5,
                },
                autohidedelay = {
                    name = L["Auto Hide Delay"],
                    desc = L["Set the length of time (in seconds) it takes for the menu to disappear once you move the mouse away."],
                    type = "range",
                    order = 200,
                    min = 0,
                    max = 5,
                },
            }
        }
        return options
    end
end

-- Set the font for the bar text
function XPBarNone:SetFontOptions()
    local font, size, flags
    if db.general.font then
        font = LSM3:Fetch("font", db.general.font)
    end
    -- Use regular font if we couldn't restore the saved one.
    if not font then
        font, size, flags = GameFontNormal:GetFont()
    end
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
    -- XXX: Blizz tiling breakage
    self.frame.background:GetStatusBarTexture():SetHorizTile(false)
    self.frame.remaining:GetStatusBarTexture():SetHorizTile(false)
    self.frame.xpbar:GetStatusBarTexture():SetHorizTile(false)
end

-- Set bar widths
function XPBarNone:SetWidth(width)
    self.frame:SetWidth(width)
    self.frame.button:SetWidth(width - 4)
    self.frame.background:SetWidth(width - 4)
    self.frame.remaining:SetWidth(width - 4)
    self.frame.xpbar:SetWidth(width - 4)
    self.frame.bubbles:SetWidth(width - 4)
    self:UpdateXPBar()
end

function XPBarNone:SetHeight(height)
    self.frame:SetHeight(height)
    self.frame.background:SetHeight(height - 8)
    self.frame.remaining:SetHeight(height - 8)
    self.frame.xpbar:SetHeight(height - 8)
    self.frame.bubbles:SetHeight(height - 8)
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

-- Toggle auto watching
function XPBarNone:ToggleAutoWatch()
    if db.rep.autowatchrep then
        self:RegisterEvent("COMBAT_TEXT_UPDATE")
    else
        self:UnregisterEvent("COMBAT_TEXT_UPDATE")
    end
end

-- Refreshes the config for profiles support, NYI
function XPBarNone:RefreshConfig(event, database, newProfileKey)
    db = database.profile
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
    -- Nil out the exalted colour in repHexColour so it can be regenerated
    repHexColour[STANDING_EXALTED] = nil
    self:RestorePosition()
    self:UpdateXPBar()
end

function XPBarNone:OnInitialize()
    -- Get the DB.
    self.db = LibStub("AceDB-3.0"):New("XPBarNoneDB", defaults, true)
    db = self.db.profile
    -- Register options
    local myName = GetAddOnMetadata("XPBarNone", "Title")
    local ACRegistry = LibStub("AceConfigRegistry-3.0")
    local ACDialog = LibStub("AceConfigDialog-3.0")
    ACRegistry:RegisterOptionsTable("XPBarNone-General", GetOptions)
    ACRegistry:RegisterOptionsTable("XPBarNone-XP", GetOptions)
    ACRegistry:RegisterOptionsTable("XPBarNone-Rep", GetOptions)
    ACRegistry:RegisterOptionsTable("XPBarNone-Colours", GetOptions)
    ACRegistry:RegisterOptionsTable("XPBarNone-RepMenu", GetOptions)
    ACDialog:AddToBlizOptions("XPBarNone-General", myName)
    ACDialog:AddToBlizOptions("XPBarNone-XP", L["XP Bar"], myName)
    ACDialog:AddToBlizOptions("XPBarNone-Rep", L["Reputation Bar"], myName)
    ACDialog:AddToBlizOptions("XPBarNone-Colours", L["Bar Colours"], myName)
    ACDialog:AddToBlizOptions("XPBarNone-RepMenu", L["Reputation Menu"], myName)
    -- Register a chat command to open options
    self:RegisterChatCommand("xpbn", function() InterfaceOptionsFrame_OpenToCategory(myName) end)
    -- Profiles
    local popts = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    ACRegistry:RegisterOptionsTable("XPBarNone-Profiles", popts)
    ACDialog:AddToBlizOptions("XPBarNone-Profiles", L["Profiles"], myName)
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
    -- Used for hiding XP Bar during pet battles
    self:RegisterEvent("PET_BATTLE_OPENING_START")
    self:RegisterEvent("PET_BATTLE_CLOSE")
    -- Register some LSM3 callbacks
    --LSM3.RegisterCallback(self, "LibSharedMedia_Registered", "MediaUpdate")
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
    if not db.general.commify or type(num) ~= "number" or tostring(num):len() <= 3 then
        return num
    end

    return BreakUpLargeNumbers(num)
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
    local ktl = remainingXP / avgxp

    -- We can divide by zero if we're on a new character. Protect against breakage here.
    if ktl == math_huge then
        return 0
    end
    return math_ceil(remainingXP / avgxp)
end

-- Get the XP bar text
local function GetXPText(restedXP)
    local text = db.xp.xpstring

    text = text:gsub("%[curXP%]", commify(XPBarNone.cXP))
    text = text:gsub("%[maxXP%]", commify(XPBarNone.nXP))

    if restedXP then
        text = text:gsub("%[restXP%]", commify(restedXP))
        text = text:gsub("%[restPC%]", ("%.1f%%%%"):format(restedXP / XPBarNone.nXP * 100))
    else
        text = text:gsub("%[restXP%]", db.xp.showzerorest and "0" or "")
        text = text:gsub("%[restPC%]", db.xp.showzerorest and "0%%" or "")
    end

    text = text:gsub("%[curPC%]", ("%.1f%%%%"):format(XPBarNone.cXP / XPBarNone.nXP * 100))
    text = text:gsub("%[needPC%]", ("%.1f%%%%"):format(100 - (XPBarNone.cXP / XPBarNone.nXP * 100)))
    text = text:gsub("%[pLVL%]", UnitLevel("player"))
    text = text:gsub("%[nLVL%]", UnitLevel("player") + 1)
    text = text:gsub("%[mLVL%]", maxPlayerLevel)
    text = text:gsub("%[needXP%]", commify(XPBarNone.remXP))
    text = text:gsub("%[isLocked%]", IsXPUserDisabled() and "*" or "")

    local ktl = tonumber(("%d"):format(GetNumKTL()))
    if ktl <= 0 or not ktl then
        ktl = '?'
    end

    text = text:gsub("%[KTL%]", commify(ktl))
    text = text:gsub("%[BTL%]", ("%d"):format(math_ceil(20 - ((XPBarNone.cXP / XPBarNone.nXP * 100) / 5))))

    return text
end

-- Set the watched faction based on the faction name
local function SetWatchedFactionName(faction)
    for i = 1, GetNumFactions() do
        -- name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(factionIndex);
        local name,_,_,_,_,_,_,_,isHeader,_,_,isWatched,_,_,_,_ = GetFactionInfo(i)
        if name == faction then
            -- If it's not watched and it's not a header
            -- watch it.
            if not isWatched then
                SetWatchedFactionIndex(i)
            end
            return
        end
    end
end

-- Cache FACTION_STANDING_LABEL
local factionStandingLabel
do
    local _G = _G
    factionStandingLabel = setmetatable({}, {
        __index = function(t, k)
            local FSL = _G["FACTION_STANDING_LABEL"..k]
            t[k] = FSL
            return FSL
        end,
    })
end

-- GetRepText
-- Returns the text for the reputation bar after substituting the various tokens
local function GetRepText(repName, repStanding, repMin, repMax, repValue, friendID, friendTextLevel, hasBonusRep, canBeLFGBonus, isFactionParagon)
    local text = db.rep.repstring

    local standingText
    if friendID then
        standingText = friendTextLevel
    else
        -- Add a + next to the standing for bonus or paragon reps.
        if hasBonusRep or isFactionParagon then
            standingText = ("%s+"):format(factionStandingLabel[repStanding])
        else
            standingText = factionStandingLabel[repStanding]
        end
    end

    -- Now replace all the tokens
    text = text:gsub("%[faction%]", repName)
    text = text:gsub("%[standing%]", standingText)
    text = text:gsub("%[curRep%]", commify(repValue))
    text = text:gsub("%[maxRep%]", commify(repMax))
    text = text:gsub("%[repPC%]", ("%.1f%%%%"):format(repValue / repMax * 100))
    text = text:gsub("%[needRep%]", commify(repMax - repValue))
    text = text:gsub("%[needPC%]", ("%.1f%%%%"):format(math_floor(100 - (repValue / repMax * 100))))

    return text
end

-- Get the text for the rep tooltip
local function GetRepTooltipText(standingText, bottom, top, earned)
    local maxRep = top - bottom
    local curRep = earned - bottom
    local repPercent = curRep / maxRep * 100

    return (L["Standing: %s\nRep: %s/%s [%.1f%%]"]):format(standingText, commify(curRep), commify(maxRep), repPercent)
end

-- Toggle the collapsed sections in the rep menu
function XPBarNone:ToggleCollapse(args)
    local tooltip, factionIndex, name, hasRep, isCollapsed = args[1], args[2], args[3], args[4], args[5]
    if hasRep and GetMouseButtonClicked() == "RightButton" then
        SetWatchedFactionName(name)
    else
        if isCollapsed then
            ExpandFactionHeader(factionIndex)
        else
            CollapseFactionHeader(factionIndex)
        end
    end
    tooltip:UpdateScrolling()
end

function XPBarNone:SetWatchedFactionIndex(faction)
    SetWatchedFactionIndex(faction)
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
    self.frame.button:SetScript("OnClick", function(clickself, button, down)
        -- Paste currently displayed text to edit box on Shift-LeftClick
        if IsShiftKeyDown() and button == "LeftButton" then
            local activeWin = ChatEdit_GetActiveWindow()
            if not activeWin then
                activeWin = ChatEdit_GetLastActiveWindow()
                activeWin:Show()
            end
            activeWin:SetFocus()
            activeWin:Insert(self.frame.bartext:GetText())
        end
        -- Display options on Shift-RightClick
        if IsShiftKeyDown() and button == "RightButton" then
            InterfaceOptionsFrame_OpenToCategory(GetAddOnMetadata("XPBarNone", "Title"))
        end
        -- Display Reputation menu on Ctrl-RightClick
        if IsControlKeyDown() and button == "RightButton" then
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
    if IsAddOnLoaded("ElvUI") or IsAddOnLoaded("TukUI") then
        self.frame.xpbar:CreateBackdrop()
    end

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
    -- XXX: Blizz tiling breakage.
    self.frame.bubbles:GetStatusBarTexture():SetHorizTile(false)

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
    self:ToggleBorder()
    self:RestorePosition()

    -- Kill function after the bar is made.
    XPBarNone.CreateXPBar = nil
end

-- LSM3 Updates.
function XPBarNone:MediaUpdate()

end

-- Check for faction updates for the auto rep watching
function XPBarNone:COMBAT_TEXT_UPDATE(event, msgtype, faction, amount)
    -- Abort if it's not a FACTION update
    if msgtype ~= "FACTION" then
        return
    end
    if db.rep.autowatchrep then
        -- Don't track Horde / Alliance classic faction header
        if faction == FACTION_HORDE or faction == FACTION_ALLIANCE then
            return
        end

        -- We don't want to watch factions we're losing rep with
        if tostring(amount):match("^%-.*") then
            return
        end

        -- Fix for auto tracking guild reputation since the COMBAT_TEXT_UPDATE doesn't contain
        -- the guild name, it just contains "Guild"
        if faction == GUILD then
            if db.rep.autotrackguild then
                faction = GetGuildInfo("player")
            else
                return
            end
        end

        -- Everything ok? Watch the faction!
        SetWatchedFactionName(faction)
    end
end

function XPBarNone:PET_BATTLE_OPENING_START()
    self.frame:Hide()
end

function XPBarNone:PET_BATTLE_CLOSE()
    self.frame:Show()
end

function XPBarNone:UpdateXPData()
    local prevXP = self.cXP or 0
    self.cXP = UnitXP("player")
    self.nXP = UnitXPMax("player")
    self.remXP = self.nXP - self.cXP
    self.diffXP = self.cXP - prevXP

    if self.diffXP > 0 then
        lastXPValues[(sessionkills % 10) + 1] = self.diffXP
        sessionkills = sessionkills + 1
    end

    self:UpdateXPBar()
end

function XPBarNone:UpdateRepData()
    if not db.rep.showrepbar then
        return
    end

    local repName, repStanding, repMin, repMax, repValue, factionID = GetWatchedFactionInfo()
    local isFactionParagon = IsFactionParagon(factionID)

    -- Set the colour of the bar text.
    local txtcol = db.colours.reptext
    self.frame.bartext:SetTextColor(txtcol.r, txtcol.g, txtcol.b, txtcol.a)

    if repName == nil then
        if self.frame.xpbar:IsVisible() then
            self.frame.xpbar:Hide()
        end
        self.frame.bartext:SetText(L["You need to select a faction to watch."])
        return
    end

    -- friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold
    local _, hasBonusRep, canBeLFGBonus
    local friendID, friendRep, friendMaxRep, friendName, _, _, friendTextLevel, friendThresh, nextFriendThresh = GetFriendshipReputation(factionID)
    if friendID then
        if nextFriendThresh then
            -- Not yet "Exalted" with friend, use provided max for current level.
            repMax = nextFriendThresh
        else
            -- "Exalted". Fake the maxRep.
            repMax = friendMaxRep + 1
        end
        repMax = repMax - friendThresh
        repValue = friendRep - friendThresh
        repMin = 0
    else
        -- name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(factionIndex);
        _,_,_,_,_,_,_,_,_,_,_,_,_,_,hasBonusRep,canBeLFGBonus = GetFactionInfoByID(factionID)

        -- If a faction is exalted in Legion, it might be a paragon rep.
        -- Check for that, if it's not, fudge the numbers to make it appear
        -- like the old full rep bar.
        if repStanding == STANDING_EXALTED then
            if isFactionParagon then
                local parValue, parThresh, _, _ = GetFactionParagonInfo(factionID)
                -- parValue is additive. We need to modulo to get the real
                -- reputation value vs. the current threshold.
                repMax = parThresh
                repValue = parValue % parThresh
            else
                repMax = 1000
                repValue = 999
            end
        else
            repMax = repMax - repMin
            repValue = repValue - repMin
        end

        repMin = 0
    end

    if not self.frame.xpbar:IsVisible() then
        self.frame.xpbar:Show()
    end

    self.frame.remaining:Hide()
    self.frame.xpbar:SetMinMaxValues(math_min(0, repValue), repMax)
    self.frame.xpbar:SetValue(repValue)

    -- Use our own colour for exalted.
    local repColour
    if repStanding == STANDING_EXALTED then
        repColour = db.colours.exalted
    else
        repColour = FACTION_BAR_COLORS[repStanding]
    end
    self.frame.xpbar:SetStatusBarColor(repColour.r, repColour.g, repColour.b, repColour.a)

    if not db.general.hidetext then
        self.frame.bartext:SetText(
        GetRepText(
        repName,
        repStanding,
        repMin,
        repMax,
        repValue,
        friendID,
        friendTextLevel,
        hasBonusRep,
        canBeLFGBonus,
        isFactionParagon
        )
        )
    else
        self.frame.bartext:SetText("")
    end
end

function XPBarNone:UpdateXPBar()
    -- If the menu is open and we're in here, refresh the menu.
    if LQT:IsAcquired("XPBarNoneTT") then
        self:DrawRepMenu()
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
        if IsResting() and db.xp.indicaterest then
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

    -- Set the colour of the bar text
    local txtcol = db.colours.xptext
    self.frame.bartext:SetTextColor(txtcol.r, txtcol.g, txtcol.b, txtcol.a)

    -- Hide the text or not?
    if not db.general.hidetext then
        self.frame.bartext:SetText(GetXPText(restedXP))
    else
        self.frame.bartext:SetText("")
    end
end

-- When max level is hit, show only the rep bar.
function XPBarNone:LevelUp(event, level)
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

-- Mainly from LibQTip
local function GetTipAnchor(frame, tooltip)
    local uiScale = UIParent:GetEffectiveScale()
    local uiWidth = UIParent:GetWidth()
    local ttWidth = tooltip:GetWidth()
    local x, y = GetCursorPosition()
    if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
    -- Always use the LEFT of the bar as the anchor
    local hhalf = "LEFT"
    local vhalf = ((y / uiScale) > UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"
    local fX, fY = (x / uiScale) - (ttWidth / 2), y / uiScale
    -- OK, since :SetClampedToScreen is stupid, we'll check if the tooltip goes off the screen manually.
    -- OK, if it's less than 0, it's gone off the left edge.
    if fX < 0 then
        fX = 0
    end
    -- If it's greater than the size of the screen, it's off to the right
    -- Move it back in by a few pixels.
    if (x / uiScale) + (ttWidth / 2) > uiWidth then
        fX = fX - ((x / uiScale) + (ttWidth / 2) - uiWidth)
    end
    --XPBarNone:Print(("Anchoring: %s %s %s %s %s"):format(vhalf..hhalf, frame:GetName(), (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf, fX, fY))
    return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf, fX, 0
end

-- Setup tips, etc.
function XPBarNone:MakeRepTooltip()
    if not LQT:IsAcquired("XPBarNoneTT") then
        tooltip = LQT:Acquire("XPBarNoneTT", 2, "CENTER", "LEFT")
    end
    tooltip:SetClampedToScreen(true)
    tooltip:SetScale(db.repmenu.scale)
    -- Anchor to the cursor position along the bar.
    tooltip:ClearAllPoints()
    tooltip:SetPoint(GetTipAnchor(self.frame.button, tooltip))
    tooltip:SetAutoHideDelay(db.repmenu.autohidedelay, self.frame.button)
    tooltip:EnableMouse()
    self:DrawRepMenu()
end

-- repHex colours are automatically generated and cached when first looked up.
do
    repHexColour = setmetatable({}, {
        -- Called when indexing fails (key doesn't exist in table)
        __index = function(t, k)
            local FBC
            if k == STANDING_EXALTED then
                FBC = db.colours.exalted
            else
                FBC = FACTION_BAR_COLORS[k]
            end
            local hex = ("%02x%02x%02x"):format(FBC.r * 255, FBC.g * 255, FBC.b * 255)
            t[k] = hex
            return hex
        end,
    })
end

-- Reputation menu
function XPBarNone:DrawRepMenu()
    local linenum = nil
    local checkIcon = "|TInterface\\Buttons\\UI-CheckBox-Check:16:16:1:-1|t"
    local NormalFont = tooltip:GetFont()
    local GameTooltipTextSmall = GameTooltipTextSmall

    tooltip:Hide()
    tooltip:Clear()

    -- Reputations
    for faction = 1, GetNumFactions() do
        -- name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(factionIndex);
        local name,_,standing,bottom,top,earned,atWar,_,isHeader,isCollapsed,hasRep,isWatched,isChild,repID,hasBonusRep,canBeLFGBonus = GetFactionInfo(faction)

        -- Set these to previous max values for exalted. Legion changed how
        -- exalted works.
        if standing == STANDING_EXALTED then
            bottom = 0
            top = 1000
            earned = 999
        end

        if not isHeader then
            local friendID, friendRep, friendMaxRep, friendName, _, _, friendTextLevel, friendThresh, friendThreshNext = GetFriendshipReputation(repID)
            local isFactionParagon = IsFactionParagon(repID)

            -- Faction
            local standingText
            if friendID then
                standingText = friendTextLevel
                bottom = 0
                earned = friendRep - friendThresh

                if friendThreshNext then
                    -- Not "Exalted", use provided figure for next level.
                    top = friendThreshNext
                else
                    -- "Exalted". Fake exalted max.
                    top = friendMaxRep + 1
                    earned = 1
                end

                top = top - friendThresh
            else
                if hasBonusRep or isFactionParagon then
                    standingText = ("%s+"):format(factionStandingLabel[standing])
                else
                    standingText = factionStandingLabel[standing]
                end
            end

            -- Paragon reputation values
            if isFactionParagon then
                local parValue, parThresh, _, _ = GetFactionParagonInfo(repID)
                bottom = 0
                top = parThresh
                earned = parValue % parThresh
            end

            -- Legion introduced a bug where you can be shown a
            -- completely blank rep, so only add menu entries for
            -- things with a name.
            if name then
                local tipText = GetRepTooltipText(standingText, bottom, top, earned)

                linenum = tooltip:AddLine(nil)
                tooltip:SetCell(linenum, 1, isWatched and checkIcon or " ", NormalFont)
                tooltip:SetCell(linenum, 2, ("|cff%s%s (%s)|r"):format(repHexColour[standing], name, standingText), GameTooltipTextSmall)
                tooltip:SetLineScript(linenum, "OnMouseUp", XPBarNone.SetWatchedFactionIndex, faction)
                tooltip:SetLineScript(linenum, "OnEnter", XPBarNone.SetTooltip, {name,tipText})
                tooltip:SetLineScript(linenum, "OnLeave", XPBarNone.HideTooltip)
            end
        else
            -- Header
            local tipText, iconPath
            if isCollapsed then
                tipText = (L["Click to expand %s faction listing"]):format(name)
                iconPath = "|TInterface\\Buttons\\UI-PlusButton-Up:16:16:1:-1|t"
            else
                tipText = (L["Click to collapse %s faction listing"]):format(name)
                iconPath = "|TInterface\\Buttons\\UI-MinusButton-Up:16:16:1:-1|t"
            end

            --linenum = tooltip:AddLine(iconPath, name)
            linenum = tooltip:AddLine(nil)
            tooltip:SetCell(linenum, 1, iconPath, NormalFont)
            -- If this header also has rep, then change the header slightly
            -- and fix the tooltip.
            if hasRep then
                local standingText
                if hasBonusRep then
                    standingText = ("%s+"):format(factionStandingLabel[standing])
                else
                    standingText = factionStandingLabel[standing]
                end

                tooltip:SetCell(linenum, 2, ("%s (%s)"):format(name, standingText), NormalFont)
                tipText = ("%s|n%s|n%s"):format(
                    GetRepTooltipText(standingText, bottom, top, earned),
                    tipText,
                    L["Right click to watch faction"]
                )
            else
                tooltip:SetCell(linenum, 2, name, NormalFont)
            end
            tooltip:SetLineScript(linenum, "OnMouseUp", XPBarNone.ToggleCollapse, {tooltip,faction,name,hasRep,isCollapsed})
            tooltip:SetLineScript(linenum, "OnEnter", XPBarNone.SetTooltip, {name,tipText})
            tooltip:SetLineScript(linenum, "OnLeave", XPBarNone.HideTooltip)
        end
    end

    tooltip:UpdateScrolling()
    tooltip:Show()
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
