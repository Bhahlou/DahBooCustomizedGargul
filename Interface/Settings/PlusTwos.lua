---@type GL
local _, GL = ...;

local Overview = GL.Interface.Settings.Overview; ---@type SettingsOverview

---@class PlusTwosSettings
GL.Interface.Settings.PlusTwos = {
    description = "With plus ones you can keep track of how many items have been awarded to each player. Players with a lower plus one value can be given a higher priority on rolls to help equalize loot distribution amongst players"
};
local PlusTwos = GL.Interface.Settings.PlusTwos; ---@type PlusTwosSettings

---@return void
function PlusTwos:draw(Parent)
    GL:debug("PlusTwosSettings:draw");

    local HorizontalSpacer;
    local Checkboxes = {
        {
            label = "Block shared data",
            description = "Block shared +1s data from other players in your raid.\nEnabling this also blocks players on your allowed list.",
            setting = "PlusTwos.blockShareData",
        },

        {
            label = "Automatically share data",
            description = "Automatically share PlusTwos data with players who join your raid.",
            setting = "PlusTwos.automaticallyShareData",
        },
        {
            label = "Whisper command",
            description = string.format(
                "Players can whisper '|cff%s!plustwo [<name>]|r' or '|cff%s!po [<name>]|r' or '|cff%s!+1 [<name>]|r' to the master looter to get the current plus one for this name in response. If no name is given, their own name is assumed instead.",
                GL:classHexColor("rogue"),
                GL:classHexColor("rogue"),
                GL:classHexColor("rogue")
            ),
            setting = "PlusTwos.enableWhisperCommand",
        },
    };

    Overview:drawCheckboxes(Checkboxes, Parent);

    HorizontalSpacer = GL.AceGUI:Create("SimpleGroup");
    HorizontalSpacer:SetLayout("FILL");
    HorizontalSpacer:SetFullWidth(true);
    HorizontalSpacer:SetHeight(15);
    Parent:AddChild(HorizontalSpacer);

    local PlusTwosIdentifier = GL.AceGUI:Create("EditBox");
    PlusTwosIdentifier:DisableButton(true);
    PlusTwosIdentifier:SetHeight(20);
    PlusTwosIdentifier:SetFullWidth(true);
    PlusTwosIdentifier:SetText(GL.Settings:get("PlusTwos.automaticallyAcceptDataFrom", ""));
    PlusTwosIdentifier:SetLabel(string.format(
        "|cff%sAdd a comma separated list of players that are allowed to overwrite your data without your explicit consent:|r",
        GL:classHexColor("rogue")
    ));
    PlusTwosIdentifier:SetCallback("OnTextChanged", function (self)
        local value = self:GetText();

        if (type(value) ~= "string") then
            return;
        end

        GL.Settings:set("PlusTwos.automaticallyAcceptDataFrom", value:gsub(" ", ""));
    end);
    Parent:AddChild(PlusTwosIdentifier);

    local OpenDataButton = GL.AceGUI:Create("Button");
    OpenDataButton:SetText("Open Plus Twos Data");
    OpenDataButton:SetCallback("OnClick", function()
        GL.Settings:close();
        GL.Commands:call("plustwo");
    end);
    Parent:AddChild(OpenDataButton);
end

GL:debug("Interface/Settings/PlusTwos.lua");