import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleWildImps = Ovale.NewModule("OvaleWildImps", "AceEvent-3.0");
Ovale.OvaleWildImps = OvaleWildImps;
let OvaleState = undefined;
let tinsert = table.insert;
let tremove = table.remove;
let demonData = { [55659]: { duration: 12 }, [98035]: { duration: 12 }, [103673]: { duration: 12 }, [11859]: { duration: 25 }, [89]: { duration: 25 } }
let self_demons = {  }
let self_serial = 1;
let API_GetTime = GetTime;
class OvaleWildImps {
    OnInitialize() {
        OvaleState = Ovale.OvaleState;
    }
    OnEnable() {
        if (Ovale.playerClass == "WARLOCK") {
            this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
            OvaleState.RegisterState(this, this.statePrototype);
            self_demons = {  }
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "WARLOCK") {
            OvaleState.UnregisterState(this);
            this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...__args) {
        self_serial = self_serial + 1;
        Ovale.refreshNeeded[Ovale.playerGUID] = true;
        if (sourceGUID != Ovale.playerGUID) {
            break;
        }
        if (cleuEvent == "SPELL_SUMMON") {
            let [_, _, _, _, _, _, _, creatureId] = destGUID.find('(%S+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)-(%S+)');
            creatureId = tonumber(creatureId);
            let now = API_GetTime();
            for (const [id, v] of pairs(demonData)) {
                if (id == creatureId) {
                    self_demons[destGUID] = { id: creatureId, timestamp: now, finish: now + v.duration }
                    break;
                }
            }
            for (const [k, d] of pairs(self_demons)) {
                if (d.finish < now) {
                    self_demons[k] = undefined;
                }
            }
        } else if (cleuEvent == 'SPELL_INSTAKILL') {
            if (spellId == 196278) {
                self_demons[destGUID] = undefined;
            }
        } else if (cleuEvent == 'SPELL_CAST_SUCCESS') {
            let spellId = __args;
            if (spellId == 193396) {
                for (const [k, d] of pairs(self_demons)) {
                    d.de = true;
                }
            }
        }
    }
}
OvaleWildImps.statePrototype = {  }
let statePrototype = OvaleWildImps.statePrototype;
statePrototype.GetNotDemonicEmpoweredDemonsCount = function (state, creatureId, atTime) {
    let count = 0;
    for (const [k, d] of pairs(self_demons)) {
        if (d.finish >= atTime && d.id == creatureId && !d.de) {
            count = count + 1;
        }
    }
    return count;
}
statePrototype.GetDemonsCount = function (state, creatureId, atTime) {
    let count = 0;
    for (const [k, d] of pairs(self_demons)) {
        if (d.finish >= atTime && d.id == creatureId) {
            count = count + 1;
        }
    }
    return count;
}
statePrototype.GetRemainingDemonDuration = function (state, creatureId, atTime) {
    let max = 0;
    for (const [k, d] of pairs(self_demons)) {
        if (d.finish >= atTime && d.id == creatureId) {
            let remaining = d.finish - atTime;
            if (remaining > max) {
                max = remaining;
            }
        }
    }
    return max;
}
