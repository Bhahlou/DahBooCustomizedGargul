---@type GL
local _, GL = ...;

GL.AceGUI = GL.AceGUI or LibStub("AceGUI-3.0");

local AceGUI = GL.AceGUI;
local DB = GL.DB; ---@type DB

GL:tableSet(GL, "Interface.TMBRaidGroups.Overview", {
    isVisible = false,
});

---@class TMBRaidGroupsOverview
local Overview = GL.Interface.TMBRaidGroups.Overview;

---@return void
function Overview:draw()
    GL:debug("Overview:draw");

    -- The overview is already visible
    if (self.isVisible) then
        return;
    end

    self.isVisible = true;

    -- Create a container/parent frame
    local Window = AceGUI:Create("Frame");
    Window:SetTitle("Dah Boo Customized Gargul v" .. GL.version);
    Window:SetLayout("Flow");
    Window:SetWidth(500);
    Window:SetHeight(250);
    Window:EnableResize(false);
    Window.statustext:GetParent():Show(); -- Explicitely show the statustext bar
    Window:SetCallback("OnClose", function()
       self:close();
    end);
    GL.Interface:setItem(self, "Window", Window);

    Window:SetPoint(GL.Interface:getPosition("TMBOverview"));

    Window:SetStatusText(string.format(
        "Importé le |c00a79eff%s|r à |c00a79eff%s|r",
        date('%d-%m-%Y', DB:get("TMBRaidGroups.MetaData.importedAt", GetServerTime())),
        date('%H:%M', DB:get("TMBRaidGroups.MetaData.importedAt", GetServerTime()))
    ));

    -- Make sure the window can be closed by pressing the escape button
    _G["GARGUL_TMBRAIDGROUPS_OVERVIEW_WINDOW"] = Window.frame;
    tinsert(UISpecialFrames, "GARGUL_TMBRAIDGROUPS_OVERVIEW_WINDOW");

    local TimestampLabel = AceGUI:Create("Label");
    TimestampLabel:SetFullWidth(true);
    TimestampLabel:SetText(string.format(
        "\nCes groupes de raid de TMB ont été importés le |c00a79eff%s|r à |c00a79eff%s|r",
        date('%d-%m-%Y', DB:get("TMBRaidGroups.MetaData.importedAt", GetServerTime())),
        date('%H:%M', DB:get("TMBRaidGroups.MetaData.importedAt", GetServerTime()))
    ));
    TimestampLabel:SetFontObject(_G["GameFontNormal"]);
    Window:AddChild(TimestampLabel);

    local ItemNumberLabel = AceGUI:Create("Label");
    ItemNumberLabel:SetFullWidth(true);
    ItemNumberLabel:SetText(string.format(
        "\nNombre de joueurs importés: |c00a79eff%s|r",
        GL:count(DB:get("TMBRaidGroups.RaidGroups")) or 0

    ));
    ItemNumberLabel:SetFontObject(_G["GameFontNormal"]);
    Window:AddChild(ItemNumberLabel);

    local VerticalSpacer = AceGUI:Create("SimpleGroup");
    VerticalSpacer:SetLayout("FILL");
    VerticalSpacer:SetFullWidth(true);
    VerticalSpacer:SetHeight(15);
    Window:AddChild(VerticalSpacer);

    local ClearButton = AceGUI:Create("Button");
    ClearButton:SetWidth(152);
    ClearButton:SetText("Effacer données");
    ClearButton:SetCallback("OnClick", function()
        GL.Interface.Dialogs.PopupDialog:open("CLEAR_TMBRAIDGROUPS_CONFIRMATION");
    end);
    Window:AddChild(ClearButton);
end

---@return void
function Overview:close()
    GL:debug("Overview:close");

    local Window = GL.Interface:getItem(self, "Window");

    if (not self.isVisible
        or not Window
    ) then
        return;
    end

    -- Store the frame's last position for future play sessions
    GL.Interface:storePosition(Window, "TMBOverview");

    -- Clear the frame and its widgets
    Window:Hide();
    self.isVisible = false;
end