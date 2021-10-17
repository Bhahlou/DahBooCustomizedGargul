---@type GL
local _, GL = ...;

local Overview = GL.Interface.Settings.Overview; ---@type SettingsOverview
GL.AceGUI = GL.AceGUI or LibStub("AceGUI-3.0");

---@class ExportingLootSettings
GL.Interface.Settings.ExportingLoot = {
    description = "Gargul keeps track of all loot awarded via /gl award or via one of the shortcuts (see the 'Awarding Loot' section on the left). Items awarded this way can be exported in order to share loot data with TMB, archiving purposes or audits. To export items you can run '/gl export' or Shift+Right-click the Gargul minimap icon.",
    wikiUrl = "https://github.com/papa-smurf/Gargul/wiki/Export-To-TMB",
};
local ExportingLoot = GL.Interface.Settings.ExportingLoot; ---@type ExportingLootSettings
local Constants = GL.Data.Constants; ---@type Data

---@return void
function ExportingLoot:draw(Parent)
    GL:debug("ExportingLootSettings:draw");

    local HorizontalSpacer;
    local Checkboxes = {
        {
            label = "Include disenchanted items",
            description = "Check this if you want to export disenchanted items as well",
            setting = "ExportingLoot.includeDisenchantedItems",
        },
    };

    Overview:drawCheckboxes(Checkboxes, Parent);

    HorizontalSpacer = GL.AceGUI:Create("SimpleGroup");
    HorizontalSpacer:SetLayout("FILL");
    HorizontalSpacer:SetFullWidth(true);
    HorizontalSpacer:SetHeight(10);
    Parent:AddChild(HorizontalSpacer);

    local DisenchanterIdentifier = GL.AceGUI:Create("EditBox");
    DisenchanterIdentifier:DisableButton(true);
    DisenchanterIdentifier:SetHeight(20);
    DisenchanterIdentifier:SetFullWidth(true);
    DisenchanterIdentifier:SetText(GL.Settings:get("ExportingLoot.disenchanterIdentifier"));
    DisenchanterIdentifier:SetLabel(string.format(
        "|cff%sUnder which name should disenchanted items be mentioned? (Default: _disenchanted)|r",
        GL:classHexColor("rogue")
    ));
    DisenchanterIdentifier:SetCallback("OnTextChanged", function (self)
        local value = self:GetText();

        if (type(value) ~= "string"
            or GL:empty(value)
        ) then
            return;
        end

        GL.Settings:set("ExportingLoot.disenchanterIdentifier", value);
    end);
    Parent:AddChild(DisenchanterIdentifier);

    HorizontalSpacer = GL.AceGUI:Create("SimpleGroup");
    HorizontalSpacer:SetLayout("FILL");
    HorizontalSpacer:SetFullWidth(true);
    HorizontalSpacer:SetHeight(10);
    Parent:AddChild(HorizontalSpacer);

    local ExportFormatLabel = GL.AceGUI:Create("Label");
    ExportFormatLabel:SetColor(1, .95686, .40784);
    ExportFormatLabel:SetText("The format in which awarded loot should be exported");
    ExportFormatLabel:SetHeight(20);
    ExportFormatLabel:SetFullWidth(true);
    Parent:AddChild(ExportFormatLabel);

    local DropDownItems = {
        [1] = "Thatsmybis TMB / RCLC (default)",
        [2] = "DFT-Fight-Club (US date format)",
        [3] = "DFT-Fight-Club (EU date format)",
    };

    local ExportFormat = GL.AceGUI:Create("Dropdown");
    ExportFormat:SetValue(GL.Settings:get("ExportingLoot.format", Constants.ExportFormats.TMB));
    ExportFormat:SetList(DropDownItems);
    ExportFormat:SetText(DropDownItems[GL.Settings:get("ExportingLoot.format", Constants.ExportFormats.TMB)]);
    ExportFormat:SetWidth(250);
    ExportFormat:SetCallback("OnValueChanged", function()
        GL.Settings:set("ExportingLoot.format", ExportFormat:GetValue());

        -- Refresh the export window if it's open
        if (GL.Exporter.visible) then
            GL.Exporter:refreshExportString();
        end
    end);
    Parent:AddChild(ExportFormat);

    HorizontalSpacer = GL.AceGUI:Create("SimpleGroup");
    HorizontalSpacer:SetLayout("FILL");
    HorizontalSpacer:SetFullWidth(true);
    HorizontalSpacer:SetHeight(10);
    Parent:AddChild(HorizontalSpacer);

    local OpenExporter = GL.AceGUI:Create("Button");
    OpenExporter:SetText("Open Exporter");
    OpenExporter:SetCallback("OnClick", function()
        GL.Settings:close();
        GL.Commands:call("export");
    end);
    Parent:AddChild(OpenExporter);
end

GL:debug("Interface/Settings/ExportingLoot.lua");