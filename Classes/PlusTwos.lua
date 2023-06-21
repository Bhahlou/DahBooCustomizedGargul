---@type GL
local _, GL = ...;

---@class PlusTwos
GL.PlusTwos = {
    _initialized = false,
    broadcastInProgress = false,
    requestingData = false,
    ImportDialog = false,
    MaterializedData = {
        DetailsByPlayerName = {},
    },
    QueuedUpdates = {},
    QueuedUpdateBroadcastTimer = false,
};

local DB = GL.DB; ---@type DB
local CommActions = GL.Data.Constants.Comm.Actions;
local PlusTwos = GL.PlusTwos; ---@type PlusTwos

---@return boolean
function PlusTwos:_init()
    GL:debug("PlusTwos:_init");

    if (self._initialized) then
        return false;
    end

    --- Register listener for whisper command.
    GL.Events:register("PlusTwosWhisperListener", "CHAT_MSG_WHISPER", function (event, message, sender)
        if (GL.Settings:get("PlusTwos.enableWhisperCommand", true)) then
            self:handleWhisperCommand(event, message, sender);
        end
    end);

    GL.Events:register("PlusTwosUserJoinedGroupListener", "GL.USER_JOINED_GROUP", function () self:requestData(); end);

    -- Make sure PlusTwos changes are only broadcasted once every 3 seconds
    GL.Events:register("PlusTwosUpdateQueuedListener", "GL.PLUSTWOS_UPDATE_QUEUED", function ()
        GL.Ace:CancelTimer(self.QueuedUpdateBroadcastTimer);

        self.QueuedUpdateBroadcastTimer = GL.Ace:ScheduleTimer(function ()
            self:broadcastQueuedUpdates();
        end, 3);
    end);

    self:materializeData();

    self._initialized = true;
    return true;
end

---@param player string
---@return string
function PlusTwos:playerGUID(player, realm)
    return strlower(GL:addRealm(player, realm));
end

---@return string
function PlusTwos:myGUID()
    return strlower(GL.User.fqn);
end

--- Check whether we trust the given player (currently used to auto-accept incoming broadcasts)
---
---@param playerName string
---@return boolean
function PlusTwos:playerIsTrusted(playerName)
    GL:debug("PlusTwos:playerIsTrusted");

    if (not playerName) then
        return false;
    end

    playerName = GL:nameFormat(playerName);

    local trustedPlayerCSV = GL.Settings:get("PlusTwos.automaticallyAcceptDataFrom", "");
    local TrustedPlayers = GL:strSplit(trustedPlayerCSV, ",");
    for _, player in pairs(TrustedPlayers) do
        if (GL:iEquals(GL:nameFormat(player), playerName)) then
            return true;
        end
    end

    return false;
end

--- Mark a given player as "trusted"
---
---@param playerName string
---@return void
function PlusTwos:markPlayerAsTrusted(playerName)
    GL:debug("PlusTwos:markPlayerAsTrusted");

    if (GL:empty(playerName)
        or self:playerIsTrusted(playerName)
    ) then
        return;
    end

    local trustedPlayerCSV = GL.Settings:get("PlusTwos.automaticallyAcceptDataFrom", "");
    if (GL:empty(trustedPlayerCSV)) then
        GL.Settings:set("PlusTwos.automaticallyAcceptDataFrom", playerName);
        return
    end

    local TrustedPlayers = GL:strSplit(trustedPlayerCSV, ",");
    tinsert(TrustedPlayers, playerName);

    GL.Settings:set("PlusTwos.automaticallyAcceptDataFrom", table.concat(TrustedPlayers, ","));
end

--- Remove a player from the list of "trusted" players
---
---@param playerName string
---@return void
function PlusTwos:removePlayerFromTrusted(playerName)
    GL:debug("PlusTwos:removePlayerFromTrusted");

    -- No point removing the player if he's not trusted in the first place
    if (GL:empty(playerName)
        or not self:playerIsTrusted(playerName)
    ) then
        return;
    end

    local trustedPlayerCSV = GL.Settings:get("PlusTwos.automaticallyAcceptDataFrom", "");
    local TrustedPlayers = GL:strSplit(trustedPlayerCSV, ",");
    local NewTrustedPlayers = {};
    local normalizedName = GL:normalizedName(playerName);

    for _, trustedPlayer in pairs(TrustedPlayers) do
        if (GL:normalizedName(trustedPlayer) ~= normalizedName) then
            tinsert(NewTrustedPlayers, trustedPlayer);
        end
    end

    GL.Settings:set("PlusTwos.automaticallyAcceptDataFrom", table.concat(NewTrustedPlayers, ","));
end

--- Draw either the importer or overview
--- based on the current plus two data
---
---@return void
function PlusTwos:draw()
    GL:debug("PlusTwos:draw");

    -- Show the plus twos overview instead
    GL.Interface.PlusTwos.Overview:draw();
end

--- Checks and handles whisper commands if enabled.
---
---@param _ string
---@param message string
---@param sender string
---@return void
function PlusTwos:handleWhisperCommand(_, message, sender)
    GL:debug("PlusTwos:handleWhisperCommand");

    -- Only listen to the following messages
    if (not GL:strStartsWith(message, "!plustwo")
        and not GL:strStartsWith(message, "!PLUSTWO")
        and not GL:strStartsWith(message, "!po")
        and not GL:strStartsWith(message, "!PO")
        and not GL:strStartsWith(message, "!+2")
    ) then
        return;
    end

    local args = GL:strSplit(message, " ");

    -- See if name is given.
    if (args[2]) then
        local name = GL:nameFormat(args[2]);
        local plusTwo = self:getPlusTwos(name);
        GL:sendChatMessage(
            string.format("Player %s's +2 total is %d", GL:capitalize(name), plusTwo),
            "WHISPER", nil, sender
        );
        return;
    end

    local name = GL:nameFormat(sender);
    local plusTwo = self:getPlusTwos(name);
    GL:sendChatMessage(
        string.format("Your +2 total is %d", plusTwo),
        "WHISPER", nil, sender
    );
end

--- Materialize the plus two data to make it more accessible during runtime
---
---@return void
function PlusTwos:materializeData()
    GL:debug("PlusTwos:materializeData");

    local DetailsByPlayerName = {}; -- Details including aliases by player name

    --- Create entries from Totals data
    for name, plusTwo in pairs(DB:get("PlusTwos.Totals", {})) do
        name = GL:addRealm(name);
        plusTwo = self:toPlusTwo(plusTwo or 0);

        if (type(name) == "string"
            and not GL:empty(name)
            and not DetailsByPlayerName[name]
        ) then
            GL:tableSet(DetailsByPlayerName, name .. ".total", plusTwo);
        end
    end

    self.MaterializedData.DetailsByPlayerName = DetailsByPlayerName;
end

--- Format a plus two.
---
---@param plusTwo number
---@return number|nil
function PlusTwos:toPlusTwo(plusTwo)
    GL:debug("PlusTwos:toPlusTwo");

    plusTwo = tonumber(plusTwo);

    if (not plusTwo) then
        return nil;
    end

    plusTwo = math.max(0, math.floor(plusTwo));
    return plusTwo;
end;

--- Clear all plus two data
---
---@return void
function PlusTwos:clearPlusTwos()
    GL:debug("PlusTwos:clearPlusTwos");

    DB:set("PlusTwos", {
        Totals = {},
        MetaData = {},
    });

    self.MaterializedData = {
        DetailsByPlayerName = {},
    };
    
    if (GL.Settings:get("PlusTwos.automaticallyShareData")
        and self:userIsAllowedToBroadcast()
    ) then
        self:broadcast(); 
    end

    self:triggerChangeEvent();
end

--- Get a player's plus two
---
---@param name string
---@return number
function PlusTwos:getPlusTwos(name)
    GL:debug("PlusTwos:getPlusTwos");

    if (type(name) ~= "string") then
        return 0;
    end

    return GL:tableGet(
        self.MaterializedData or {},
        "DetailsByPlayerName." .. self:playerGUID(name) .. ".total", 0
    );
end

--- Set a player's plus two
---
---@param name string
---@param plusTwo number
---@param dontBroadcast boolean Important so that child receiving data from parent doesn't broadcast on
---@return void
function PlusTwos:setPlusTwos(name, plusTwo, dontBroadcast)
    GL:debug("PlusTwos:setPlusTwos");

    if (type(name) ~= "string") then
        return;
    end

    dontBroadcast = GL:toboolean(dontBroadcast);

    local playerGUID = self:playerGUID(name);
    if (not self.MaterializedData.DetailsByPlayerName[playerGUID]) then
        GL:tableSet(self.MaterializedData, "DetailsByPlayerName." .. playerGUID .. ".total", plusTwo);
    else
        self.MaterializedData.DetailsByPlayerName[playerGUID].total = plusTwo;
    end

    DB:set("PlusTwos.Totals." .. playerGUID, plusTwo);
    DB:set("PlusTwos.MetaData.updatedAt", GetServerTime());

    if (not dontBroadcast
        and GL.Settings:get("PlusTwos.automaticallyShareData")
    ) then
        self:broadcastUpdate(playerGUID, plusTwo);
    end

    self:triggerChangeEvent();
end

--- Import a CSV or TSV data string
---
---@param data string
---@param openOverview boolean (optional, default: false)
---@param MetaData table (optional, default: auto generate new metadata)
---@return boolean
function PlusTwos:import(data, openOverview, MetaData)
    GL:debug("PlusTwos:import");

    -- Make sure all the required properties are available and of the correct type
    if (type(data) ~= "string"
        or GL:empty(data)
    ) then
        GL.Interface:get("PlusTwos.Importer", "Label.StatusMessage"):SetText("Invalid plus two data provided");
        return false;
    end

    MetaData = MetaData or {};
    local Totals = {};

    -- If the user copy/pasted from google sheets there will be additional quotes that need to be removed
    data = data:gsub("\"", "");

    for line in data:gmatch("[^\n]+") do
        --- We expect lines to be in the form,
        --- where the individual variables are comma, tab, or spaces separated:
        --- PlayerName,Points
        --- This facilitates imports from CSV, TSV files or pasting from Google Docs
        local Segments = GL:separateValues(line);
        
        local playerName = tostring(Segments[1]);
        local plusTwo = self:toPlusTwo(Segments[2]);

        if (not GL:empty(playerName) and not Totals[playerName] and plusTwo) then
            Totals[self:playerGUID(playerName)] = plusTwo;
        end
    end

    if (GL:empty(Totals)) then
        local errorMessage = "Invalid data provided. Make sure that the contents follows the required format and no header row is included.";
        GL.Interface:get("PlusTwos.Importer", "Label.StatusMessage"):SetText(errorMessage);

        return false;
    end

    DB:set("PlusTwos", {
        Totals = Totals,
        MetaData = {
            importedAt = MetaData.importedAt or GetServerTime(),
            updatedAt = MetaData.updatedAt or GetServerTime(),
            uuid = MetaData.uuid or GL:uuid(),
        },
    });

    GL:success("Import of plus two data successful");
    GL.Events:fire("GL.PLUSTWOS_IMPORTED");

    self:materializeData();
    GL.Interface.PlusTwos.Importer:close();

    if (openOverview) then
        self:draw();

        -- The user is in charge of automatically sharing PlusTwos data
        -- after importing it, let's get crackin'!
        if (GL.Settings:get("PlusTwos.automaticallyShareData")
            and self:userIsAllowedToBroadcast()
        ) then
            self:broadcast();
        end
    end

    return true;
end

--- Export to CSV
---
---@param displayFrame boolean
---@return string
function PlusTwos:export(displayFrame)
    GL:debug("PlusTwos:export");
    
    -- Create CSV string
    local csv = "";
    for name, Entry in pairs(self.MaterializedData.DetailsByPlayerName) do
        csv = ("%s%s,%s"):format(csv, name, Entry.total);
        csv = csv.."\n";
    end

    if (displayFrame) then
        GL:frameMessage(csv);
    end

    return csv;
end

--- Broadcast our plus two data to the raid or group
---
---@return boolean
function PlusTwos:broadcast()
    GL:debug("PlusTwos:broadcast");

    if (self.broadcastInProgress) then
        GL:error("Broadcast still in progress");
        return false;
    end

    -- No need to broadcast anything when not in a group, this also doesn't warrent a warning
    if (not GL.User.isInGroup) then
        return false;
    end

    if (not self:userIsAllowedToBroadcast()) then
        GL:warning("Insufficient permissions to broadcast, need ML, assist or lead!");
        return false;
    end

    -- No need to keep any queued updates, we're doing a full broadcast now anyways
    self.QueuedUpdates = {};

    self.broadcastInProgress = true;
    GL.Events:fire("GL.PLUSTWOS_BROADCAST_STARTED");

    local Broadcast = function ()
        GL:message("Broadcasting PlusTwos data...");

        local Label = GL.Interface:get(GL.PlusTwos, "Label.BroadcastProgress");

        if (Label) then
            Label:SetText("Broadcasting...");
        end

        GL.CommMessage.new(
            CommActions.broadcastPlusTwosData,
            {
                importString = self:export(false),
                MetaData = DB:get("PlusTwos.MetaData", {}),
            },
            "GROUP"
        ):send(function ()
            GL:success("PlusTwos broadcast finished");

            self.broadcastInProgress = false;
            GL.Events:fire("GL.PLUSTWOS_BROADCAST_ENDED");

            Label = GL.Interface:get(GL.PlusTwos, "Label.BroadcastProgress");
            if (Label) then
                Label:SetText("Broadcast finished!");
            end
        end, function (sent, plusTwo)
            Label = GL.Interface:get(GL.PlusTwos, "Label.BroadcastProgress");
            if (Label) then
                Label:SetText(string.format("Sent %s of %s bytes", sent, plusTwo));
            end
        end);
    end

    -- We're about to send a lot of data which will put strain on CTL
    -- Make sure we're out of combat before doing so!
    if (UnitAffectingCombat("player")) then
        GL:message("You are currently in combat, delaying PlusTwos broadcast");

        GL.Events:register("PlusTwosOutOfCombatListener", "PLAYER_REGEN_ENABLED", function ()
            GL.Events:unregister("PlusTwosOutOfCombatListener");
            Broadcast();
        end);
    else
        Broadcast();
    end

    return true;
end

--- Process an incoming plus two broadcast
---
---@param CommMessage CommMessage
---@return void
function PlusTwos:receiveBroadcast(CommMessage)
    GL:debug("PlusTwos:receiveBroadcast");

    -- If shared data is blocked then return
    if (GL.Settings:get("PlusTwos.blockShareData")) then
        return;
    end

    -- No need to update our tables if we broadcasted them ourselves
    if (CommMessage.Sender.isSelf) then
        GL:debug("PlusTwos:receiveBroadcast received by self, skip");
        return;
    end

    local importString = CommMessage.content.importString or '';
    local MetaData = CommMessage.content.MetaData or {};
    local importBroadcast = (function ()
        if (GL:empty(importString)) then
            return self:clearPlusTwos();
        end

        GL:warning("Attempting to process incoming PlusTwos data from " .. CommMessage.Sender.name);

        local result = self:import(importString, false, MetaData);
        if (result) then
            self:triggerChangeEvent();
        end

        return;
    end);

    --- Check whether we can trust this sender (and as such immediately accept the incoming broadcast)
    if (self:playerIsTrusted(CommMessage.Sender.name)
        or self:playerIsTrusted(CommMessage.senderFqn)
    ) then
        importBroadcast();
        return;
    end

    --- Display different messages depending on whether it is an update of the same import or completely new data.
    local uuid = DB:get("PlusTwos.MetaData.uuid", '');
    local updatedAt = DB:get("PlusTwos.MetaData.updatedAt", 0);
    local question;
    
    if (GL:empty(importString)) then
        question = string.format(
            "%s wants to clear all your plus two data. Clear all plus two data?",
            CommMessage.Sender.name
        );
    elseif (MetaData.uuid and uuid == MetaData.uuid) then -- This is an update to our dataset
        question = string.format(
            "Are you sure you want to update your existing plus twos with data from |c00%s%s|r?\n\nYour latest update was on |c00a79eff%s|r, theirs on |c00a79eff%s|r.",
            GL:classHexColor(GL.Player:classByName(CommMessage.Sender.name)),
            CommMessage.Sender.name,
            date("%Y-%m-%d %H:%M", updatedAt),
            date("%Y-%m-%d %H:%M", MetaData.updatedAt or 0)
        );
    elseif (not GL:empty(uuid)) then -- This is a different dataset, not an update
        question = string.format(
            "Are you sure you want to clear your existing plus two data and import new data broadcasted by %s?",
            CommMessage.Sender.name
        );
    else
        question = string.format(
            "Are you sure you want to import new data broadcasted by %s?",
            CommMessage.Sender.name
        );
    end

    local Dialog = {
        question = question,
        OnYes = importBroadcast,
        sender = CommMessage.Sender.name,
    };

    GL.Interface.Dialogs.IncomingPlusTwoDataDialog:open(Dialog);
end

--- Request PlusTwos data from the person in charge (ML or Leader).
---
---@return void
function PlusTwos:requestData()
    GL:debug("PlusTwos:requestData");

    -- If shared data is blocked then no need to request so return
    if (GL.Settings:get("PlusTwos.blockShareData")) then
        return;
    end

    if (self.requestingData) then
        return;
    end

    self.requestingData = true;

    local playerToRequestFrom = (function()
        -- We are the ML, we need to import the data ourselves
        if (GL.User.isMasterLooter) then
            return;
        end

        local lootMethod, _, masterLooterRaidID = GetLootMethod();

        -- Master looting is not active and we are the leader, this means we should import it ourselves
        if (lootMethod ~= 'master'
            and GL.User.isLead
        ) then
            return;
        end

        -- Master looting is active, return the name of the master looter
        if (lootMethod == 'master') then
            return GetRaidRosterInfo(masterLooterRaidID);
        end

        -- Fetch the group leader
        local maximumNumberOfGroupMembers = _G.MEMBERS_PER_RAID_GROUP;
        if (GL.User.isInRaid) then
            maximumNumberOfGroupMembers = _G.MAX_RAID_MEMBERS;
        end

        for index = 1, maximumNumberOfGroupMembers do
            local name, rank = GetRaidRosterInfo(index);

            -- Rank 2 means leader
            if (name and rank == 2) then
                return name;
            end
        end
    end)();

    -- There's no one to request data from, return
    if (GL:empty(playerToRequestFrom)) then
        self.requestingData = false;
        return;
    end

    -- We send a data request to the person in charge
    -- He will compare the ID and importedAt timestamp on his end to see if we actually need his data
    GL.CommMessage.new(
        CommActions.requestPlusTwosData,
        DB:get('PlusTwos.MetaData', {}),
        "WHISPER",
        playerToRequestFrom
    ):send();

    self.requestingData = false;
end

--- Reply to a player's PlusTwos data request.
---
---@param CommMessage CommMessage
---@return void
function PlusTwos:replyToDataRequest(CommMessage)
    GL:debug("PlusTwos:replyToDataRequest");

    -- We're not in a group (anymore), no need to help this person out
    if (not GL.User.isInGroup) then
        return;
    end

    -- Nice try, but we don't allow auto-sharing
    if (not GL.Settings:get("PlusTwos.automaticallyShareData")) then
        return;
    end

    -- Nice try, but we're not allowed to share data
    if (not self:userIsAllowedToBroadcast()) then
        return;
    end

    local uuid = CommMessage.content.uuid or '';
    local lastUpdate = CommMessage.content.updatedAt or 0;
    -- Your data is up to date, leave me alone!
    if (not GL:empty(uuid)
        and uuid == DB:get('PlusTwos.MetaData.uuid', '')
        and lastUpdate >= DB:get('PlusTwos.MetaData.updatedAt', 0)
    ) then
        return;
    end

    -- Looks like you need my data, here it is!
    GL.CommMessage.new(
        CommActions.broadcastPlusTwosData,
        {
            importString = self:export(false),
            MetaData = DB:get("PlusTwos.MetaData", {}),
        },
        "WHISPER",
        CommMessage.Sender.name
    ):send();
end

--- Add points to a give user's balance
---
---@param playerName string
---@return void
function PlusTwos:addPlusTwos(playerName)
    GL:debug("PlusTwos:addPlusTwos")

    local currentPoints = self:getPlusTwos(playerName) or 0;
    self:queueUpdate(playerName, currentPoints + 1);
end

--- Subtract points from a given user's balance
---
---@param playerName string
---@return void
function PlusTwos:subtractPlusTwos(playerName)
    GL:debug("PlusTwos:subtractPlusTwos");

    local currentPoints = self:getPlusTwos(playerName) or 0;

    self:queueUpdate(playerName, max(currentPoints - 1, 0));
end

---@todo is delete parameter even needed since entries aren't deleted manually?
--- Queue an update until broadcast is finished
---
---@param playerName string
---@param plusTwo number
---@param delete boolean
---@return void
function PlusTwos:queueUpdate(playerName, plusTwo, delete)
    local dontBroadcast = true;

    if (plusTwo) then
        self:setPlusTwos(playerName, plusTwo, dontBroadcast);
    end

    if (delete) then
        self:deletePlusTwos(playerName, dontBroadcast);
    end

    local Update = {
        playerName = playerName,
        plusTwo = plusTwo or nil,
        delete = delete or false,
    };

    tinsert(self.QueuedUpdates, Update);

    -- Fire an event to let the application know that an update was queued
    GL.Events:fire("GL.PLUSTWOS_UPDATE_QUEUED");
end

--- Send out the queued updates
---
---@return void
function PlusTwos:broadcastQueuedUpdates()
    GL:debug("PlusTwos:broadcastQueuedUpdates");

    if (not GL.User.isInGroup) then
        return;
    end

    if (GL.Settings:get("PlusTwos.automaticallyShareData")
        and self:userIsAllowedToBroadcast()
    ) then
        GL:message("Broadcasting PlusTwos updates...");
        GL.CommMessage.new(
            CommActions.broadcastPlusTwosMutation,
            {
                importString = self:export(false),
                MetaData = DB:get("PlusTwos.MetaData", {}),
            },
            "GROUP"
        ):send(function ()
            GL:success("PlusTwos updates finished");
        end);
    end

    self.QueuedUpdates = {};
end

---@todo Is delete parameter even required since manual deletions are not done?
--- Process an outgoing plus two update
---
---@param playerName string
---@param plusTwo number
---@param delete boolean
---@return boolean
function PlusTwos:broadcastUpdate(playerName, plusTwo, delete)
    GL:debug("PlusTwos:broadcastUpdate");

    if (not GL.User.isInGroup) then
        GL:warning("No one to broadcast to, you're not in a group!");
        return false;
    end

    if (not self:userIsAllowedToBroadcast()) then
        GL:warning("Insufficient permissions to broadcast, need ML, assist or lead!");
        return false;
    end

    if (self.broadcastInProgress) then
        GL:error("Broadcast still in progress");
        self:queueUpdate(playerName, plusTwo, delete);
        return false;
    end

    GL:message("Broadcasting PlusTwos update...");

    GL.CommMessage.new(
        CommActions.broadcastPlusTwosMutation,
        {
            updates = {{
                playerName = playerName,
                plusTwo = plusTwo or nil,
                delete = delete or false,
            }},
            uuid = DB:get("PlusTwos.MetaData.uuid", ""),
        },
        "GROUP"
    ):send();

    return true;
end

--- Process an incoming plus two update
---
---@param CommMessage CommMessage
---@return void
function PlusTwos:receiveUpdate(CommMessage)
    GL:debug("PlusTwos:receiveUpdate");

    -- If shared data is blocked then no need to receive update so return
    if (GL.Settings:get("PlusTwos.blockShareData")) then
        return;
    end

    -- No need to update our tables if we broadcasted them ourselves
    if (CommMessage.Sender.name == GL.User.name) then
        GL:debug("PlusTwos:receiveUpdate received by self, skip");
        return;
    end

    local importString = CommMessage.content.importString or '';
    local MetaData = CommMessage.content.MetaData or {};
    local importUpdates = (function ()
        if (GL:empty(importString)) then
            return self:clearPlusTwos();
        end

        local result = self:import(importString, false, MetaData);
        if (result) then
            self:triggerChangeEvent();
        end

        return;
    end);

    --- Check whether we can trust this sender (and as such immediately accept the incoming broadcast)
    if (self:playerIsTrusted(CommMessage.Sender.name)
        or self:playerIsTrusted(CommMessage.senderFqn)
    ) then
        importUpdates();
        return;
    end

    --- Display different messages depending on whether it is an update of the same import or completely new data.
    local uuid = DB:get("PlusTwos.MetaData.uuid", '');
    local updatedAt = DB:get("PlusTwos.MetaData.updatedAt", 0);
    local question;

    if (GL:empty(importString)) then
        question = string.format(
            "%s wants to clear all your plus two data. Clear all plus two data?",
            CommMessage.Sender.name
        );
    elseif (MetaData.uuid and uuid == MetaData.uuid) then -- This is an update to our dataset
        question = string.format(
            "Are you sure you want to update your existing plus twos with data from |c00%s%s|r?\n\nYour latest update was on |c00a79eff%s|r, theirs on |c00a79eff%s|r.",
            GL:classHexColor(GL.Player:classByName(CommMessage.Sender.name)),
            CommMessage.Sender.name,
            date("%Y-%m-%d %H:%M", updatedAt),
            date("%Y-%m-%d %H:%M", MetaData.updatedAt or 0)
        );
    elseif (not GL:empty(uuid)) then -- This is a different dataset, not an update
        question = string.format(
            "Are you sure you want to clear your existing plus two data and import new data broadcasted by %s?",
            CommMessage.Sender.name
        );
    else
        question = string.format(
            "Are you sure you want to import new data broadcasted by %s?",
            CommMessage.Sender.name
        );
    end

    local Dialog = {
        question = question,
        OnYes = importUpdates,
        sender = CommMessage.Sender.name,
    };

    GL.Interface.Dialogs.IncomingPlusTwoDataDialog:open(Dialog);

end

--- Check whether the current user is allowed to broadcast PlusTwos data
---
---@return boolean
function PlusTwos:userIsAllowedToBroadcast()
    GL:debug("PlusTwos:userIsAllowedToBroadcast");

    return GL.User.isInGroup and (GL.User.isMasterLooter or GL.User.hasAssist);
end

--- Trigger the PLUSTWOS_CHANGED event
---
---@return void
function PlusTwos:triggerChangeEvent()
    GL:debug("PlusTwos:triggerChangeEvent");

    GL.Events:fire("GL.PLUSTWOS_CHANGED");
end

GL:debug("PlusTwos.lua");