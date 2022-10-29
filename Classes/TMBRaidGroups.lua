---@type GL
local _, GL = ...;

GL.AceGUI = GL.AceGUI or LibStub("AceGUI-3.0");

---@class TMBRaidGroups
GL.TMBRaidGroups = {
    _initialized = false,
    broadcastInProgress = false,
    requestingData = false,
};
local TMBRaidGroups = GL.TMBRaidGroups; ---@type TMBRaidGroups
local DB = GL.DB; ---@type DB

local Constants = GL.Data.Constants; ---@type Data
local CommActions = Constants.Comm.Actions;
local Settings = GL.Settings; ---@type Settings


---@return boolean
function TMBRaidGroups:_init()
    GL:debug("TMBRaidGroups:_init");

    if (self._initialized) then
        return false;
    end

    GL.Events:register("TMBRaidGroupsUserJoinedGroupListener", "GL.USER_JOINED_GROUP", function () self:requestData(); end);

    self._initialized = true;
    return true;
end

--- Draw either the importer or overview
--- based on the current TMB data
---
---@return void
function TMBRaidGroups:draw()
    GL:debug("TMBRaidGroups:draw");

    -- No data available, show importer
    if (not self:available()) then
        GL.Interface.TMBRaidGroups.Importer:draw();
        return;
    end

    GL.Interface.TMBRaidGroups.Overview:draw();

end

function TMBRaidGroups:import(TMBBoxContent)
    GL:debug("RaidGroupsImporter:import");

    -- Make sure all the required properties are available and of the correct type    -- Make sure all the required properties are available and of the correct type
    if (GL:empty(TMBBoxContent)) then
        GL.Interface:getItem("TMBRaidGroups.Importer", "Label.StatusMessage"):SetText("Les données de groupe de raid fournies sont invalides");
        return false;
    end
    
    -- If the user copy/pasted from google sheets there will be addition quotes that need to be removed
    TMBBoxContent = TMBBoxContent:gsub("\"", "");
    local raidGroups = {};

    for line in TMBBoxContent:gmatch("[^\n]+") do
        --- We expect lines to be in the form,
        --- where the individual variables are comma, tab, or spaces separated:
        --- PlayerName,Points,Alias1,Alias2...
        --- e.g., "Foobar,240,Barfoo"
        --- This facilitates imports from CSV, TSV files or pasting from Google Docs
        local Segments = GL:separateValues(line);
       
        local playerName = tostring(Segments[3]);
        playerName = GL:normalizedName(playerName);

        if not (GL:empty(playerName)) then
            if not (playerName == "character_name") then
                raidGroups[playerName] = tostring(Segments[1]);    
            end
        end

    end
    local MetaData = {};


    GL.DB.TMBRaidGroups = {
        RaidGroups = raidGroups,
        MetaData = {
            importedAt = GetServerTime(),
            updatedAt = GetServerTime(),
            uuid = GL:uuid(),
        },
    };
    
    if (GL:empty(raidGroups)) then
        local errorMessage = "Les données fournies sont invalides.";
        GL.Interface:getItem("TMBRaidGroups.Importer", "Label.StatusMessage"):SetText(errorMessage);

        return false;
    end

    -- The user is in charge of automatically sharing TMB raid groups data
    -- after importing it, let's get crackin'!
    if (GL.Settings:get("TMBRaidGroups.broadcastRaidGroups")
        and (GL.User.isMasterLooter
            or (GetLootMethod() ~= 'master'
                and GL.User.isLead
            )
        )
    ) then
        self:broadcast();
    end
    
    GL:success("Import des groupes de raid de TMB réussi");
    GL.Events:fire("GL.TMBRAIDGROUPS_IMPORTED");

    GL.Interface.TMBRaidGroups.Importer:close();

end

--- Broadcast the TMB raid groups to the RAID / PARTY
---@return boolean
function TMBRaidGroups:broadcast()
    GL:debug("TMBRaidGroups:broadcast");

    if (self.broadcastInProgress) then
        GL:error("Le partage des groupes de raid est encore en cours");
        return false;
    end

    if (not GL.User.isInGroup) then
        GL:warning("Personne à qui partager les groupes de raid, vous n'êtes pas dans un groupe !");
        return false;
    end

    if (not GL.User.hasAssist
        and not GL.User.isMasterLooter
    ) then
        GL:warning("Permission insuffisante pour partager les groupes de raid, vous devez être ML, avoir une promote ou le lead !");
        return false;
    end

    -- Check if there's anything to share
    if (not self:available()) then
        GL:warning("Rien à partager, importez les groupes de raid TMB d'abord !");
        return false;
    end

    self.broadcastInProgress = true;
    GL.Events:fire("GL.TMBRAIDGROUPS_BROADCAST_STARTED");

    local Broadcast = function ()
        GL:message("Partage des données de groupe de raid TMB...");

        GL.CommMessage.new(
            CommActions.broadcastTMBRaidGroupsData,
            GL.DB.TMBRaidGroups,
            "GROUP"
        ):send(function ()
            GL:success("Partage des groupes de raid terminé");
            self.broadcastInProgress = false;
            GL.Events:fire("GL.TMBRAIDGROUPS_BROADCAST_ENDED");
        end);
    end

    -- We're about to send a lot of data which will put strain on CTL
    -- Make sure we're out of combat before doing so!
    if (UnitAffectingCombat("player")) then
        GL:message("Vous êtes actuellement en combat, report du partage des groupes de raid");

        GL.Events:register("TMBOutOfCombatListener", "PLAYER_REGEN_ENABLED", function ()
            GL.Events:unregister("TMBOutOfCombatListener");
            Broadcast();
        end);
    else
        Broadcast();
    end

    return true;
end

--- Process an incoming TMB raid groups broadcast
---
---@param CommMessage CommMessage
function TMBRaidGroups:receiveBroadcast(CommMessage)
    GL:debug("TMBRaidGroups:receiveBroadcast");

    -- No need to update our tables if we broadcasted them ourselves
    if (CommMessage.Sender.id == GL.User.id) then
        GL:debug("TMBRaidGroups:receiveBroadcast received by self, skip");
        return true;
    end

    local Data = CommMessage.content;
    if (not GL:empty(Data)) then
        GL:warning("Tentative de traitement de données de groupes de raid TMB entrantes de " .. CommMessage.Sender.name);

        if (type(Data) ~= "table" or GL:empty(Data)
            or type(Data.RaidGroups) ~= "table" or GL:empty(Data.RaidGroups)
            or GL:empty(GL:tableGet(Data, "MetaData.importedAt"))
        ) then
            GL:error("Données de groupes de raid TMB invalides reçues de " .. CommMessage.Sender.name);
            return;
        end

        -- Validate dataset
        for raidGroup, Entries in pairs(Data.RaidGroups) do

            if (GL:empty(raidGroup)) then
                GL:error("Données de groupes de raid TMB invalides reçues de " .. CommMessage.Sender.name);
                return;
            end
        end

        GL:success("Données de groupes de raids TMB synchronisées !");
        GL.DB.TMBRaidGroups = Data;
    end
end

--- Check whether there is TMBRaidGroups data available
---
---@return boolean
function TMBRaidGroups:available()
    return GL:higherThanZero(GL.DB:get("TMBRaidGroups.MetaData.importedAt", 0));
end

--- Clear all TMB data
---
---@return void
function TMBRaidGroups:clear()
    GL.DB.TMBRaidGroups = {};

    GL.Events:fire("GL.TMBRAIDGROUPS_CLEARED");
end

--- Request TMB raid groups data from the person in charge (ML or Leader)
---
---@return void
function TMBRaidGroups:requestData()
    GL:debug("TMBRaidGroups:requestData");

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
        CommActions.requestTMBRaidGroupsData,
        {
            currentHash = GL.DB:get('TMBRaidGroups.MetaData.hash', nil),
        },
        "WHISPER",
        playerToRequestFrom
    ):send();

    self.requestingData = false;
end

--- Reply to a player's TMB raid groups data request
---
---@param CommMessage CommMessage
---@return void
function TMBRaidGroups:replyToDataRequest(CommMessage)
    GL:debug("TMBRaidGroups:replyToDataRequest");

    -- I don't have any data, leave me alone!
    if (not self:available()) then
        return;
    end

    -- We're not in a group (anymore), no need to help this person out
    if (not GL.User.isInGroup) then
        return;
    end

    -- Nice try, but we don't allow auto-sharing
    if (not Settings:get("TMBRaidGroups.broadcastRaidGroups")) then
        return;
    end

    -- Nice try, but we're not allowed to share data
    if (not self:userIsAllowedToBroadcast()) then
        return;
    end

    -- The player is not in the same guild, this is something we won't support in data requests
    if (not GL.User:playerIsGuildMember(CommMessage.senderFqn)) then
        return;
    end

    local playerTMBHash = CommMessage.content.currentHash or '';
    -- Your data is the same as mine, leave me alone!
    if (not GL:empty(playerTMBHash)
        and playerTMBHash == GL.DB:get('TMBRaidGroups.MetaData.hash')
    ) then
        return;
    end

    -- Looks like you need my data, here it is!
    GL.CommMessage.new(
        CommActions.broadcastTMBRaidGroupsData,
        GL.DB.TMBRaidGroups,
        "WHISPER",
        CommMessage.Sender.name
    ):send();

end

--- Check whether the current user is allowed to broadcast TMB data
---
---@return boolean
function TMBRaidGroups:userIsAllowedToBroadcast()
    return GL.User.isInGroup and (GL.User.isMasterLooter or GL.User.hasAssist);
end