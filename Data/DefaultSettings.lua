---@type GL
local _, GL = ...;

---@class DefaultSettings : Data
GL.Data = GL.Data or {};

GL.Data.DefaultSettings = {
    autoOpenCommandHelp = true,
    changeLog = true,
    debugModeEnabled = false,
    highlightsEnabled = true,
    highlightMyItemsOnly = false,
    highlightHardReservedItems = true,
    highlightSoftReservedItems = true,
    highlightWishlistedItems = true,
    highlightPriolistedItems = true,
    noMessages = false,
    noSounds = false,
    profilerEnabled = false,
    showMinimapButton = true,
    welcomeMessage = true,

    DroppedLoot = {
        announceLootToChat = true,
        announceDroppedLootInRW = false,
        minimumQualityOfAnnouncedLoot = 4,
    },
    ShortcutKeys = {
        onlyInGroup = false,
        showLegend = true,
        rollOff = "ALT_CLICK",
        award = "ALT_SHIFT_CLICK",
        disenchant = "CTRL_SHIFT_CLICK",
    },
    MasterLooting = {
        alwaysUseDefaultNote = false,
        announceCountdownOnce = false,
        announceMasterLooter = false,
        autoOpenMasterLooterDialog = true,
        announceMasterLooterMessage = "J'utilise l'addon Dah Boo Customized Gargul pour distribuer les loots. Téléchargez Gargul si vous ne voulez rien rater des rolls !",
        defaultRollOffNote = "/roll 100 pour +1, /roll 80 pour +2, /roll 70 pour +3 ",
        doCountdown = true,
        announceRollEnd = true,
        announceRollStart = true,
        numberOfSecondsToCountdown = 5,
        preferredMasterLootingThreshold = 2,
    },
    AwardingLoot = {
        announceAwardMessagesInGuildChat = false,
        announceAwardMessagesInRW = false,
        autoAssignAfterAwardingAnItem = true,
        autoTradeAfterAwardingAnItem = true,
        awardMessagesEnabled = true,
    },
    ExportingLoot = {
        includeDisenchantedItems = true,
        includeOffspecItems = true,
        customFormat = "@ID;@DATE @TIME;@WINNER",
        disenchanterIdentifier = "_disenchanted",
        showLootAssignmentReminder = true,
    },
    LootTradeTimers = {
        enabled = true,
        maximumNumberOfBars = 5,
        scale = 1,
        showHotkeyReminder = true,
        showOnlyWhenMasterLooting = true,
    },
    PackMule = {
        announceDisenchantedItems = true,
        autoConfirmSolo = false,
        autoConfirmGroup = false,
        enabledForGroupLoot = false,
        enabledForMasterLoot = false,
        Rules = {},
    },
    Rolling = {
        showRollOffWindow = true,
        closeAfterRoll = false,
        scale = 1,
    },
    RollTracking = {
        trackAll = false,
        Brackets = {
            {"+1", 1, 100, 1, false, true},
            {"+2", 1, 80, 2, true, false},
            {"+3", 1, 70, 5, false, false},
        },
    },
    SoftRes = {
        announceInfoInChat = true,
        announceInfoWhenRolling = true,
        enableTooltips = true,
        enableWhisperCommand = true,
        fixPlayerNames = true,
        hideInfoOfPeopleNotInGroup = true,
    },
    BoostedRolls = {
        automaticallyAcceptDataFrom = "",
        automaticallyShareData = true,
        defaultCost = 10,
        defaultPoints = 100,
        defaultStep = 10,
        enabled = false,
        enableWhisperCommand = true,
        fixedRolls = false,
        identifier = "BR",
        priority = 1,
        reserveThreshold = 180,
    },
    TMB = {
        announceInfoWhenRolling = true,
        automaticallyShareData = false,
        hideInfoOfPeopleNotInGroup = true,
        hideWishListInfoIfPriorityIsPresent = true,
        includePrioListInfoInLootAnnouncement = true,
        includeWishListInfoInLootAnnouncement = true,
        maximumNumberOfTooltipEntries = 35,
        maximumNumberOfAnnouncementEntries = 5,
        OSHasLowerPriority = true,
        showEntriesWhenSolo = true,
        showItemInfoOnTooltips = true,
        showPrioListInfoOnTooltips = true,
        showWishListInfoOnTooltips = true,
    },
    TradeAnnouncements = {
        alwaysAnnounceEnchantments = true,
        enchantmentReceived = true,
        enchantmentGiven = true,
        goldReceived = true,
        goldGiven = true,
        itemsReceived = true,
        itemsGiven = true,
        minimumQualityOfAnnouncedLoot = 0,
        mode = "WHEN_MASTERLOOTER",
    },
    UI = {
        RollOff = {
            closeOnStart = false,
            closeOnAward = false,
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
    },
    TMBRaidGroups = {
        useAsSortCriteria = false;
    }
};