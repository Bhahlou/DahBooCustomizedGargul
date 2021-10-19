---@type GL
local _, GL = ...;

---@class DefaultSettings : Data
GL.Data = GL.Data or {};

GL.Data.DefaultSettings = {
    announceLootToChat = true,
    debugModeEnabled = false,
    highlightsDisabled = false,
    highlightHardReservedItems = true,
    highlightSoftReservedItems = true,
    highlightWishlistedItems = true,
    highlightPriolistedItems = true,
    minimumQualityOfAnnouncedLoot = 4,
    noMessages = false,
    noSounds = false,
    autoOpenCommandHelp = true,
    showMinimapButton = true,
    spreadTheWord = true,
    welcomeMessage = true,
    fixMasterLootWindow = true,

    ShortcutKeys = {
        showLegend = true,
        rollOff = "ALT_CLICK",
        award = "ALT_SHIFT_CLICK",
        disenchant = "CTRL_SHIFT_CLICK",
    },
    MasterLooting = {
        autoOpenMasterLooterDialog = true,
        announceMasterLooter = true,
        doCountdown = false,
        announceRollEnd = true,
        announceRollStart = true,
        numberOfSecondsToCountdown = 5,
        preferredMasterLootingThreshold = 2,
    },
    AwardingLoot = {
        awardMessagesDisabled = false,
        announceAwardMessagesInRW = false,
        autoAssignAfterAwardingAnItem = true,
        autoTradeAfterAwardingAnItem = true,
    },
    ExportingLoot = {
        includeDisenchantedItems = true,
        disenchanterIdentifier = "_disenchanted",
    },
    PackMule = {
        announceDisenchantedItems = true,
        enabled = false,
        persistsAfterReload = false,
        persistsAfterZoneChange = false,
        Rules = {},
    },
    Rolling = {
        showRollOffWindow = true,
        osRollMax = 99,
        closeAfterRoll = false,
    },
    SoftRes = {
        announceInfoInChat = true,
        enableTooltips = true,
        hideInfoOfPeopleNotInGroup = true,
    },
    TMB = {
        hideInfoOfPeopleNotInGroup = true,
        hideWishListInfoIfPriorityIsPresent = true,
        includePrioListInfoInLootAnnouncement = true,
        includeWishListInfoInLootAnnouncement = true,
        maximumNumberOfTooltipEntries = 35,
        maximumNumberOfAnouncementEntries = 5,
        showEntriesWhenSolo = false,
        showItemInfoOnTooltips = true,
        showLootAssignmentReminder = true,
        showPrioListInfoOnTooltips = true,
        showWishListInfoOnTooltips = true,
    },
    UI = {
        RollOff = {
            closeOnStart = true,
            closeOnAward = true,
            timer = 15,
        },
        PopupDialog = {
            Position = {
                offsetX = 0,
                offsetY = -115,
                point = "TOP",
                relativePoint = "TOP",
            }
        },
        Award = {
            closeOnAward = true,
        },
    }
};