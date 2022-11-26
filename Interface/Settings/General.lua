---@type GL
local _, GL = ...;

local Overview = GL.Interface.Settings.Overview; ---@type SettingsOverview

---@class GeneralSettings
GL.Interface.Settings.General = {};
local General = GL.Interface.Settings.General; ---@type GeneralSettings

---@return void
function General:draw(Parent)
    GL:debug("GeneralSettings:draw");

    local Checkboxes = {
        {
            label = "Message de bienvenue",
            description = "Affiche un message de bienvenue en lançant Dah Boo Customized Gargul",
            setting = "welcomeMessage",
        },
        {
            label = "Minimap Icon",
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
        {
            label = "Experimental: addon usage",
            description = "Affiche l'utilisation de la mémoire par l'addon. Attention : peut causer des chutes de FPS !",
            setting = "profilerEnabled",
            callback = function ()
                if (GL.Settings:get("profilerEnabled")) then
                    GL.Profiler:draw();
                else
                    GL.Profiler:close();
                end
            end,
        },
    };

    Overview:drawCheckboxes(Checkboxes, Parent);
end

GL:debug("Interface/Settings/General.lua");