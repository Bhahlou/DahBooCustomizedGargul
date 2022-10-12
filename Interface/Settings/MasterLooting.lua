---@type GL
local _, GL = ...;

local Overview = GL.Interface.Settings.Overview; ---@type SettingsOverview

---@class MasterLootingSettings
GL.Interface.Settings.MasterLooting = {
    description = "",
};
local MasterLooting = GL.Interface.Settings.MasterLooting; ---@type MasterLootingSettings

---@return void
function MasterLooting:draw(Parent)
    GL:debug("MasterLootingSettings:draw");

    -- SetLootMethod('Master','Character Name','1')

    -- Give classic era users an easy way to change the master looting threshold
    if (GL.isEra) then
        local LootThresholdLabel = GL.AceGUI:Create("Label");
        LootThresholdLabel:SetText("Master Loot quality Threshold");
        LootThresholdLabel:SetColor(1, .95686, .40784);
        LootThresholdLabel:SetHeight(20);
        LootThresholdLabel:SetFullWidth(true);
        Parent:AddChild(LootThresholdLabel);

        local DropdownItems = {
            [0] = "0 - Poor",
            [1] = "1 - Common",
            [2] = "2 - Uncommon",
            [3] = "3 - Rare",
            [4] = "4 - Epic",
            [5] = "5 - Legendary",
        };

        local LootThreshold = GL.AceGUI:Create("Dropdown");
        LootThreshold:SetValue(GL.Settings:get("MasterLooting.preferredMasterLootingThreshold", 2));
        LootThreshold:SetList(DropdownItems);
        LootThreshold:SetText(DropdownItems[GL.Settings:get("MasterLooting.preferredMasterLootingThreshold", 2)]);
        LootThreshold:SetWidth(150);
        LootThreshold:SetCallback("OnValueChanged", function()
            GL.Settings:set("MasterLooting.preferredMasterLootingThreshold", LootThreshold:GetValue());
        end);
        Parent:AddChild(LootThreshold);

        local VerticalSpacer = GL.AceGUI:Create("SimpleGroup");
        VerticalSpacer:SetLayout("FILL");
        VerticalSpacer:SetWidth(10);
        VerticalSpacer:SetHeight(10);
        Parent:AddChild(VerticalSpacer);

        local ApplyLootThreshold = GL.AceGUI:Create("Button");
        ApplyLootThreshold:SetText("Apply");
        ApplyLootThreshold:SetWidth("80");
        ApplyLootThreshold:SetCallback("OnClick", function()
            local threshold = LootThreshold:GetValue();
            SetLootMethod('Master', GL.User.name, tostring(threshold));
        end);
        Parent:AddChild(ApplyLootThreshold);

        local HorizontalSpacer = GL.AceGUI:Create("SimpleGroup");
        HorizontalSpacer:SetLayout("FILL");
        HorizontalSpacer:SetFullWidth(true);
        HorizontalSpacer:SetHeight(10);
        Parent:AddChild(HorizontalSpacer);
    end

    local Checkboxes = {
        {
            label = "Afficher le pop-up de master loot",
            description = "Active la fenêtre du responsable de butin qui apparaît automatiquement lorsque le rôle de responsable du butin vous est attribué. Elle vous fournit un accès  facile pour effacer et importer les données depuis Thatsmybis",
            setting = "MasterLooting.autoOpenMasterLooterDialog",
        },
        {
            label = "Annoncer le responsable du butin",
            description = "Poste automatiquement un message dans le chat lorsque le rôle de responsable du butin vous est attribué",
            setting = "MasterLooting.announceMasterLooter",
        },
        {
            label = "Annoncer le début des rolls",
            description = "Poste une annonce en /ar quand un roll commence",
            setting = "MasterLooting.announceRollStart",
        },
        {
            label = "Compte à rebours sur les rolls",
            description = "Un compte à rebours sera affiché dans le chat quand un roll arrive à sa fin (par ex : vous avez 5s pour roll)",
            setting = "MasterLooting.doCountdown",
        },
    };

    Overview:drawCheckboxes(Checkboxes, Parent);

    local HorizontalSpacer = GL.AceGUI:Create("SimpleGroup");
    HorizontalSpacer:SetLayout("FILL");
    HorizontalSpacer:SetFullWidth(true);
    HorizontalSpacer:SetHeight(20);
    Parent:AddChild(HorizontalSpacer);

    local NumberOfSecondsToCountdown = GL.AceGUI:Create("Slider");
    NumberOfSecondsToCountdown:SetLabel("A combien de secondes restantes voulez-vous que le compte à rebours commence ?");
    NumberOfSecondsToCountdown.label:SetTextColor(1, .95686, .40784);
    NumberOfSecondsToCountdown:SetFullWidth(true);
    NumberOfSecondsToCountdown:SetValue(GL.Settings:get("MasterLooting.numberOfSecondsToCountdown", 5));
    NumberOfSecondsToCountdown:SetSliderValues(3, 25, 1);
    NumberOfSecondsToCountdown:SetCallback("OnValueChanged", function(Slider)
        local value = math.floor(tonumber(Slider:GetValue()));

        if (value >= 3) then
            GL.Settings:set("MasterLooting.numberOfSecondsToCountdown", value);
        end
    end);
    Parent:AddChild(NumberOfSecondsToCountdown);

    HorizontalSpacer = GL.AceGUI:Create("SimpleGroup");
    HorizontalSpacer:SetLayout("FILL");
    HorizontalSpacer:SetFullWidth(true);
    HorizontalSpacer:SetHeight(20);
    Parent:AddChild(HorizontalSpacer);

    Overview:drawCheckboxes({
        {
            label = "Annoncer la fin des rolls",
            description = "Quand activé, vous posterez une annonce en /ar lorsque le roll est terminé",
            setting = "MasterLooting.announceRollEnd",
        },
    }, Parent);

    HorizontalSpacer = GL.AceGUI:Create("SimpleGroup");
    HorizontalSpacer:SetLayout("FILL");
    HorizontalSpacer:SetFullWidth(true);
    HorizontalSpacer:SetHeight(15);
    Parent:AddChild(HorizontalSpacer);

    local DefaultRollOffNote = GL.AceGUI:Create("EditBox");
    DefaultRollOffNote:DisableButton(true);
    DefaultRollOffNote:SetHeight(20);
    DefaultRollOffNote:SetFullWidth(true);
    DefaultRollOffNote:SetText(GL.Settings:get("MasterLooting.defaultRollOffNote", "/roll 100 pour +1, /roll 90 pour +2, /roll 80 pour +3"));
    DefaultRollOffNote:SetLabel(string.format(
            "|cff%sDéfinissez une note par défaut qui est affichée lors du roll d'un item. Le caractère ( | ) n'est pas autorisé!|r",
            GL:classHexColor("rogue")
    ));
    DefaultRollOffNote:SetCallback("OnTextChanged", function (self)
        local value = self:GetText();

        if (type(value) ~= "string"
            or GL:strContains(value, "|")
        ) then
            GL:warning("Invalid note provided");
            GL.Settings:set("MasterLooting.defaultRollOffNote", "/roll 100 pour +1, /roll 90 pour +2, /roll 80 pour +3")
        end

        GL.Settings:set("MasterLooting.defaultRollOffNote", value);
    end);
    Parent:AddChild(DefaultRollOffNote);

    Checkboxes = {
        {
            label = "Toujours afficher la note par défaut à la place de la priorité de l'item",
            description = "Dah Boo Customized Gargul utilise les priorités d'item (si disponible) lors du roll d'items. Activer ceci signifie que vous pouvez utiliser votre note personnalisée par défaut à la place",
            setting = "MasterLooting.alwaysUseDefaultNote",
            callback = function ()
                GL.MasterLooterUI:updateItemNote();
            end
        },
    };

    Overview:drawCheckboxes(Checkboxes, Parent);
end

GL:debug("Interface/Settings/MasterLooting.lua");