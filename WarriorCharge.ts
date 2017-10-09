import { OvaleDebug } from "./Debug";
import { OvaleAura } from "./Aura";
import { Ovale } from "./Ovale";
let OvaleWarriorChargeBase = Ovale.NewModule("OvaleWarriorCharge", "AceEvent-3.0");
export let OvaleWarriorCharge: OvaleWarriorChargeClass;
let API_GetSpellInfo = GetSpellInfo;
let API_GetTime = GetTime;
let INFINITY = math.huge;
let self_playerGUID = undefined;
let CHARGED = 100;
let CHARGED_NAME = "Charged";
let CHARGED_DURATION = INFINITY;
let CHARGED_ATTACKS = {
    [100]: API_GetSpellInfo(100)
}
class OvaleWarriorChargeClass extends OvaleDebug.RegisterDebugging(OvaleWarriorChargeBase) {
    targetGUID = undefined;
    constructor() {
        super();
        if (Ovale.playerClass == "WARRIOR") {
            self_playerGUID = Ovale.playerGUID;
            this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "WARRIOR") {
            this.UnregisterMessage("COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...__args) {
        let [arg12, arg13, , , , , , , , , , , , ] = __args;
        if (sourceGUID == self_playerGUID && cleuEvent == "SPELL_CAST_SUCCESS") {
            let [spellId, spellName] = [arg12, arg13];
            if (CHARGED_ATTACKS[spellId] && destGUID != this.targetGUID) {
                this.Debug("Spell %d (%s) on new target %s.", spellId, spellName, destGUID);
                let now = API_GetTime();
                if (this.targetGUID) {
                    this.Debug("Removing Charged debuff on previous target %s.", this.targetGUID);
                    OvaleAura.LostAuraOnGUID(this.targetGUID, now, CHARGED, self_playerGUID);
                }
                this.Debug("Adding Charged debuff to %s.", destGUID);
                let duration = CHARGED_DURATION;
                let ending = now + CHARGED_DURATION;
                OvaleAura.GainedAuraOnGUID(destGUID, now, CHARGED, self_playerGUID, "HARMFUL", undefined, undefined, 1, undefined, duration, ending, undefined, CHARGED_NAME, undefined, undefined, undefined);
                this.targetGUID = destGUID;
            }
        }
    }
}

OvaleWarriorCharge = new OvaleWarriorChargeClass();