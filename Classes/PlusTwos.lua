---@type GL
local _, GL = ...;

---@class PlusTwos
GL.PlusTwos = {};

local DB = GL.DB; ---@type DB
local PlusTwos = GL.PlusTwos; ---@type PlusTwos
local Constants = GL.Data.Constants; ---@type Data
local CommActions = Constants.Comm.Actions;

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

    DB.PlusTwos[playerName] = GL:round(value or 0);

    self:triggerChangeEvent()
end

--- Assign PlusTwo values en masse
---
---@param PlusTwosByPlayerName table
---@return void
function PlusTwos:massSet(plusTwosByPlayerName)
    GL:debug("PlusTwos:massSet");

    for playerName, value in pairs(plusTwosByPlayerName) do
        playerName = GL:normalizedName(playerName or 0);

        DB.PlusTwos[playerName] = GL:round(value or 0);
    end

    self:triggerChangeEvent();
end

--- Trigger the PLUSONES_CHANGED event
function PlusTwos:triggerChangeEvent()
    GL:debug("PlusTwos:triggerChangeEvent");

    GL.Events:fire("GL.PLUSTWOS_CHANGED");

    if (self.broadcastInProgress) then
        GL:error("Broadcast still in progress");
        return false;
    end

    if (not GL.User.isInGroup) then
        GL:warning("Personne ?? qui diffuser, vous n'??tes pas en groupe !");
        return false;
    end

    if (not GL.User.hasAssist
        and not GL.User.isMasterLooter
    ) then
        GL:warning("Droits insuffisants pour diffuser, vous devez ??tre ML, avoir une promote ou le lead !");
        return false;
    end

    self.broadcastInProgress = true;

    local Broadcast = function ()
        GL:message("Diffusion des donn??es de +2...");

        print(CommActions.broacastPlusTwos);

        GL.CommMessage.new(
            CommActions.broadcastPlusTwos,
            GL.DB.PlusTwos,
            "GROUP"
        ):send(function ()
            GL:success("Diffusion +2 termin??e");
            self.broadcastInProgress = false;
        end);
    end

    -- We're about to send a lot of data which will put strain on CTL
    -- Make sure we're out of combat before doing so!
    if (UnitAffectingCombat("player")) then
        GL:message("Vous ??tes actuellement en combat, la diffusion des +2 est repouss??e");

        GL.Events:register("PlusTwosOutOfCombatListener", "PLAYER_REGEN_ENABLED", function ()
            GL.Events:unregister("PlusTwosOutOfCombatListener");
            Broadcast();
        end);
    else
        Broadcast();
    end

    return true;
end


--- Process an incoming PlusTwos broadcast
---
---@param CommMessage CommMessage
function PlusTwos:receiveBroadcast(CommMessage)
    GL:debug("PlusTwos:receiveBroadcast");

    -- No need to update our tables if we broadcasted them ourselves
    if (CommMessage.Sender.id == GL.User.id) then
        GL:debug("PlusTwos:receiveBroadcast received by self, skip");
        return true;
    end

    local Data = CommMessage.content;
    if (not GL:empty(Data)) then
        GL:warning("Tentative de traitement de donn??es de +2 en provenance de " .. CommMessage.Sender.name);

        if (type(Data) ~= "table" or GL:empty(Data)
        ) then
            GL:error("Donn??es de +2 invalides re??ues de " .. CommMessage.Sender.name);
            return;
        end

        -- Validate dataset
        for player, value in pairs(Data) do
            value= tonumber(value);

            if (GL:empty(player)) then
                GL:error("Donn??es de +2 invalides re??ues de " .. CommMessage.Sender.name);
                return;
            end

        end

        GL:success("Donn??es de +2 synchronis??es");
        GL.DB.PlusTwos = Data;
    end
end
GL:debug("PlusTwos.lua");