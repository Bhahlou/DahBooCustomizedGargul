---@type GL
local _, GL = ...;

---@class PlusTwosOverview
GL:tableSet(GL, "Interface.PlusTwos.Overview", {
    isVisible = false,
});

local AceGUI = GL.AceGUI;
local Overview = GL.Interface.PlusTwos.Overview; ---@type PlusTwosOverview

function Overview:draw()
    GL:debug("Overview:draw");

    if (self.isVisible) then
        return;
    end

    self.isVisible = true;

    -- Create a container/parent frame
    local Window = AceGUI:Create("Frame");
    Window:SetTitle("Gargul v" .. GL.version);
    Window:SetLayout("Flow");
    Window:SetWidth(300);
    Window:SetHeight(400);
    Window.statustext:GetParent():Hide(); -- Hide the statustext bar
    Window:EnableResize(false);
    Window:SetCallback("OnClose", function()
        self:close();
    end);
    GL.Interface:setItem(self, "Window", Window);
    Window:SetPoint(GL.Interface:getPosition("PlusTwosOverview"));

    local ScrollFrameParent = AceGUI:Create("SimpleGroup");
    ScrollFrameParent:SetLayout("Fill");
    ScrollFrameParent:SetFullWidth(true);
    ScrollFrameParent:SetHeight(318);
    Window:AddChild(ScrollFrameParent);

    local ScrollFrame = AceGUI:Create("ScrollFrame");
    ScrollFrame:SetLayout("Flow");
    ScrollFrameParent:AddChild(ScrollFrame);

    local HorizontalSpacer = AceGUI:Create("SimpleGroup");
    HorizontalSpacer:SetLayout("FILL");
    HorizontalSpacer:SetFullWidth(true);
    HorizontalSpacer:SetHeight(6);
    Window:AddChild(HorizontalSpacer);

    local ClearButton = AceGUI:Create("Button");
    ClearButton:SetText("Clear");
    ClearButton:SetWidth(80);
    ClearButton:SetCallback("OnClick", function()
        GL.Interface.Dialogs.PopupDialog:open({
            question = "Are you sure you want to clear all PlusTwos?",
            OnYes = function ()
                GL.PlusTwos:clear();
            end,
        });
    end);
    Window:AddChild(ClearButton);

    self:addPlayerPlusTwoEntries(ScrollFrame);

    GL.Events:register("PlusTwosOverViewChangeListener", "GL.PLUSONES_CHANGED", function () self:update(); end);
    GL.Events:register("PlusTwosOverViewRosterUpdatedListener","GROUP_ROSTER_UPDATE", function () GL.PlusTwos:triggerChangeEvent(); end);
end

--- Add all player entries to the PlusTwos ScrollFrame
---
---@param Parent table
---@return void
function Overview:addPlayerPlusTwoEntries(Parent)
    local VerticalSpacer;
    local HorizontalSpacer;
    local PlusTwoEntries = {};

    for _, Player in pairs(GL.User:groupMembers()) do
        local normalizedName = GL:normalizedName(Player.name);

        tinsert(PlusTwoEntries, {
            name = normalizedName,
            class = Player.class,
            plusTwos = GL.PlusTwos:get(Player.name),
        });
    end

    -- Sort the PlusTwo entries alphabetically
    table.sort(PlusTwoEntries, function (a, b)
        return a.name < b.name;
    end);

    for _, Entry in pairs(PlusTwoEntries) do
        local Row = AceGUI:Create("SimpleGroup");
        Row:SetLayout("Flow");
        Row:SetFullWidth(true);
        Row:SetHeight(30);

        VerticalSpacer = AceGUI:Create("SimpleGroup");
        VerticalSpacer:SetLayout("FILL");
        VerticalSpacer:SetWidth(10);
        VerticalSpacer:SetHeight(10);
        Row:AddChild(VerticalSpacer);

        local PlayerName = AceGUI:Create("Label");
        PlayerName:SetFontObject(_G["GameFontNormal"]);
        PlayerName:SetText(GL:capitalize(Entry.name));
        PlayerName:SetColor(unpack(GL:classRGBColor(Entry.class)))
        PlayerName:SetHeight(28);
        PlayerName:SetWidth(120);
        Row:AddChild(PlayerName);

        local DeductButton = AceGUI:Create("Button");
        DeductButton:SetText("<");
        DeductButton:SetWidth(38);
        DeductButton:SetCallback("OnClick", function()
            GL.PlusTwos:deduct(Entry.name);
        end);
        Row:AddChild(DeductButton);

        local PlusTwoStatus = AceGUI:Create("Label");
        PlusTwoStatus:SetFontObject(_G["GameFontNormal"]);
        PlusTwoStatus:SetText(Entry.plusTwos);
        PlusTwoStatus:SetHeight(28);
        PlusTwoStatus:SetWidth(30);
        PlusTwoStatus:SetJustifyH("CENTER");
        Row:AddChild(PlusTwoStatus);
        GL.Interface:setItem(self, "PlusTwosOf_" .. Entry.name, PlusTwoStatus);

        local AddButton = AceGUI:Create("Button");
        AddButton:SetText(">");
        AddButton:SetWidth(38);
        AddButton:SetCallback("OnClick", function()
            GL.PlusTwos:add(Entry.name);
        end);
        Row:AddChild(AddButton);

        Parent:AddChild(Row);

        HorizontalSpacer = AceGUI:Create("SimpleGroup");
        HorizontalSpacer:SetLayout("FILL");
        HorizontalSpacer:SetFullWidth(true);
        HorizontalSpacer:SetHeight(8);
        Parent:AddChild(HorizontalSpacer);
    end
end

--- Close the window and stop listening for plustwo changes
---
---@return void
function Overview:close()
    GL:debug("Overview:close");

    if (not self.isVisible) then
        return;
    end

    local Window = GL.Interface:getItem(self, "Window");

    if (Window) then
        Window:Hide();
    end

    self.isVisible = false;
    GL.Interface:storePosition(Window, "PlusTwosOverview");

    GL.Events:unregister("PlusTwosOverViewChangeListener");
    GL.Events:unregister("PlusTwosOverViewRosterUpdatedListener");
end

--- Update all PlusTwo values in the plustwo overview
---
---@return void
function Overview:update()
    if (not IsInGroup()) then
        self:close();
        return self:draw();
    end

    for _, Player in pairs(GL.User:groupMembers()) do
        local normalizedName = GL:normalizedName(Player.name);
        local PlusTwoLabel = GL.Interface:getItem(self, "Label.PlusTwosOf_" .. normalizedName);

        if (PlusTwoLabel) then
            PlusTwoLabel:SetText(GL.PlusTwos:get(normalizedName));
        else
            self:close();
            return self:draw();
        end
    end
end

GL:debug("Interfaces/PlusTwos/Overview.lua");