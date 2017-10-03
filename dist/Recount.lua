local __addonName, __addon = ...
__addon.require(__addonName, __addon, "Recount", { "./Ovale", "./Localization", "./Score", "AceLocale-3.0", "Recount" }, function(__exports, __Ovale, __Localization, __Score, AceLocale, Recount)
local OvaleRecountBase = __Ovale.Ovale:NewModule("OvaleRecount")
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

local OvaleRecountClass = __class(OvaleRecountBase, {
    OnInitialize = function(self)
        if Recount then
            local aceLocale = AceLocale and AceLocale:GetLocale("Recount", true)
            if  not aceLocale then
                aceLocale = _setmetatable({}, {
                    __index = function(t, k)
                        t[k] = k
                        return k
                    end

                })
            end
            Recount:AddModeTooltip(__Ovale.Ovale:GetName(), DataModes, TooltipFuncs, nil, nil, nil, nil)
        end
    end,
    OnEnable = function(self)
        if Recount then
            __Score.OvaleScore:RegisterDamageMeter("OvaleRecount", self, "ReceiveScore")
        end
    end,
    OnDisable = function(self)
        __Score.OvaleScore:UnregisterDamageMeter("OvaleRecount")
    end,
    ReceiveScore = function(self, name, guid, scored, scoreMax)
        if Recount then
            local source = Recount.db2.combatants[name]
            if source then
                Recount:AddAmount(source, __Ovale.Ovale:GetName(), scored)
                Recount:AddAmount(source, __Ovale.Ovale:GetName(), scoreMax)
            end
        end
    end,
})
end)
