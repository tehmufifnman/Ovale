import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleSpellDamage = Ovale.NewModule("OvaleSpellDamage", "AceEvent-3.0");
Ovale.OvaleSpellDamage = OvaleSpellDamage;
import { OvaleProfiler } from "./OvaleProfiler";
OvaleProfiler.RegisterProfiling(OvaleSpellDamage);
let CLEU_DAMAGE_EVENT = {
    SPELL_DAMAGE: true,
    SPELL_PERIODIC_AURA: true
}
let self_playerGUID = undefined;
OvaleSpellDamage.value = {
}
class OvaleSpellDamage {
    OnEnable() {
        self_playerGUID = Ovale.playerGUID;
        this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    }
    OnDisable() {
        this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    }
    COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...__args) {
        let [arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25] = __args;
        if (sourceGUID == self_playerGUID) {
            this.StartProfiling("OvaleSpellDamage_COMBAT_LOG_EVENT_UNFILTERED");
            if (CLEU_DAMAGE_EVENT[cleuEvent]) {
                let [spellId, amount] = [arg12, arg15];
                this.value[spellId] = amount;
                Ovale.refreshNeeded[self_playerGUID] = true;
            }
            this.StopProfiling("OvaleSpellDamage_COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    Get(spellId) {
        return this.value[spellId];
    }
}
