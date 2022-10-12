---@type GL
local _, GL = ...;

local Overview = GL.Interface.Settings.Overview; ---@type SettingsOverview

---@class RollTrackingSettings
GL.Interface.Settings.RollTracking = {
    description = "Après avoir annoncé un objet et un roll aux joueurs, Dah Boo Customized Gargul gardera le suivi des rolls entrants. Par défaut, Dah Boo Customized Gargul ne garde que les rolls +1, +2, +3. Les champs ci-dessous vous permettent de customiser cela selon vos préférences, jusqu'à 6 'plages' de roll. L'identifieur est le texte affiché sur le bouton (maximum 3 caractères) et la 'Priorité' détermine comment les rolls seront triés dans la table de suivi (la priorité 1 est la plus haute). 2 ou davantage de plages de rolls peuvent partager la même priorité, ce ne sont pas des valeurs uniques. |cffC41E3AAttention à cliquer sur le bouton 'Sauvegarder plages de roll' lorsque vous avez terminé !|r"
};
local RollTracking = GL.Interface.Settings.RollTracking; ---@type RollTrackingSettings

---@return void
function RollTracking:draw(Parent)
    GL:debug("RollTrackingSettings:draw");

    local EditBoxes = {};
    local Checkboxes = {
        {
            label = "Suivre tous les rolls",
            description = "Par défaut, Dah Boo Customized Gargul ne suit que les rolls qui suivent les règles définies ci-dessous. Si vous voulez suivre tous les rolls, alors activez cette option. La plage dans la quelle le joueur a roll sera affichée dans la fenêtre de suivi des rolls",
            setting = "RollTracking.trackAll",
        },
    };

    Overview:drawCheckboxes(Checkboxes, Parent);

    local HorizontalSpacer = GL.AceGUI:Create("SimpleGroup");
    HorizontalSpacer:SetLayout("FILL");
    HorizontalSpacer:SetFullWidth(true);
    HorizontalSpacer:SetHeight(15);
    Parent:AddChild(HorizontalSpacer);

    local StatusMessageLabel = nil;
    local SaveRollRanges = GL.AceGUI:Create("Button");
    SaveRollRanges:SetText("Sauvegarder plages de roll");
    SaveRollRanges:SetCallback("OnClick", function()
        local TempNewRollSettings = GL.Settings:get("RollTracking.Brackets");

        for i = 1, 6 do
            local identifier = strtrim(EditBoxes[i].Identifier:GetText());
            local min = tonumber(strtrim(EditBoxes[i].Min:GetText()));
            local max = tonumber(strtrim(EditBoxes[i].Max:GetText()));
            local priority = tonumber(strtrim(EditBoxes[i].SortingPriority:GetText()));

            if (not GL:empty(identifier)) then
                --- Not all the necessary data is provided
                if (not min
                    or not max
                    or not priority
                ) then
                    StatusMessageLabel:SetText(string.format("Missing data for identifier '%s'", identifier));
                    return;
                end

                min = math.floor(min);
                max = math.floor(max);
                priority = math.floor(priority);

                --- The user provided invalid data (letters instead of numbers or invalid numerical values)
                if (min < 1
                    or max < min
                    or priority < 1
                ) then
                    StatusMessageLabel:SetText(string.format("Invalid data for identifier '%s'. Min must be greater than 0, max must be higher than min and priority must be greater than 0", identifier));
                    return;
                end

                -- The identifier can hold a maximum of 3 characters
                identifier = string.sub(identifier, 1, 3);

                TempNewRollSettings[i] = { identifier, min, max, priority};
            else
                TempNewRollSettings[i] = nil;
            end
        end

        -- We rebuild the table to make sure it's unassociative again
        local NewRollSettings = {};
        for _, NewSettings in pairs(TempNewRollSettings) do
            tinsert(NewRollSettings, NewSettings);
        end

        -- Store the roll range settings
        GL.Settings:set("RollTracking.Brackets", NewRollSettings);

        -- Remove error messages (if any), since all data is valid
        StatusMessageLabel:SetText("");

        -- Show a simple sucess message in the chat
        GL:success("Success!");

        -- Redraw the settings overview to make sure it reflects these changes
        GL.Settings:close();
        GL.Settings:draw("RollTracking");
    end);
    Parent:AddChild(SaveRollRanges);

    HorizontalSpacer = GL.AceGUI:Create("SimpleGroup");
    HorizontalSpacer:SetLayout("FILL");
    HorizontalSpacer:SetFullWidth(true);
    HorizontalSpacer:SetHeight(6);
    Parent:AddChild(HorizontalSpacer);

    -- Status message frame
    local StatusMessageFrame = GL.AceGUI:Create("SimpleGroup");
    StatusMessageFrame:SetLayout("FILL");
    StatusMessageFrame:SetWidth(500);
    StatusMessageFrame:SetHeight(10);
    Parent:AddChild(StatusMessageFrame);

    HorizontalSpacer = GL.AceGUI:Create("SimpleGroup");
    HorizontalSpacer:SetLayout("FILL");
    HorizontalSpacer:SetFullWidth(true);
    HorizontalSpacer:SetHeight(12);
    Parent:AddChild(HorizontalSpacer);

    StatusMessageLabel = GL.AceGUI:Create("Label");
    StatusMessageLabel:SetFontObject(_G["GameFontNormal"]);
    StatusMessageLabel:SetFullWidth(true);
    StatusMessageLabel:SetColor(1, 0, 0);
    StatusMessageFrame:AddChild(StatusMessageLabel);

    for i = 1, 6 do
        local RollTrackingSettings = GL.Settings:get("RollTracking.Brackets", {})[i] or {};

        local identifier = RollTrackingSettings[1] or "";
        local min = RollTrackingSettings[2] or "";
        local max = RollTrackingSettings[3] or "";
        local priority = RollTrackingSettings[4] or "";

        local Identifier = GL.AceGUI:Create("EditBox");
        Identifier:DisableButton(true);
        Identifier:SetHeight(20);
        Identifier:SetWidth(100);
        Identifier:SetText(identifier);
        Identifier:SetMaxLetters(3);
        Parent:AddChild(Identifier);

        local Min = GL.AceGUI:Create("EditBox");
        Min:DisableButton(true);
        Min:SetHeight(20);
        Min:SetWidth(100);
        Min:SetText(min);
        Parent:AddChild(Min);

        local Max = GL.AceGUI:Create("EditBox");
        Max:DisableButton(true);
        Max:SetHeight(20);
        Max:SetWidth(100);
        Max:SetText(max);
        Parent:AddChild(Max);
        
        local SortingPriority = GL.AceGUI:Create("EditBox");
        SortingPriority:DisableButton(true);
        SortingPriority:SetHeight(20);
        SortingPriority:SetWidth(100);
        SortingPriority:SetText(priority);
        SortingPriority:SetMaxLetters(1);
        Parent:AddChild(SortingPriority);

        EditBoxes[i] = {
            Identifier = Identifier,
            Min = Min,
            Max = Max,
            SortingPriority = SortingPriority,
        };

        if (i == 1) then
            Identifier:SetLabel(string.format(
                "|cff%sIdentifiant|r",
                GL:classHexColor("rogue")
            ));

            Min:SetLabel(string.format(
                "|cff%sRoll minimum|r",
                GL:classHexColor("rogue")
            ));

            Max:SetLabel(string.format(
                "|cff%sRoll maximum|r",
                GL:classHexColor("rogue")
            ));

            SortingPriority:SetLabel(string.format(
                "|cff%sPriorité (tri)|r",
                GL:classHexColor("rogue")
            ));
        end

        if (i < 6) then
            HorizontalSpacer = GL.AceGUI:Create("SimpleGroup");
            HorizontalSpacer:SetLayout("FILL");
            HorizontalSpacer:SetFullWidth(true);
            HorizontalSpacer:SetHeight(10);
            Parent:AddChild(HorizontalSpacer);
        end
    end
end

GL:debug("Interface/Settings/RollTracking.lua");