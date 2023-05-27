---@type GL
local _, GL = ...;

---@type DB
local DB = GL.DB;

---@class Settings
GL.Settings = {
    _initialized = false,
    Defaults = GL.Data.DefaultSettings,
    Active = {}, -- This object holds the actual setting values applicable to this runtime
};

---@type Settings
local Settings = GL.Settings;

---@return void
function Settings:_init()
    GL:debug("Settings:_init");

    -- No need to initialize this class twice
    if (self._initialized) then
        return;
    end

    -- Validate the settings and adjust discrepancies
    self:sanitizeSettings();

    -- Combine defaults and user settings
    self:overrideDefaultsWithUserSettings();

    -- Prepare the options / config frame
    local Frame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer);
    Frame.name = "Gargul";
    Frame:SetScript("OnShow", function ()
        self:showSettingsMenu(Frame);
    end);
    InterfaceOptions_AddCategory(Frame);

    self._initialized = true;
end

--- Make sure the settings adhere to our rules
---
---@return void
function Settings:sanitizeSettings()
    GL:debug("Settings:sanitizeSettings");

    self:enforceTemporarySettings();

    -- Remove plus one entries with a value of 0
    for player, po in pairs(DB:get("PlusOnes.Totals", {})) do
        if (not tonumber(po) or po < 1) then
            DB:set("PlusOnes.Totals." .. player, nil);
        end
    end

    -- Remove old roll data so it doesn't clog our SavedVariables
    local fiveWeeksAgo = GetServerTime() - 3024000;
    for key, Award in pairs(DB:get("AwardHistory", {})) do
        if (Award.timestamp < fiveWeeksAgo) then
            Award.Rolls = nil;
            DB:set("AwardHistory." .. key, Award);
        end
    end

    -- Permanently delete soft-deleted GDKP sessions after 48 hours
    local twoDaysAgo = GetServerTime() - 172800;
    for key, Session in pairs(DB:get("GDKP.Ledger", {})) do
        if (Session.deletedAt and Session.deletedAt < twoDaysAgo) then
            DB:set("GDKP.Ledger." .. key, nil);
        end
    end
end

--- These settings are version-specific and will be removed over time!
---
---@return void
function Settings:enforceTemporarySettings()
    GL:debug("Settings:enforceTemporarySettings");

    --- This is reserved for version-based logic (e.g. cleaning up variables, settings etc.)

    --- No point enforcing these temp settings if the user has never used Gargul
    --- before or has already loaded this version before!
    if (GL.firstBoot
        or not GL.Version.firstBoot
    ) then
        return;
    end

    --- In 5.2.0 we completely redid the GDKP queue flow and UI
    --- Make sure to re-enable so users at least get to experience it again
    if (GL.version == "5.2.0" or (not DB.LoadDetails["5.2.0"])) then
        self:set("GDKP.enableBidderQueue", true);
        DB.LoadDetails["5.2.0"] = GetServerTime();
    end

    --- In 5.2.0 we moved GDKP item details from settings to GDKP DB
    if (DB:get("Settings.GDKP.SettingsPerItem")) then
        local OldSettings = DB:get("Settings.GDKP.SettingsPerItem");

        if (type(OldSettings) ~= "table") then
            OldSettings = {};
        end

        if (GL:empty(DB:get("GDKP.SettingsPerItem"))) then
            DB:set("GDKP.SettingsPerItem", OldSettings);
        end

        DB:set("Settings.GDKP.SettingsPerItem", nil);
    end

    --- In 5.1.0 we added +1 broadcasting, auto-share should be disabled by default
    if (GL.version == "5.1.1" or (
        not GL.firstBoot and not DB.LoadDetails["5.1.1"])
    ) then
        DB:set("Settings.PlusOnes.automaticallyShareData", false);
        DB.LoadDetails["5.1.1"] = GetServerTime();
    end

    --- in 5.0.13 we remove the GDKP.doCountdown and x settings
    DB:set("Settings.GDKP.doCountdown", nil);
    DB:set("Settings.GDKP.announceCountdownOnce", nil);

    --- In the GDKP module we added extra shortcut keys forcing us to remap old ones
    if (not DB.Settings.ShortcutKeys.rollOffOrAuction) then
        DB.Settings.ShortcutKeys.rollOffOrAuction = DB.Settings.ShortcutKeys.rollOff or "ALT_CLICK";
        DB.Settings.ShortcutKeys.rollOff = "DISABLED";
    end
end

--- Draw a setting section
---
---@param section string|nil
---@param onCloseCallback function|nil What to do after closing the settings again
---@return void
function Settings:draw(section, onCloseCallback)
    GL.Interface.Settings.Overview:draw(section, onCloseCallback);
end

---@return void
function Settings:close()
    GL.Interface.Settings.Overview:close();
end

--- Reset the addon to its default settings
---
---@return void
function Settings:resetToDefault()
    GL:debug("Settings:resetToDefault");

    self.Active = {};
    DB.Settings = {};

    -- Combine defaults and user settings
    self:overrideDefaultsWithUserSettings();
end

--- Override the addon's default settings with the user's custom settings
---
---@return void
function Settings:overrideDefaultsWithUserSettings()
    GL:debug("Settings:overrideDefaultsWithUserSettings");

    -- Reset the currently active settings table
    self.Active = {};

    -- Combine the default and user's settings to one settings table
    Settings = GL:tableMerge(Settings.Defaults, DB.Settings);

    -- Set the values of the settings table directly on the GL.Settings table.
    for key, value in pairs(Settings) do
        self.Active[key] = value;
    end

    DB.Settings = self.Active;
end

--- We use this method to make sure that the interface is only built
--- when the user has actually accessed the settings menu, which doesn't happen every session
---
---@return void
function Settings:showSettingsMenu(Frame)
    GL:debug("Settings:showSettingsMenu");

    -- Add the addon title to the top of the settings frame
    local Title = Frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
    Title:SetPoint("TOPLEFT", 16, -16);
    Title:SetText(string.format("Gargul |c00967FD2(v%s)|r", GL.version));

    local SettingsButton = CreateFrame("Button", nil, Frame, "UIPanelButtonTemplate");
    SettingsButton:SetText("Settings");
    SettingsButton:SetWidth(177);
    SettingsButton:SetHeight(24);
    SettingsButton:SetPoint("TOPLEFT", Title, "BOTTOMLEFT", 0, -16);
    SettingsButton:SetScript("OnClick", function()
        -- Make sure the vanilla interface options are closed and don't reopen automatically
        HideUIPanel(InterfaceOptionsFrame);
        HideUIPanel(GameMenuFrame);

        self:draw();
    end);

    local ResetUIButton = CreateFrame("Button", nil, Frame, "UIPanelButtonTemplate");
    ResetUIButton:SetText("Reset Gargul UI");
    ResetUIButton:SetWidth(177);
    ResetUIButton:SetHeight(24);
    ResetUIButton:SetPoint("TOPLEFT", Title, "BOTTOMLEFT", 200, -16);
    ResetUIButton:SetScript("OnClick", function()
        GL.Commands:call("resetui");
    end);
end

--- Get a setting by a given key. Use dot notation to traverse multiple levels e.g:
--- Settings.UI.Auctioneer.offsetX can be fetched using Settings:get("Settings.UI.Auctioneer.offsetX")
--- without having to worry about tables or keys existing yes or no.
---
---@param keyString string
---@param default any
---@return any
function Settings:get(keyString, default)
    -- Just in case something went wrong with merging the default settings
    if (type(default) == "nil") then
        default = GL:tableGet(GL.Data.DefaultSettings, keyString);
    end

    return GL:tableGet(self.Active, keyString, default);
end

--- Set a setting by a given key and value. Use dot notation to traverse multiple levels e.g:
--- Settings.UI.Auctioneer.offsetX can be set using Settings:set("Settings.UI.Auctioneer.offsetX", myValue)
--- without having to worry about tables or keys existing yes or no.
---
---@param keyString string
---@param value any
---@param quiet boolean Should trigger event?
---@return boolean
function Settings:set(keyString, value, quiet)
    local success = GL:tableSet(self.Active, keyString, value);

    if (success and not quiet) then
        GL.Events:fire("GL.SETTING_CHANGED", keyString, value);
    end

    return success
end

GL:debug("Settings.lua");