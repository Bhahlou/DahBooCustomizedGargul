---@type GL
local _, GL = ...;

local Overview = GL.Interface.Settings.Overview; ---@type SettingsOverview

---@class RaidGroupsSettings
GL.Interface.Settings.RaidGroups = {
    description = "Vous pouvez ici importer les groupes de raid de TMB des joueurs de votre raid pour vous en servir comme nouveau critère de tri dans les rolls"
};
local RaidGroups = GL.Interface.Settings.RaidGroups; ---@type RaidGroupsSettings
local EditBoxes = {};

---@return void
function RaidGroups:draw(Parent)
    GL:debug("RaidGroupsSettings:draw");
    
    local useAsSortCriteriaCheckbox = {
        {
            label = "Utiliser les groupes de raid comme critère de priorité dans les rolls",
            description = "En cochant ceci, vous pouvez utilier les groupes de raid comme un critère supplémentaire de tri dans la priorité des rolls",
            setting = "TMBRaidGroups.useAsSortCriteria",
        },
    };
    

    -- Status message frame
    local StatusMessageFrame = GL.AceGUI:Create("SimpleGroup");
    StatusMessageFrame:SetLayout("FILL");
    StatusMessageFrame:SetWidth(570);
    StatusMessageFrame:SetHeight(56);
    

    local StatusMessageLabel = GL.AceGUI:Create("Label");
    StatusMessageLabel:SetFontObject(_G["GameFontNormal"]);
    StatusMessageLabel:SetFullWidth(true);
    StatusMessageLabel:SetColor(1, 0, 0)
    GL.Interface:setItem(self, "StatusMessage", StatusMessageLabel);
    
    local AceGUI = GL.AceGUI;
    
    for _, Entry in pairs(useAsSortCriteriaCheckbox) do
        local Checkbox = AceGUI:Create("CheckBox");
        Checkbox:SetValue(GL.Settings:get(Entry.setting));
        Checkbox:SetLabel(Entry.label);
        Checkbox:SetDescription(Entry.description);
        Checkbox:SetFullWidth(true);
        Checkbox.text:SetTextColor(1, .95686, .40784);
        Checkbox:SetCallback("OnValueChanged", function()
            GL.Settings:set(Entry.setting, Checkbox:GetValue());
            
            self:refreshPrioritySettings(Parent);

            if (type(Entry.callback) == "function") then
                Entry.callback(Checkbox);
            end
        end);
        GL.Interface:setItem(GL.Settings, Entry.setting, Checkbox);
        Parent:AddChild(Checkbox);
    end

    local ImportTMBRaidGroups = GL.AceGUI:Create("Button");
    ImportTMBRaidGroups:SetText("Import des groupes de raid");
    ImportTMBRaidGroups:SetCallback("OnClick", function()
        -- GL.Settings:close();
        GL.Commands:call("tmbRaidGroupImport");
    end);
    Parent:AddChild(ImportTMBRaidGroups);

    local SaveRaidGroupSorting = GL.AceGUI:Create("Button");
    SaveRaidGroupSorting:SetText("Sauvegarder tri par groupe de raid");
    SaveRaidGroupSorting:SetCallback("OnClick",function ()
        local RaidGroupSortingSetting = {};
        
        for i = 1, GL:count(EditBoxes) do
            local identifier = strtrim(EditBoxes[i].Identifier:GetText(),nil);
            local raidGroup = strtrim(EditBoxes[i].RaidGroup:GetText(),nil);
            local sortingPriority = tonumber(strtrim(EditBoxes[i].SortingPriority:GetText(),nil));

            -- Check all required fields are provided
            if (not identifier or not raidGroup or not sortingPriority) then
                StatusMessageLabel:SetText(string.format("Données manquantes pour l'identifiant '%s' et groupe de raid '%s'",identifier, raidGroup));
                return;
            end
            
            sortingPriority = math.floor(sortingPriority);

            -- Invalid sorting priority
            if sortingPriority < 1 then
                StatusMessageLabel:SetText(string.format("Données invalides pour l'identifiant '%s' et groupe de raid '%s'. La priorité doit être supérieure à 0", identifier, raidGroup));
                return;
            end
            
            RaidGroupSortingSetting[identifier..raidGroup] = {
                Identifier = identifier,
                RaidGroup = raidGroup,
                SortingPriority = sortingPriority,
            }
        end

        -- Store
        GL.Settings:set("RaidGroupSorting",RaidGroupSortingSetting);

        -- Clear errors
        StatusMessageLabel:SetText("");

        -- Show sucess
        GL:success("Sauvegarde réussie !")

        -- Redraw settings
        GL.Settings:close();
        GL.Settings:draw("RaidGroups");
        
    end);
    Parent:AddChild(SaveRaidGroupSorting);

    Parent:AddChild(StatusMessageFrame);
    StatusMessageFrame:AddChild(StatusMessageLabel);

    self:refreshPrioritySettings(Parent);
end

function RaidGroups:refreshPrioritySettings(Parent)

    local useAsSortCriteria = GL.Settings:get("TMBRaidGroups.useAsSortCriteria");
    local currentStatusMessage = GL.Interface:getItem(self,"Label.StatusMessage")
    local currentText = "";
    local rollBracketCounter = GL:count(GL.Settings:get("RollTracking.Brackets"));

    if (useAsSortCriteria) then
        if (GL:count(GL.DB:get("TMBRaidGroups.RaidGroups")) == 0) then
            -- No Raid group imported
            currentText = "Aucun groupe de raid n'a été importé";
            currentStatusMessage:SetText(currentText);
            return;
        end
        
        if ( rollBracketCounter== 0) then
            -- No roll bracket set up yet
            currentText = currentText .. "\n Aucune plage de roll n'a été paramétrée"
            currentStatusMessage:SetText(currentText);
            return;
        end ;

        local raidGroups = {};

        for player, raidGroup in pairs(GL.DB:get("TMBRaidGroups.RaidGroups")) do
            
            if raidGroups[raidGroup] == nil then
                raidGroups[raidGroup] = true;
            end
        end

        local lineToDraw = rollBracketCounter * GL:count(raidGroups);

        local j = 1;
        for raidGroup, _ in pairs(raidGroups) do

            for i = 1, rollBracketCounter do
                local RollTrackingSettings = GL.Settings:get("RollTracking.Brackets", {})[i] or {};
                local identifier = RollTrackingSettings[1] or "";
                local raidGroup = raidGroup;

                local settingKey = identifier .. raidGroup;
                local raidGroupSortingSetting = GL.Settings:get("RaidGroupSorting",{})[settingKey] or {};
                local priority = raidGroupSortingSetting.SortingPriority  or "";

                local Identifier = GL.AceGUI:Create("EditBox");
                Identifier:DisableButton(true);
                Identifier:SetDisabled(true);
                Identifier:SetHeight(20);
                Identifier:SetWidth(100);
                Identifier:SetText(identifier);
                Parent:AddChild(Identifier);
                
                local RaidGroup = GL.AceGUI:Create("EditBox");
                RaidGroup:DisableButton(true);
                RaidGroup:SetDisabled(true);
                RaidGroup:SetHeight(20);
                RaidGroup:SetWidth(100);
                RaidGroup:SetText(raidGroup);
                Parent:AddChild(RaidGroup);

                local SortingPriority = GL.AceGUI:Create("EditBox");
                SortingPriority:DisableButton(true);
                SortingPriority:SetHeight(20);
                SortingPriority:SetWidth(100);
                SortingPriority:SetText(priority);
                SortingPriority:SetMaxLetters(1);
                Parent:AddChild(SortingPriority);

                EditBoxes[j] = {
                    Identifier = Identifier,
                    RaidGroup = RaidGroup,
                    SortingPriority = SortingPriority,
                };

                if (j == 1) then
                    Identifier:SetLabel(string.format(
                        "|cff%sIdentifieur|r",
                        GL:classHexColor("rogue")
                    ));
        
                    RaidGroup:SetLabel(string.format(
                        "|cff%sGroupe de raid|r",
                        GL:classHexColor("rogue")
                    ));
                
                    SortingPriority:SetLabel(string.format(
                        "|cff%sPriorité (tri)|r",
                        GL:classHexColor("rogue")
                    ));
                end

                if (i < lineToDraw) then
                    local HorizontalSpacer = GL.AceGUI:Create("SimpleGroup");
                    HorizontalSpacer:SetLayout("FILL");
                    HorizontalSpacer:SetFullWidth(true);
                    HorizontalSpacer:SetHeight(10);
                    Parent:AddChild(HorizontalSpacer);
                end
                j = j + 1;
            end
        end
    else
        currentStatusMessage:SetText("");
    end
end