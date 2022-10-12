---@type GL
local _, GL = ...;

local Overview = GL.Interface.Settings.Overview; ---@type SettingsOverview

---@class GeneralSettings
GL.Interface.Settings.General = {
    description = "Dah Boo Customized Gargul est une version remaniée de l'addon utilitaire Gargul, qui améliore la qualité de vie des raideurs, du responsable du butin et du raid leader. Il est désigné pour fonctionner avec TMB (thatsmybis.com) pour créer une expérience de raid sans problèmes.\n\nVérifiez les diverses sections sur la gauche de cette fenêtre ou visitez notre Wiki/Discord pour démarrer !",
    wikiUrl = "https://github.com/papa-smurf/Gargul/wiki",
};
local General = GL.Interface.Settings.General; ---@type GeneralSettings

---@return void
function General:draw(Parent)
    GL:debug("GeneralSettings:draw");

    local MoreInfoLabel = GL.AceGUI:Create("Label");
    MoreInfoLabel:SetText("Pour un support personnel ou pour vous investir, vérifiez aussi notre discord:\n");
    MoreInfoLabel:SetFontObject(_G["GameFontNormal"]);
    MoreInfoLabel:SetFullWidth(true);
    Parent:AddChild(MoreInfoLabel);

    local DiscordURL = GL.AceGUI:Create("EditBox");
    DiscordURL:DisableButton(true);
    DiscordURL:SetHeight(20);
    DiscordURL:SetFullWidth(true);
    DiscordURL:SetText("https://discord.gg/3BYJzqeSJ9");
    Parent:AddChild(DiscordURL);

    local HorizontalSpacer = GL.AceGUI:Create("SimpleGroup");
    HorizontalSpacer:SetLayout("FILL");
    HorizontalSpacer:SetFullWidth(true);
    HorizontalSpacer:SetHeight(10);
    Parent:AddChild(HorizontalSpacer);

    local OpenSoftRes = GL.AceGUI:Create("Button");
    OpenSoftRes:SetText("SoftRes");
    OpenSoftRes:SetCallback("OnClick", function()
        GL.Settings:close();
        GL.Commands:call("softreserves");
    end);
    OpenSoftRes:SetWidth(172);
    Parent:AddChild(OpenSoftRes);

    local OpenTMB = GL.AceGUI:Create("Button");
    OpenTMB:SetText("TMB ou DFT");
    OpenTMB:SetCallback("OnClick", function()
        GL.Settings:close();
        GL.Commands:call("tmb");
    end);
    OpenTMB:SetWidth(172);
    Parent:AddChild(OpenTMB);

    local OpenPackMule = GL.AceGUI:Create("Button");
    OpenPackMule:SetText("Autolooting");
    OpenPackMule:SetCallback("OnClick", function()
        GL.Settings:draw("PackMule");
    end);
    OpenPackMule:SetWidth(172);
    Parent:AddChild(OpenPackMule);

    HorizontalSpacer = GL.AceGUI:Create("SimpleGroup");
    HorizontalSpacer:SetLayout("FILL");
    HorizontalSpacer:SetFullWidth(true);
    HorizontalSpacer:SetHeight(20);
    Parent:AddChild(HorizontalSpacer);

    local Checkboxes = {
        {
            label = "Message de bienvenue",
            setting = "welcomeMessage",
        },
        {
            label = "Icône minicarte",
            setting = "showMinimapButton",
            callback = function()
                GL.MinimapButton:drawOrHide();
            end,
        },
        {
            label = "Pas de sons",
            setting = "noSounds",
        },
        {
            label = "Pas de messages",
            setting = "noMessages",
        },
        {
            label = "Afficher journal de modifications",
            description = "Active ou désactive le journal de modifications qui affiche le détail des changements après la mise à jour de Dah Boo Customized Gargul",
            setting = "changeLog",
        },
        {
            label = "Experimental : mode debug",
            description = "Activer ceci activera le mode debug, qui affiche les infos de debug dans votre fenêtre de chat. Ceci est prévu uniquement pour les développeurs travaillant activement sur l'addon Dah Boo Customized Gargul",
            setting = "debugModeEnabled",
        },
    };

    Overview:drawCheckboxes(Checkboxes, Parent);
end

GL:debug("Interface/Settings/General.lua");