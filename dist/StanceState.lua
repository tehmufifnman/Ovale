local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./StanceState", { "./State", "./Stance", "./DataState" }, function(__exports, __State, __Stance, __DataState)
local _type = type
local StanceState = __class(nil, {
    InitializeState = function(self)
        self.stance = nil
    end,
    CleanState = function(self)
    end,
    ResetState = function(self)
        __Stance.OvaleStance:StartProfiling("OvaleStance_ResetState")
        self.stance = __Stance.OvaleStance.stance or 0
        __Stance.OvaleStance:StopProfiling("OvaleStance_ResetState")
    end,
    ApplySpellAfterCast = function(self, spellId, targetGUID, startCast, endCast, isChanneled, spellcast)
        __Stance.OvaleStance:StartProfiling("OvaleStance_ApplySpellAfterCast")
        local stance = __DataState.dataState:GetSpellInfoProperty(spellId, endCast, "to_stance", targetGUID)
        if stance then
            if _type(stance) == "string" then
                stance = __Stance.OvaleStance.stanceId[stance]
            end
            self.stance = stance
        end
        __Stance.OvaleStance:StopProfiling("OvaleStance_ApplySpellAfterCast")
    end,
    IsStance = function(self, name)
        return __Stance.OvaleStance:IsStance(name)
    end,
    RequireStanceHandler = function(self, spellId, atTime, requirement, tokens, index, targetGUID)
        return __Stance.OvaleStance:RequireStanceHandler(spellId, atTime, requirement, tokens, index, targetGUID)
    end,
    constructor = function(self)
        self.stance = nil
    end
})
__exports.stanceState = StanceState()
__State.OvaleState:RegisterState(__exports.stanceState)
end)
