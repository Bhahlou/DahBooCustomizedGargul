---@type GL
local _, GL = ...;

GL.ScrollingTable = GL.ScrollingTable or LibStub("ScrollingTable");

---@class AwardInterface
GL.Interface.Award = {
    ItemBoxHoldsValidItem = false,
    PlayersTable = {},
    Defaults = {
        itemIcon = "Interface\\Icons\\INV_Misc_QuestionMark",
        itemBoxText = "",
    },
};

local AceGUI = GL.AceGUI;
local Settings = GL.Settings; ---@type Settings
local Award = GL.Interface.Award; ---@type AwardInterface
local ScrollingTable = GL.ScrollingTable;

--- This is the UI the person who rolls off an item uses to prepare everything e.g:
--- Select an item
--- Set the duration of the roll off
--- Award the item to the winner
---
---@param itemLink string
---@return void
function Award:draw(itemLink)
    GL:debug("Award:draw");

    local itemID = GL:getItemIdFromLink(itemLink);

    -- First we need to check if the frame hasn't been
    -- rendered already. If so then show it (if it's hidden)
    -- and pass the itemLink along in case one was provided
    if (GL.Interface:getItem(self, "Window")
        and GL.Interface:getItem(self, "Window").rendered
    ) then
        if (itemLink) then
            Award:passItemLink(itemLink);
        end

        -- If the frame is hidden we need to show it again
        if (not GL.Interface:getItem(self, "Window"):IsShown()) then
            GL.Interface:getItem(self, "Window"):Show();
        end

        Award:populatePlayersTable(itemID or nil);
        return;
    end

    -- Create a container/parent frame
    local Window = AceGUI:Create("Frame");
    Window:SetTitle("Gargul v" .. GL.version);
    Window:SetLayout("Flow");
    Window:SetWidth(430);
    Window:SetHeight(290);
    Window:EnableResize(false);
    Window.rendered = true;
    Window.frame:SetFrameStrata("HIGH");
    Window.statustext:GetParent():Hide(); -- Hide the statustext bar
    Window:SetCallback("OnClose", function()
        self:close();
    end);
    Window:SetPoint(GL.Interface:getPosition("Award"));

    GL.Interface:setItem(self, "Window", Window);

    -- Make sure the window can be closed by pressing the escape button
    _G["GARGUL_AWARD_WINDOW"] = Window.frame;
    tinsert(UISpecialFrames, "GARGUL_AWARD_WINDOW");

    --[[
        FIRST ROW (ITEM AND BUTTONS)
    ]]

    local FirstRow = AceGUI:Create("SimpleGroup");
    FirstRow:SetLayout("Flow");
    FirstRow:SetFullWidth(true);
    FirstRow:SetHeight(30);
    Window:AddChild(FirstRow);

    --[[
        ITEM ICON
    ]]

    local ItemIcon = AceGUI:Create("Icon");
    ItemIcon:SetImage(Award.Defaults.itemIcon);
    ItemIcon:SetImageSize(30, 30);
    ItemIcon:SetWidth(40);
    FirstRow:AddChild(ItemIcon);
    GL.Interface:setItem(self, "Item", ItemIcon);

    --[[
        ITEM TEXTBOX
    ]]
    local ItemBox = AceGUI:Create("EditBox");

    ItemBox:DisableButton(true);
    ItemBox:SetHeight(20);
    ItemBox:SetWidth(150);
    ItemBox:SetCallback("OnTextChanged", function () self:ItemBoxChanged() end); -- Update item info when input value changes
    ItemBox:SetCallback("OnEnterPressed", function () self:ItemBoxChanged() end); -- Update item info when item is dragged on top (makes no sense to use OnEnterPressed I know)
    GL.Interface:setItem(self, "Item", ItemBox);

    FirstRow:AddChild(ItemBox);

    -- Show a gametooltip if the icon shown belongs to an item
    ItemIcon:SetCallback("OnEnter", function()
        if (not Award.ItemBoxHoldsValidItem) then
            return;
        end

        local itemLink = ItemBox:GetText();
        GameTooltip:SetOwner(ItemIcon.frame, "ANCHOR_TOP");
        GameTooltip:SetHyperlink(itemLink);
        GameTooltip:Show();
    end)

    ItemIcon:SetCallback("OnLeave", function()
        GameTooltip:Hide();
    end)

    --[[
        SPACER
    ]]

    local PreButtonSpacer = AceGUI:Create("SimpleGroup");
    PreButtonSpacer:SetLayout("Flow");
    PreButtonSpacer:SetWidth(4);
    PreButtonSpacer:SetHeight(20);
    FirstRow:AddChild(PreButtonSpacer);

    --[[
        AWARD BUTTON
    ]]

    local AwardButton = AceGUI:Create("Button");
    AwardButton:SetText("Attribuer");
    AwardButton:SetWidth(90);
    AwardButton:SetHeight(20);
    AwardButton:SetDisabled(true);
    AwardButton:SetCallback("OnClick", function()
        local PlayersTable = GL.Interface:getItem(self, "Table.Players");
        local selected = PlayersTable:GetRow(PlayersTable:GetSelection());
        itemLink = GL.Interface:getItem(self, "EditBox.Item"):GetText();
        local winner = false;

        local award = function ()
            local isOS = false;
            local addPlusOne = false;
            local cost = nil;

            local OSCheckBox = GL.Interface:getItem(GL.Interface.Dialogs.AwardDialog, "CheckBox.OffSpec");
            if (OSCheckBox) then
                isOS = GL:toboolean(OSCheckBox:GetValue());

                if (isOS) then
                    GL.PlusTwos:add(winner);
                end
            end

            local addPlusOneCheckBox = GL.Interface:getItem(GL.Interface.Dialogs.AwardDialog, "CheckBox.PlusOne");
            if (addPlusOneCheckBox) then
                addPlusOne = GL:toboolean(addPlusOneCheckBox:GetValue());

                if (addPlusOne) then
                    GL.PlusOnes:add(winner);
                end
            end

            local BoostedRollCostEditBox = GL.Interface:getItem(GL.Interface.Dialogs.AwardDialog, "EditBox.Cost");
            if (BoostedRollCostEditBox) then
                cost = GL.BoostedRolls:toPoints(BoostedRollCostEditBox:GetText());

                if (cost) then
                    GL.BoostedRolls:modifyPoints(winner, -cost);
                end
            end

            -- Add the player we awarded the item to to the item's tooltip
            GL.AwardedLoot:addWinner(winner, itemLink, nil, nil, isOS, cost, addPlusOne);
            GL.Interface.Award:reset();

            if (Settings:get("UI.Award.closeOnAward", true)) then
                self:close();
            end
        end

        -- No player was selected, check if the ML wants to award this item to a random player
        if (not selected or type(selected) ~= "table") then
            -- Show a confirmation dialog asking whether we should award this to a random person
            return GL.Interface.Dialogs.PopupDialog:open({
                question = string.format("Do you want to award %s to a random player?", itemLink),
                OnYes = function ()
                    local GroupMembers = GL.User:groupMembers();

                    -- Pick a random winner
                    winner = GL:tableGet(GroupMembers[math.random( #GroupMembers)] or {}, "name", false);

                    -- We couldn't find any winner (shouldn't be possible, just a safety check)
                    if (not winner) then
                        return;
                    end

                    GL:sendChatMessage(string.format("Random winner for %s selected (%s)", itemLink, winner), "GROUP");
                    award();
                end,
            });
        end

        winner = selected.cols[1].value;

        -- Make sure the initiator has to confirm his choices
        GL.Interface.Dialogs.AwardDialog:open({
            question = string.format("Attribuer %s à |cff%s%s|r ?",
                itemLink,
                GL:classHexColor(GL.Player:classByName(winner)),
                winner
            ),
            OnYes = award,
        });
    end);
    FirstRow:AddChild(AwardButton);
    GL.Interface:setItem(self, "Award", AwardButton);

    --[[
        DISENCHANT BUTTON
    ]]
    local DisenchantButton = AceGUI:Create("Button");
    DisenchantButton:SetText("Dez");
    DisenchantButton:SetWidth(80);
    DisenchantButton:SetHeight(20);
    DisenchantButton:SetDisabled(false);
    DisenchantButton:SetCallback("OnClick", function()
        local itemLink = GL.Interface:getItem(self, "EditBox.Item"):GetText();

        if (GL.PackMule.disenchanter) then
            GL.PackMule:disenchant(itemLink);

            if (Settings:get("UI.Award.closeOnAward", true)) then
                self:close();
            end

            return;
        end

        local PlayersTable = GL.Interface:getItem(self, "Table.Players");
        local selected = PlayersTable:GetRow(PlayersTable:GetSelection());

        if (not selected or type(selected) ~= "table") then
            return GL:warning("You need to select a player first");
        end

        local disenchanter = selected.cols[1].value;

        -- No disenchanter was set yet
        GL.Interface.Dialogs.PopupDialog:open({
            question = string.format("Set |cff%s%s|r as your disenchanter?",
                GL:classHexColor(GL.Player:classByName(disenchanter)),
                disenchanter
            ),
            OnYes = function ()
                GL.PackMule.disenchanter = disenchanter;
                GL.PackMule:disenchant(itemLink, true);

                if (Settings:get("UI.Award.closeOnAward", true)) then
                    self:close();
                end
            end,
        });
    end);
    FirstRow:AddChild(DisenchantButton);
    GL.Interface:setItem(self, "Disenchant", DisenchantButton);

    --[[
        SECOND ROW (GROUP MEMBERS)
    ]]

    local SecondRow = AceGUI:Create("SimpleGroup");
    SecondRow:SetLayout("FILL");
    SecondRow:SetFullWidth(true);
    SecondRow:SetHeight(170);
    Window:AddChild(SecondRow);

    Award:drawPlayersTable();

    --[[
        THIRD ROW (AUTO CLOSE CHECKBOX)
    ]]

    local ThirdRow = AceGUI:Create("SimpleGroup");
    ThirdRow:SetLayout("Flow");
    ThirdRow:SetFullWidth(true);
    ThirdRow:SetHeight(50);
    Window:AddChild(ThirdRow);

    local CloseOnAward = AceGUI:Create("CheckBox");
    CloseOnAward:SetLabel("Fermer à l'attribution");
    CloseOnAward:SetValue(Settings:get("UI.Award.closeOnAward", true));
    CloseOnAward:SetCallback("OnValueChanged", function (widget)
        Settings:set("UI.Award.closeOnAward", widget:GetValue());
    end);
    CloseOnAward:SetWidth(150);
    ThirdRow:AddChild(CloseOnAward);

    self:draw(itemLink);
end

---@return void
function Award:close()
    GL:debug("Award:close");

    local Window = GL.Interface:getItem(self, "Window");

    if (not Window) then
        return;
    end

    GL.Interface:storePosition(Window, "Award");
    Window:Hide();
end

---@param Parent table
---@return void
function Award:drawPlayersTable()
    GL:debug("Award:drawPlayersTable");

    local Parent = GL.Interface:getItem(self, "Window").frame;

    -- Combined width of all colums should be 340
    local columns = {
        {
            name = "Player",
            width = 340,
            align = "LEFT",
            color = {
                r = 0.5,
                g = 0.5,
                b = 1.0,
                a = 1.0
            },
            colorargs = nil,
            sort = GL.Data.Constants.ScrollingTable.ascending,
        },
    };

    local Table = ScrollingTable:CreateST(columns, 8, 15, nil, Parent);
    Table:EnableSelection(true);
    Table.frame:SetPoint("BOTTOM", Parent, "BOTTOM", 0, 60);
    GL.Interface:setItem(self, "Players", Table);

    Award:populatePlayersTable();
end

--- Check if a single player is top prio on a given item ID
---
---@param itemID
---@return nil|string
function Award:topPrioForItem(itemID)
    GL:debug("Award:topPrioForItem");

    -- This item was only reserved by one player
    if (GL.SoftRes:available()) then
        local lastPlayerName = false;
        local moreThanOnePersonReservedThisItem = false;
        for _, playerName in pairs(GL.SoftRes:byItemId(itemID)) do
            if (not lastPlayerName) then
                lastPlayerName = playerName;
            end

            if (playerName ~= lastPlayerName) then
                moreThanOnePersonReservedThisItem = true;
                break;
            end
        end

        if (not moreThanOnePersonReservedThisItem) then
            return lastPlayerName;
        end
    end

    local PrioListEntries = {};
    local WishListEntries = {};
    for _, Entry in pairs(GL.TMB:byItemId(itemID)) do
        -- Priolist entry
        if (Entry.type == 1) then
            tinsert(PrioListEntries, Entry);

        -- Wishlist entry
        elseif (Entry.type == 2) then
            tinsert(WishListEntries, Entry);
        end
    end

    -- There are prio list entries available, use them
    if (not GL:empty(PrioListEntries)) then
        if (GL:count(PrioListEntries) == 1) then
            return PrioListEntries[1].character;
        end

        -- Sort the PrioListEntries based on prio (lowest to highest)
        table.sort(PrioListEntries, function (a, b)
            return a.prio < b.prio;
        end);

        -- There's more than 1 person with top prio
        if (PrioListEntries[1].prio == PrioListEntries[2].prio) then
            return;
        end

        return PrioListEntries[1].character;
    end

    -- There are wish list entries available, use them
    if (not GL:empty(WishListEntries)) then
        if (GL:count(WishListEntries) == 1) then
            return WishListEntries[1].character;
        end

        -- Sort the WishListEntries based on prio (lowest to highest)
        table.sort(WishListEntries, function (a, b)
            return a.prio < b.prio;
        end);

        -- There's more than 1 person with top prio
        if (WishListEntries[1].prio == WishListEntries[2].prio) then
            return;
        end

        return WishListEntries[1].character;
    end
end

-- Populate the players table with your current group members
function Award:populatePlayersTable(itemID)
    GL:debug("Award:populatePlayersTable");

    local PlayersTable = GL.Interface:getItem(self, "Table.Players");

    if (not PlayersTable) then
        return;
    end

    PlayersTable:ClearSelection();

    local topPrioForItem = self:topPrioForItem(itemID);

    local TableData = {};
    local row = 1;
    for _, Player in pairs(GL.User:groupMembers()) do
        local name = Player.name;

        tinsert(TableData, {
            cols = {
                {
                    value = name,
                    color = GL:classRGBAColor(Player.class),
                },
            },
        });

        if (topPrioForItem == string.lower(GL:stripRealm(name))) then
            PlayersTable:SetSelection(row);
        end

        row = row + 1;
    end

    PlayersTable:SetData(TableData);
end

--- The item box contents changed
---@return void
function Award:ItemBoxChanged()
    GL:debug("Award:ItemBoxChanged");

    local itemLink = GL.Interface:getItem(self, "EditBox.Item"):GetText();

    Award:passItemLink(itemLink);
end

--- Pass an item link to the master looter UI
--- This method is used when alt clicking an item
--- in a loot window or when executing /gl roll [itemlink]
---
---@param itemLink string
---@return void
function Award:passItemLink(itemLink)
    GL:debug("Award:passItemLink");

    if (not GL.Interface:getItem(self, "Window").rendered) then
        return;
    end

    GL.Interface:getItem(self, "EditBox.Item"):SetText(itemLink);
    Award:update();
end

--- Update the master looter UI based on the value of the ItemBox input
---
---@return void
function Award:update()
    GL:debug("Award:update");

    local IconWidget = GL.Interface:getItem(self, "Icon.Item");
    local itemLink = GL.Interface:getItem(self, "EditBox.Item"):GetText();

    -- If the item link is not valid then
    --   Show the default question mark icon
    if (not itemLink or itemLink == "") then
        GL:debug("Award:update. Item link is invalid");

        Award.ItemBoxHoldsValidItem = false;
        IconWidget:SetImage(Award.Defaults.itemIcon);

        Award:updateWidgets();
        return;
    end

    -- The item's icon is in the 10th position
    local icon = select(10, GetItemInfo(itemLink));

    if (icon) then
        GL.Interface:getItem(self, "Table.Players"):ClearSelection();

        IconWidget:SetImage(icon);
        Award.ItemBoxHoldsValidItem = true;
    else
        Award.ItemBoxHoldsValidItem = false;
        IconWidget:SetImage(Award.Defaults.itemIcon);
    end

    Award:updateWidgets();
end

--- Reset the roll off UI to its defaults
---
---@return void
function Award:reset()
    GL:debug("Award:reset");

    GL.Interface:getItem(self, "Icon.Item"):SetImage(Award.Defaults.itemIcon);
    GL.Interface:getItem(self, "EditBox.Item"):SetText(Award.Defaults.itemText);
    Award.ItemBoxHoldsValidItem = false;

    Award:updateWidgets();
end

--- Update the widgets based on the current state of the roll off
---
---@return void
function Award:updateWidgets()
    GL:debug("Award:updateWidgets");

    -- If the itembox doesn't hold a valid item link then:
    --   The start button should not be available
    --   The stop button should be available
    --   The item box should be available
    if (not Award.ItemBoxHoldsValidItem) then
        GL.Interface:getItem(self, "Button.Award"):SetDisabled(true);
        GL.Interface:getItem(self, "Button.Disenchant"):SetDisabled(true);
    else
        GL.Interface:getItem(self, "Button.Award"):SetDisabled(false);
        GL.Interface:getItem(self, "Button.Disenchant"):SetDisabled(false);
    end
end

GL:debug("Award.lua");