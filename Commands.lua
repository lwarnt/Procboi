local addonName, Procboi = ...

local Commands = {}

Procboi.Commands = Commands

SLASH_PROCBOI1 = "/procboi"

SlashCmdList.PROCBOI = function(msg)
    Commands:Handle(msg)
end

function Commands:Handle(msg)
    Procboi.UI:Toggle()
end
