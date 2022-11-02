---@type GL
local _, GL = ...;

local Overview = GL.Interface.Settings.Overview; ---@type SettingsOverview

---@class ShortcutKeysSettings
GL.Interface.Settings.ShortcutKeys = {
    description = "Par défaut, Dah Boo Customized Gargul offre 3 raccourcis que vous pouvez utiliser en cliquant sur les objets dans votre sac ou la  fenêtre de butin d'un ennemi : alt+clic pour démarrer le roll sur un objet, alt+shift+clic pour attribuer un objet ou shift+clic pour désenchanter un objet (fonctionne uniquement dans la fenêtre de butin). Vous pouvez éditer ou complètement désactiver ces raccourcis ici, faites attention à ne pas sélectionner le même raccourci 2 fois pour éviter les comportements idiots !",
};
local ShortcutKeys = GL.Interface.Settings.ShortcutKeys; ---@type ShortcutKeysSettings

---@return void
function ShortcutKeys:draw(Parent)
    GL:debug("ShortcutKeys:draw");

    local HorizontalSpacer;
    local AceGUI = GL.AceGUI;
    local DropDownItems = {
        DISABLED = "Désactiver",
        SHIFT_CLICK = "Shift + Clic",
        ALT_CLICK = "Alt + Clic",
        ALT_SHIFT_CLICK = "Alt + Shift + Clic",
        ALT_RIGHTCLICK = "Alt + Right Clic",
        ALT_SHIFT_RIGHTCLICK = "Alt + Shift + Clic droit",
        CTRL_CLICK = "Ctrl + Clic",
        CTRL_SHIFT_CLICK = "Ctrl + Shift + Clic",
    };
    local ItemOrder = {
        "DISABLED",
        "SHIFT_CLICK",
        "ALT_CLICK",
        "ALT_SHIFT_CLICK",
        "CTRL_CLICK",
        "CTRL_SHIFT_CLICK",
        "CTRL_ALT_CLICK",
        "CTRL_ALT_SHIFT_CLICK",
    }

    local Checkboxes = {
        {
            label = "Afficher rappel raccourcis",
            description = "Affiche un rappel en lootant un ennemi pour afficher vos raccourcis actuels pour roll, attribuer ou désenchanter un objet",
            setting = "ShortcutKeys.showLegend",
        },
        {
            label = "Seulement en groupe",
            description = "Les raccourcis devraient fonctionner seulement lorsque je suis en groupe",
            setting = "ShortcutKeys.onlyInGroup",
        },
    }

    Overview:drawCheckboxes(Checkboxes, Parent);

    HorizontalSpacer = AceGUI:Create("SimpleGroup");
    HorizontalSpacer:SetLayout("FILL");
    HorizontalSpacer:SetFullWidth(true);
    HorizontalSpacer:SetHeight(10);
    Parent:AddChild(HorizontalSpacer);

    local RollOffLabel = AceGUI:Create("Label");
    RollOffLabel:SetText("Définit le raccourcir pour ouvrir la fenêtre du maître du butin, où vous pouvez démarrer un roll (par défaut alt+clic)");
    RollOffLabel:SetColor(1, .95686, .40784);
    RollOffLabel:SetHeight(20);
    RollOffLabel:SetFullWidth(true);
    Parent:AddChild(RollOffLabel);

    local RollOffHotkey = AceGUI:Create("Dropdown");
    RollOffHotkey:SetValue(GL.Settings:get("ShortcutKeys.rollOff"));
    RollOffHotkey:SetList(DropDownItems, ItemOrder);
    RollOffHotkey:SetText(DropDownItems[GL.Settings:get("ShortcutKeys.rollOff")]);
    RollOffHotkey:SetWidth(250);
    RollOffHotkey:SetCallback("OnValueChanged", function()
        GL.Settings:set("ShortcutKeys.rollOff", RollOffHotkey:GetValue());
    end);
    Parent:AddChild(RollOffHotkey);

    HorizontalSpacer = AceGUI:Create("SimpleGroup");
    HorizontalSpacer:SetLayout("FILL");
    HorizontalSpacer:SetFullWidth(true);
    HorizontalSpacer:SetHeight(20);
    Parent:AddChild(HorizontalSpacer);

    local AwardLabel = AceGUI:Create("Label");
    AwardLabel:SetText("Définit le raccourci pour ouvrir la fenêtre d'attribution d'objet (par défaut alt+shift+clic)");
    AwardLabel:SetColor(1, .95686, .40784);
    AwardLabel:SetHeight(20);
    AwardLabel:SetFullWidth(true);
    Parent:AddChild(AwardLabel);

    local AwardHotkey = AceGUI:Create("Dropdown");
    AwardHotkey:SetValue(GL.Settings:get("ShortcutKeys.award"));
    AwardHotkey:SetList(DropDownItems, ItemOrder);
    AwardHotkey:SetText(DropDownItems[GL.Settings:get("ShortcutKeys.award")]);
    AwardHotkey:SetWidth(250);
    AwardHotkey:SetCallback("OnValueChanged", function()
        GL.Settings:set("ShortcutKeys.award", AwardHotkey:GetValue());
    end);
    Parent:AddChild(AwardHotkey);

    HorizontalSpacer = AceGUI:Create("SimpleGroup");
    HorizontalSpacer:SetLayout("FILL");
    HorizontalSpacer:SetFullWidth(true);
    HorizontalSpacer:SetHeight(20);
    Parent:AddChild(HorizontalSpacer);

    local DisenchantLabel = AceGUI:Create("Label");
    DisenchantLabel:SetText("Définit le raccourci pour désenchanter un objet depuis la fenêtre du butin d'un ennemi (par défaut ctrl+shift+clic)");
    DisenchantLabel:SetColor(1, .95686, .40784);
    DisenchantLabel:SetHeight(20);
    DisenchantLabel:SetFullWidth(true);
    Parent:AddChild(DisenchantLabel);

    local DisenchantHotkey = AceGUI:Create("Dropdown");
    DisenchantHotkey:SetValue(GL.Settings:get("ShortcutKeys.disenchant"));
    DisenchantHotkey:SetList(DropDownItems, ItemOrder);
    DisenchantHotkey:SetText(DropDownItems[GL.Settings:get("ShortcutKeys.disenchant")]);
    DisenchantHotkey:SetWidth(250);
    DisenchantHotkey:SetCallback("OnValueChanged", function()
        GL.Settings:set("ShortcutKeys.disenchant", DisenchantHotkey:GetValue());
    end);
    Parent:AddChild(DisenchantHotkey);
end

GL:debug("Interface/Settings/ShortcutKeys.lua");