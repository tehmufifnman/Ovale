import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleBanditsGuile = Ovale.NewModule("OvaleBanditsGuile", "AceEvent-3.0");
Ovale.OvaleBanditsGuile = OvaleBanditsGuile;
import { OvaleDebug } from "./OvaleDebug";
let OvaleAura = undefined;
let API_GetSpellInfo = GetSpellInfo;
let API_GetTime = GetTime;
OvaleDebug.RegisterDebugging(OvaleBanditsGuile);
let self_playerGUID = undefined;
let SHALLOW_INSIGHT = 84745;
let MODERATE_INSIGHT = 84746;
let DEEP_INSIGHT = 84747;
let INSIGHT_BUFF = {
    [SHALLOW_INSIGHT]: API_GetSpellInfo(SHALLOW_INSIGHT),
    [MODERATE_INSIGHT]: API_GetSpellInfo(MODERATE_INSIGHT),
    [DEEP_INSIGHT]: API_GetSpellInfo(DEEP_INSIGHT)
}
let BANDITS_GUILE = 84654;
let BANDITS_GUILE_ATTACK = {
    [1752]: API_GetSpellInfo(1752)
}
OvaleBanditsGuile.spellName = "Bandit's Guile";
OvaleBanditsGuile.spellId = BANDITS_GUILE;
OvaleBanditsGuile.start = 0;
OvaleBanditsGuile.ending = 0;
OvaleBanditsGuile.duration = 15;
OvaleBanditsGuile.stacks = 0;
class OvaleBanditsGuile {
    OnInitialize() {
        OvaleAura = Ovale.OvaleAura;
    }
    OnEnable() {
        if (Ovale.playerClass == "ROGUE") {
            self_playerGUID = Ovale.playerGUID;
            this.RegisterMessage("Ovale_SpecializationChanged");
        }
    }
    OnDisable() {
        if (Ovale.playerClass == "ROGUE") {
            this.UnregisterMessage("Ovale_SpecializationChanged");
        }
    }
    Ovale_SpecializationChanged(event, specialization, previousSpecialization) {
        this.Debug(event, specialization, previousSpecialization);
        if (specialization == "combat") {
            this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
            this.RegisterMessage("Ovale_AuraAdded");
            this.RegisterMessage("Ovale_AuraChanged");
            this.RegisterMessage("Ovale_AuraRemoved");
        } else {
            this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
            this.UnregisterMessage("Ovale_AuraAdded");
            this.UnregisterMessage("Ovale_AuraChanged");
            this.UnregisterMessage("Ovale_AuraRemoved");
        }
    }
    COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...__args) {
        let [arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25] = __args;
        if (sourceGUID == self_playerGUID && cleuEvent == "SPELL_DAMAGE") {
            let [spellId, spellName, multistrike] = [arg12, arg13, arg25];
            if (BANDITS_GUILE_ATTACK[spellId] && !multistrike) {
                let now = API_GetTime();
                if (this.ending < now) {
                    this.stacks = 0;
                }
                if (this.stacks < 3) {
                    this.start = now;
                    this.ending = this.start + this.duration;
                    this.stacks = this.stacks + 1;
                    this.Debug(cleuEvent, spellName, spellId, this.stacks);
                    this.GainedAura(now);
                }
            }
        }
    }
    Ovale_AuraAdded(event, timestamp, target, auraId, caster) {
        if (target == self_playerGUID) {
            let auraName = INSIGHT_BUFF[auraId];
            if (auraName) {
                let aura = OvaleAura.GetAura("player", auraId, "HELPFUL", true);
                [this.start, this.ending] = [aura.start, aura.ending];
                if (auraId == SHALLOW_INSIGHT) {
                    this.stacks = 4;
                } else if (auraId == MODERATE_INSIGHT) {
                    this.stacks = 8;
                } else if (auraId == DEEP_INSIGHT) {
                    this.stacks = 12;
                }
                this.Debug(event, auraName, this.stacks);
                this.GainedAura(timestamp);
            }
        }
    }
    Ovale_AuraChanged(event, timestamp, target, auraId, caster) {
        if (target == self_playerGUID) {
            let auraName = INSIGHT_BUFF[auraId];
            if (auraName) {
                let aura = OvaleAura.GetAura("player", auraId, "HELPFUL", true);
                [this.start, this.ending] = [aura.start, aura.ending];
                this.stacks = this.stacks + 1;
                this.Debug(event, auraName, this.stacks);
                this.GainedAura(timestamp);
            }
        }
    }
    Ovale_AuraRemoved(event, timestamp, target, auraId, caster) {
        if (target == self_playerGUID) {
            if (((auraId == SHALLOW_INSIGHT && this.stacks < 8) || (auraId == MODERATE_INSIGHT && this.stacks < 12) || auraId == DEEP_INSIGHT) && timestamp < this.ending) {
                this.ending = timestamp;
                this.stacks = 0;
                this.Debug(event, INSIGHT_BUFF[auraId], this.stacks);
                OvaleAura.LostAuraOnGUID(self_playerGUID, timestamp, this.spellId, self_playerGUID);
            }
        }
    }
    GainedAura(atTime) {
        OvaleAura.GainedAuraOnGUID(self_playerGUID, atTime, this.spellId, self_playerGUID, "HELPFUL", undefined, undefined, this.stacks, undefined, this.duration, this.ending, undefined, this.spellName, undefined, undefined, undefined);
    }
    DebugBanditsGuile() {
        let aura = OvaleAura.GetAuraByGUID(self_playerGUID, this.spellId, "HELPFUL", true);
        if (aura) {
            this.Print("Player has Bandit's Guile aura with start=%s, end=%s, stacks=%d.", aura.start, aura.ending, aura.stacks);
        }
    }
}
