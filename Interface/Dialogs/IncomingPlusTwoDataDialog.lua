---@type GL
local _, GL = ...;

---@class IncomingPlusTwoDataDialogInterface
GL:tableSet(GL, "Interface.Dialogs.IncomingPlusTwoDataDialog", {});
local IncomingPlusTwoDataDialog = GL.Interface.Dialogs.IncomingPlusTwoDataDialog; ---@type IncomingPlusTwoDataDialogInterface

function IncomingPlusTwoDataDialog:open(Dialog)
    local AceGUI = GL.AceGUI;

    Dialog.checkSenderIsTrusted = GL:toboolean(Dialog.checkOS);

    -- Create a container/parent frame
    local Frame = AceGUI:Create("GargulIncomingPlusTwoDataDialog");
    Frame:SetLayout("Flow");
    Frame:SetWidth(320);
    Frame:SetQuestion(Dialog.question);
    Frame:SetSender(Dialog.sender or "");
    Frame:OnYes(Dialog.OnYes or function () end);
    Frame:OnNo(Dialog.OnNo or function () end);

    if (Dialog.sender
        and GL.PlusTwos:playerIsTrusted(Dialog.sender)
    ) then
        local TrustSenderCheckBox = GL.Interface:get(GL.Interface.Dialogs.IncomingPlusTwoDataDialog, "CheckBox.TrustSender");
        TrustSenderCheckBox:SetValue(TrustSenderCheckBox);
    end
end

GL:debug("Interface/IncomingPlusTwoDataDialog.lua");