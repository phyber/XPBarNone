-- vim:ft=lua:
std = "lua51"

-- Show codes for warnings
codes = true

-- Disable colour output
color = false

-- Suppress reports for files without warnings
quiet = 1

-- Disable max line length check
max_line_length = false

-- We don't want to check externals Libs or this config file
exclude_files = {
    ".release/",
    "Libs/",
    ".luacheckrc",
}

-- Ignored warnings
ignore = {
    "211/_",             -- Unused in UpdateRepData
    "211/atWar",         -- Unused in DrawRepMenu
    "211/canBeLFGBonus", -- Unused in DrawRepMenu
    "211/friendName",    -- Unused in UpdateRepData
    "211/fY",            -- Unused in GetTipAnchor
    "211/isChild",       -- Unused in DrawRepMenu
    "212/callback",      -- Unused in OnEnable
    "212/canBeLFGBonus", -- Unused in GetRepText
    "212/clickself",     -- Unused in OnClick script
    "212/down",          -- Unused in OnClick script
    "212/event",         -- Unused in RefreshConfig
    "212/newProfileKey", -- Unused in RefreshConfig
    "212/repMin",        -- Unused in GetRepText
    "212/self",          -- Unused in various XPBarNone methods
    "212/uiTypes",       -- Unused in GetOptions
    "212/uiName",        -- Unused in GetOptions
    "212/info",          -- Unused in option setters
    "231/size",          -- Unaccessed size variable in SetFontOptions
    "421/_G",            -- Shadowed _G in closure
    "431/tooltip",       -- Shadowed upvalue tooltip
}

-- Globals that we read/write
globals = {
    -- Our globals
    "XPBarNone",
}

-- Globals that we only read
read_globals = {
    -- Libraries
    "LibStub",

    -- Ace
    "AceGUIWidgetLSMlists",

    -- Lua globals
    "_G",

    -- API Functions
    "BreakUpLargeNumbers",
    "C_AzeriteItem",
    "C_Reputation",
    "ChatEdit_GetActiveWindow",
    "ChatEdit_GetLastActiveWindow",
    "CollapseFactionHeader",
    "CreateFrame",
    "ExpandFactionHeader",
    "GameTooltip_SetDefaultAnchor",
    "GetAddOnMetadata",
    "GetBuildInfo",
    "GetContainerItemInfo",
    "GetCurrentCombatTextEventInfo",
    "GetCursorPosition",
    "GetExpansionLevel",
    "GetFriendshipReputation",
    "GetGuildInfo",
    "GetInventoryItemID",
    "GetItemInfo",
    "GetMouseButtonClicked",
    "GetNumFactions",
    "GetFactionInfo",
    "GetFactionInfoByID",
    "GetWatchedFactionInfo",
    "GetXPExhaustion",
    "InterfaceOptionsFrame_OpenToCategory",
    "IsAddOnLoaded",
    "IsControlKeyDown",
    "IsResting",
    "IsShiftKeyDown",
    "IsXPUserDisabled",
    "Item",
    "SetWatchedFactionIndex",
    "UnitLevel",
    "UnitXP",
    "UnitXPMax",

    -- FrameXML Globals
    "BACKGROUND",
    "FACTION_ALLIANCE",
    "FACTION_BAR_COLORS",
    "FACTION_HORDE",
    "GUILD",
    "ITEM_QUALITY_COLORS",
    "LARGE_NUMBER_SEPERATOR",
    "LE_ITEM_QUALITY_ARTIFACT",
    "MAX_PLAYER_LEVEL_TABLE",

    -- Frames
    "GameTooltip",
    "UIParent",
    "WorldFrame",

    -- Fonts
    "GameFontNormal",
    "GameTooltipTextSmall",
}
