---@type GL
local _, GL = ...;

---@class PlusTwos
GL.PlusTwos = {};

local DB = GL.DB; ---@type DB
local PlusTwos = GL.PlusTwos; ---@type PlusTwos

--- Add a plus two for the given player name and return the current plusTwo value
---
---@param playerName string
---@return number
function PlusTwos:add(playerName)
    GL:debug("PlusTwos:add");

    playerName = GL:normalizedName(playerName);

    if (not DB.PlusTwos[playerName]) then
        DB.PlusTwos[playerName] = 1;
    else
        DB.PlusTwos[playerName] = DB.PlusTwos[playerName] + 1;
    end

    self:triggerChangeEvent();

    return DB.PlusTwos[playerName];
end

--- Deduct a plus two for the given player name and return the current plusTwo value
---
---@param playerName string
---@return number
function PlusTwos:deduct(playerName)
    GL:debug("PlusTwos:deduct");

    playerName = GL:normalizedName(playerName);

    if (not DB.PlusTwos[playerName]) then
        DB.PlusTwos[playerName] = 0;
    else
        -- Make sure the plusTwo doesn't end up below 0
        DB.PlusTwos[playerName] = math.max(DB.PlusTwos[playerName] - 1, 0);
    end

    self:triggerChangeEvent();

    return DB.PlusTwos[playerName];
end

--- Set a given player's plusTwo value to 0
---
---@param playerName string
---@return number
function PlusTwos:setToZero(playerName)
    GL:debug("PlusTwos:setToZero");

    playerName = GL:normalizedName(playerName);

    if (not DB.PlusTwos[playerName]) then
        DB.PlusTwos[playerName] = 0;
    end

    DB.PlusTwos[playerName] = 0;
    self:triggerChangeEvent();

    return 0;
end

--- Clear all PlusTwos
---
---@return void
function PlusTwos:clear()
    GL:debug("PlusTwos:clear");

    DB.PlusTwos = {};

    self:triggerChangeEvent();
end

--- Get a player's PlusTwos value
---
---@param playerName string
---@return number
function PlusTwos:get(playerName)
    GL:debug("PlusTwos:get");

    playerName = GL:normalizedName(playerName);

    return DB.PlusTwos[playerName] or 0;
end

--- Set a player's PlusTwos value
---
---@param playerName string
---@param value number
---@return void
function PlusTwos:set(playerName, value)
    GL:debug("PlusTwos:set");

    -- A table was provided, treat it as a mass assignment
    if (type(playerName) == "table") then
        return self:massSet(playerName);
    end

    playerName = GL:normalizedName(playerName);

    DB.PlusTwos[playerName] = GL:round(value);
end

--- Assign PlusTwo values en masse
---
---@param PlusTwosByPlayerName table
---@return void
function PlusTwos:massSet(plusTwosByPlayerName)
    GL:debug("PlusTwos:massSet");

    for playerName, value in pairs(plusTwosByPlayerName) do
        playerName = GL:normalizedName(playerName);

        DB.PlusTwos[playerName] = GL:round(value);
    end

    self:triggerChangeEvent();
end

--- Trigger the PLUSTWOS_CHANGED event
---
---@return void
function PlusTwos:triggerChangeEvent()
    GL:debug("PlusTwos:triggerChangeEvent");

    GL.Events:fire("GL.PLUSTWOS_CHANGED");
end

GL:debug("PlusTwos.lua");