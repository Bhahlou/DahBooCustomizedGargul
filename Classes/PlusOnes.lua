---@type GL
local _, GL = ...;

---@class PlusOnes
GL.PlusOnes = {
    broadcastInProgress = false,
};

local DB = GL.DB; ---@type DB
local PlusOnes = GL.PlusOnes; ---@type PlusOnes
local CommActions = GL.Data.Constants.Comm.Actions or {};

--- Add a plus one for the given player name and return the current plusOne value
---
---@param playerName string
---@return number
function PlusOnes:add(playerName)
    GL:debug("PlusOnes:add");

    playerName = GL:normalizedName(playerName);

    if (not DB.PlusOnes[playerName]) then
        DB.PlusOnes[playerName] = 1;
    else
        DB.PlusOnes[playerName] = DB.PlusOnes[playerName] + 1;
    end

    self:triggerChangeEvent();

    return DB.PlusOnes[playerName];
end

--- Deduct a plus one for the given player name and return the current plusOne value
---
---@param playerName string
---@return number
function PlusOnes:deduct(playerName)
    GL:debug("PlusOnes:deduct");

    playerName = GL:normalizedName(playerName);

    if (not DB.PlusOnes[playerName]) then
        DB.PlusOnes[playerName] = 0;
    else
        -- Make sure the plusOne doesn't end up below 0
        DB.PlusOnes[playerName] = math.max(DB.PlusOnes[playerName] - 1, 0);
    end

    self:triggerChangeEvent();

    return DB.PlusOnes[playerName];
end

--- Set a given player's plusOne value to 0
---
---@param playerName string
---@return number
function PlusOnes:setToZero(playerName)
    GL:debug("PlusOnes:setToZero");

    playerName = GL:normalizedName(playerName);

    if (not DB.PlusOnes[playerName]) then
        DB.PlusOnes[playerName] = 0;
    end

    DB.PlusOnes[playerName] = 0;
    self:triggerChangeEvent();

    return 0;
end

--- Clear all plusOnes
---
---@return void
function PlusOnes:clear()
    GL:debug("PlusOnes:clear");

    DB.PlusOnes = {};

    self:triggerChangeEvent();
end

--- Get a player's PlusOnes value
---
---@param playerName string
---@return number
function PlusOnes:get(playerName)
    GL:debug("PlusOnes:get");

    playerName = GL:normalizedName(playerName);

    return DB.PlusOnes[playerName] or 0;
end

--- Set a player's PlusOnes value
---
---@param playerName string
---@param value number
---@return void
function PlusOnes:set(playerName, value)
    GL:debug("PlusOnes:set");

    -- A table was provided, treat it as a mass assignment
    if (type(playerName) == "table") then
        return self:massSet(playerName);
    end

    playerName = GL:normalizedName(playerName);

    DB.PlusOnes[playerName] = GL:round(value or 0);

    self:triggerChangeEvent();
end

--- Assign PlusOne values en masse
---
---@param plusOnesByPlayerName table
---@return void
function PlusOnes:massSet(plusOnesByPlayerName)
    GL:debug("PlusOnes:massSet");

    for playerName, value in pairs(plusOnesByPlayerName) do
        playerName = GL:normalizedName(playerName or 0);

        DB.PlusOnes[playerName] = GL:round(value or 0);
    end

    self:triggerChangeEvent();
end

--- Trigger the PLUSONES_CHANGED event
function PlusOnes:triggerChangeEvent()
    GL:debug("PlusOnes:triggerChangeEvent");
    GL.Events:fire("GL.PLUSONES_CHANGED");

    if (self.broadcastInProgress) then
        GL:error("Broadcast still in progress");
        return false;
    end

    if (not GL.User.isInGroup) then
        GL:warning("Personne à qui diffuser, vous n'êtes pas en groupe !");
        return false;
    end

    if (not GL.User.hasAssist
        and not GL.User.isMasterLooter
    ) then
        GL:warning("Droits insuffisants pour diffuser, vous devez être ML, avoir une promote ou le lead !");
        return false;
    end

    self.broadcastInProgress = true;

    local Broadcast = function ()
        GL:message("Diffusion des données de +1...");

        GL.CommMessage.new(
            CommActions.broadcastPlusOnes,
            GL.DB.PlusOnes,
            "GROUP"
        ):send(function ()
            GL:success("Diffusion +1 terminée");
            self.broadcastInProgress = false;
        end);
    end

    -- We're about to send a lot of data which will put strain on CTL
    -- Make sure we're out of combat before doing so!
    if (UnitAffectingCombat("player")) then
        GL:message("Vous êtes actuellement en combat, la diffusion des +1 est repoussée");

        GL.Events:register("PlusOnesOutOfCombatListener", "PLAYER_REGEN_ENABLED", function ()
            GL.Events:unregister("PlusOnesOutOfCombatListener");
            Broadcast();
        end);
    else
        Broadcast();
    end

    return true;
end

--- Process an incoming PlusOnes broadcast
---
---@param CommMessage CommMessage
function PlusOnes:receiveBroadcast(CommMessage)
    GL:debug("PlusOnes:receiveBroadcast");

    -- No need to update our tables if we broadcasted them ourselves
    if (CommMessage.Sender.id == GL.User.id) then
        GL:debug("PlusOnes:receiveBroadcast received by self, skip");
        return true;
    end

    local Data = CommMessage.content;
    if (not GL:empty(Data)) then
        GL:warning("Tentative de traitement de données de +1 en provenance de " .. CommMessage.Sender.name);

        if (type(Data) ~= "table" or GL:empty(Data)
        ) then
            GL:error("Données de +1 invalides reçues de " .. CommMessage.Sender.name);
            return;
        end

        -- Validate dataset
        for player, value in pairs(Data) do
            value= tonumber(value);

            if (GL:empty(player)) then
                GL:error("Données de +1 invalides reçues de " .. CommMessage.Sender.name);
                return;
            end

        end

        GL:success("Données de +1 synchronisées");
        GL.DB.PlusOnes = Data;
    end
end

GL:debug("PlusOnes.lua");