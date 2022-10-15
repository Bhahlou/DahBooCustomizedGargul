---@type GL
local _, GL = ...;

---@class DB
GL.DB = {
    _initialized = false,
    AwardHistory = {},
    Cache = {},
    LootPriority = {},
    MinimapButton = {},
    PlusOnes = {},
    PlusTwos = {},
    Settings = {},
    LoadDetails = {},
    SoftRes = {},
    TMB = {},
    BoostedRolls = {},
    TMBRaidGroups = {},
};

local DB = GL.DB;

function DB:_init()
    GL:debug("DB:_init");

    -- No need to initialize this class twice
    if (self._initialized) then
        return;
    end

    if (not DahBooCustomizedGargulDB or not type(DahBooCustomizedGargulDB) == "table") then
        DahBooCustomizedGargulDB = {};
    end

    -- Prepare our database tables
    DahBooCustomizedGargulDB.AwardHistory = DahBooCustomizedGargulDB.AwardHistory or {};
    DahBooCustomizedGargulDB.LootPriority = DahBooCustomizedGargulDB.LootPriority or {};
    DahBooCustomizedGargulDB.MinimapButton = DahBooCustomizedGargulDB.MinimapButton or {};
    DahBooCustomizedGargulDB.PlusOnes = DahBooCustomizedGargulDB.PlusOnes or {};
    DahBooCustomizedGargulDB.PlusTwos = DahBooCustomizedGargulDB.PlusTwos or {};
    DahBooCustomizedGargulDB.Settings = DahBooCustomizedGargulDB.Settings or {};
    DahBooCustomizedGargulDB.LoadDetails = DahBooCustomizedGargulDB.LoadDetails or {};
    DahBooCustomizedGargulDB.SoftRes = DahBooCustomizedGargulDB.SoftRes or {};
    DahBooCustomizedGargulDB.TMB = DahBooCustomizedGargulDB.TMB or {};
    DahBooCustomizedGargulDB.BoostedRolls = DahBooCustomizedGargulDB.BoostedRolls or {};
    DahBooCustomizedGargulDB.TMBRaidGroups = DahBooCustomizedGargulDB.TMBRaidGroups or {};

    -- Provide a shortcut for each table
    self.AwardHistory = DahBooCustomizedGargulDB.AwardHistory;
    self.LootPriority = DahBooCustomizedGargulDB.LootPriority;
    self.MinimapButton = DahBooCustomizedGargulDB.MinimapButton;
    self.PlusOnes = DahBooCustomizedGargulDB.PlusOnes;
    self.PlusTwos = DahBooCustomizedGargulDB.PlusTwos;
    self.Settings = DahBooCustomizedGargulDB.Settings;
    self.LoadDetails = DahBooCustomizedGargulDB.LoadDetails;
    self.SoftRes = DahBooCustomizedGargulDB.SoftRes;
    self.TMB = DahBooCustomizedGargulDB.TMB;
    self.BoostedRolls = DahBooCustomizedGargulDB.BoostedRolls;
    self.TMBRaidGroups = DahBooCustomizedGargulDB.TMBRaidGroups;

    -- Fire DB:store before every logout/reload/exit
    GL.Events:register("DBPlayerLogoutListener", "PLAYER_LOGOUT", self.store);

    self._initialized = true;
end

--- Make sure the database persists between sessions
--- This is just a safety precaution and should strictly
--- speaking not be necessary, but hey you never know!
function DB:store()
    GL:debug("DB:store");

    DahBooCustomizedGargulDB.AwardHistory = GL.DB.AwardHistory;
    DahBooCustomizedGargulDB.LootPriority = GL.DB.LootPriority;
    DahBooCustomizedGargulDB.MinimapButton = GL.DB.MinimapButton;
    DahBooCustomizedGargulDB.PlusOnes = GL.DB.PlusOnes;
    DahBooCustomizedGargulDB.PlusTwos = GL.DB.PlusTwos;
    DahBooCustomizedGargulDB.Settings = GL.Settings.Active;
    DahBooCustomizedGargulDB.LoadDetails = GL.DB.LoadDetails;
    DahBooCustomizedGargulDB.SoftRes = GL.DB.SoftRes;
    DahBooCustomizedGargulDB.TMB = GL.DB.TMB;
    DahBooCustomizedGargulDB.BoostedRolls = GL.DB.BoostedRolls;
    DahBooCustomizedGargulDB.TMBRaidGroups = GL.DB.TMBRaidGroups;
end

-- Get a value from the database, or return a default if it doesn't exist
function DB:get(keyString, default)
    return GL:tableGet(DB, keyString, default);
end

-- Set a database value by a given key and value
function DB:set(keyString, value)
    return GL:tableSet(DB, keyString, value);
end

-- Reset the tables
function DB:reset()
    GL:debug("DB:reset");

    self.AwardHistory = {};
    self.LootPriority = {};
    self.MinimapButton = {};
    self.PlusOnes = {};
    self.PlusTwos = {};
    self.Settings = {};
    self.LoadDetails = {};
    self.SoftRes = {};
    self.TMB = {};
    self.BoostedRolls = {};
    self.TMBRaidGroups = {}

    GL:success("Tables reset");
end

GL:debug("DB.lua");