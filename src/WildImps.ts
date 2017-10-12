import { OvaleState, StateModule } from "./State";
import { Ovale } from "./Ovale";
import aceEvent from "AceEvent-3.0";

let OvaleWildImpsBase = Ovale.NewModule("OvaleWildImps", aceEvent);
export let OvaleWildImps: OvaleWildImpsClass;
let demonData: LuaArray<{duration: number}> = {
    [55659]: {
        duration: 12
    },
    [98035]: {
        duration: 12
    },
    [103673]: {
        duration: 12
    },
    [11859]: {
        duration: 25
    },
    [89]: {
        duration: 25
    }
}
let self_demons = {
}
let self_serial = 1;
let API_GetTime = GetTime;
const sfind = string.find;
class OvaleWildImpsClass extends OvaleWildImpsBase {
    constructor() {
        super();
        if (Ovale.playerClass == "WARLOCK") {
            this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
            self_demons = {}
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "WARLOCK") {
            this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId: number) {
        self_serial = self_serial + 1;
        Ovale.needRefresh();
        if (sourceGUID != Ovale.playerGUID) {
            return;
        }
        if (cleuEvent == "SPELL_SUMMON") {
            let [,,,, , , , creatureId] = sfind(destGUID, '(%S+)-(%d+)-(%d+)-(%d+)-(%d+)-(%d+)-(%S+)');
            creatureId = tonumber(creatureId);
            let now = API_GetTime();
            for (const [id, v] of pairs(demonData)) {
                if (id == creatureId) {
                    self_demons[destGUID] = {
                        id: creatureId,
                        timestamp: now,
                        finish: now + v.duration
                    }
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
            if (spellId == 193396) {
                for (const [, d] of pairs(self_demons)) {
                    d.de = true;
                }
            }
        }
    }
}

class WildImpsState implements StateModule {
    CleanState(): void {
    }
    InitializeState(): void {
    }
    ResetState(): void {
    }
    GetNotDemonicEmpoweredDemonsCount(creatureId, atTime) {
        let count = 0;
        for (const [, d] of pairs(self_demons)) {
            if (d.finish >= atTime && d.id == creatureId && !d.de) {
                count = count + 1;
            }
        }
        return count;
    }
    GetDemonsCount(creatureId, atTime) {
        let count = 0;
        for (const [, d] of pairs(self_demons)) {
            if (d.finish >= atTime && d.id == creatureId) {
                count = count + 1;
            }
        }
        return count;
    }
    GetRemainingDemonDuration(creatureId, atTime) {
        let max = 0;
        for (const [, d] of pairs(self_demons)) {
            if (d.finish >= atTime && d.id == creatureId) {
                let remaining = d.finish - atTime;
                if (remaining > max) {
                    max = remaining;
                }
            }
        }
        return max;
    }
}

export const wildImpsState = new WildImpsState();
OvaleState.RegisterState(wildImpsState);

OvaleWildImps = new OvaleWildImpsClass();