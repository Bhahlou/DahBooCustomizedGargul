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

    

    print("bla")
    GL:success("Import des groupes de raid de TMB réussi");
    GL.Events:fire("GL.TMBRAIDGROUPS_IMPORTED");

    GL.Interface.TMBRaidGroups.Importer:close();

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