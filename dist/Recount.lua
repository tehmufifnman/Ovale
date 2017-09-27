local OVALE, Ovale = ...
local OvaleRecount = Ovale:NewModule("OvaleRecount")
Ovale.OvaleRecount = OvaleRecount
local L = nil
local OvaleScore = nil
local Recount = LibStub("AceAddon-3.0"):GetAddon("Recount", true)
local _setmetatable = setmetatable
local DataModes = function(self, data, num)
    if  not data then
        return 0, 0
    end
    local fight = data.Fights[Recount.db.profile.CurDataSet]
    local score
    if fight and fight.Ovale and fight.OvaleMax then
        score = fight.Ovale * 1000 / fight.OvaleMax
    else
        score = 0
    end
    if num == 1 then
        return score
    end
    return score, nil
end
local TooltipFuncs = function(self, name, data)
    local SortedData, total
    GameTooltip:ClearLines()
    GameTooltip:AddLine(name)
end
local OvaleRecount = __class()
function OvaleRecount:OnInitialize()
    OvaleScore = Ovale.OvaleScore
    if Recount then
        local AceLocale = LibStub("AceLocale-3.0", true)
        local L = AceLocale and AceLocale:GetLocale("Recount", true)
        if  not L then
            L = _setmetatable({}, {
                __index = function(t, k)
                    t[k] = k
                    return k
                end
            })
        end
        Recount:AddModeTooltip(OVALE, DataModes, TooltipFuncs, nil, nil, nil, nil)
    end
end
function OvaleRecount:OnEnable()
    if Recount then
        OvaleScore:RegisterDamageMeter("OvaleRecount", self, "ReceiveScore")
    end
end
function OvaleRecount:OnDisable()
    OvaleScore:UnregisterDamageMeter("OvaleRecount")
end
function OvaleRecount:ReceiveScore(name, guid, scored, scoreMax)
    if Recount then
        local source = Recount.db2.combatants[name]
        if source then
            Recount:AddAmount(source, OVALE, scored)
            Recount:AddAmount(source, OVALE + "Max", scoreMax)
        end
    end
end
