import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { OvaleData } from "./Data";
import { OvaleGUID } from "./GUID";
import { OvaleState, baseState, StateModule } from "./State";

let OvaleHealthBase = Ovale.NewModule("OvaleHealth", "AceEvent-3.0");
export let OvaleHealth: OvaleHealthClass;

let strsub = string.sub;
let _tonumber = tonumber;
let _wipe = wipe;
let API_GetTime = GetTime;
let API_UnitHealth = UnitHealth;
let API_UnitHealthMax = UnitHealthMax;
let INFINITY = math.huge;
let CLEU_DAMAGE_EVENT = {
    DAMAGE_SHIELD: true,
    DAMAGE_SPLIT: true,
    RANGE_DAMAGE: true,
    SPELL_BUILDING_DAMAGE: true,
    SPELL_DAMAGE: true,
    SPELL_PERIODIC_DAMAGE: true,
    SWING_DAMAGE: true,
    ENVIRONMENTAL_DAMAGE: true
}
let CLEU_HEAL_EVENT = {
    SPELL_HEAL: true,
    SPELL_PERIODIC_HEAL: true
}

class OvaleHealthClass extends OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(OvaleHealthBase)) {
    health = {    }
    maxHealth = {    }
    totalDamage = {    }
    totalHealing = {    }
    firstSeen = {    }
    lastUpdated = {    }

    OnInitialize() {
    }
    OnEnable() {
        this.RegisterEvent("PLAYER_REGEN_DISABLED");
        this.RegisterEvent("PLAYER_REGEN_ENABLED");
        this.RegisterEvent("UNIT_HEALTH_FREQUENT", "UpdateHealth");
        this.RegisterEvent("UNIT_MAXHEALTH", "UpdateHealth");
        this.RegisterMessage("Ovale_UnitChanged");
        OvaleData.RegisterRequirement("health_pct", "RequireHealthPercentHandler", this);
        OvaleData.RegisterRequirement("pet_health_pct", "RequireHealthPercentHandler", this);
        OvaleData.RegisterRequirement("target_health_pct", "RequireHealthPercentHandler", this);
    }
    OnDisable() {
        OvaleData.UnregisterRequirement("health_pct");
        OvaleData.UnregisterRequirement("pet_health_pct");
        OvaleData.UnregisterRequirement("target_health_pct");
        this.UnregisterEvent("PLAYER_REGEN_ENABLED");
        this.UnregisterEvent("PLAYER_TARGET_CHANGED");
        this.UnregisterEvent("UNIT_HEALTH_FREQUENT");
        this.UnregisterEvent("UNIT_MAXHEALTH");
        this.UnregisterMessage("Ovale_UnitChanged");
    }
    COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...__args) {
        let [arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25] = __args;
        this.StartProfiling("OvaleHealth_COMBAT_LOG_EVENT_UNFILTERED");
        let healthUpdate = false;
        if (CLEU_DAMAGE_EVENT[cleuEvent]) {
            let amount;
            if (cleuEvent == "SWING_DAMAGE") {
                amount = arg12;
            } else if (cleuEvent == "ENVIRONMENTAL_DAMAGE") {
                amount = arg13;
            } else {
                amount = arg15;
            }
            this.Debug(cleuEvent, destGUID, amount);
            let total = this.totalDamage[destGUID] || 0;
            this.totalDamage[destGUID] = total + amount;
            healthUpdate = true;
        } else if (CLEU_HEAL_EVENT[cleuEvent]) {
            let amount = arg15;
            this.Debug(cleuEvent, destGUID, amount);
            let total = this.totalHealing[destGUID] || 0;
            this.totalHealing[destGUID] = total + amount;
            healthUpdate = true;
        }
        if (healthUpdate) {
            if (!this.firstSeen[destGUID]) {
                this.firstSeen[destGUID] = timestamp;
            }
            this.lastUpdated[destGUID] = timestamp;
        }
        this.StopProfiling("OvaleHealth_COMBAT_LOG_EVENT_UNFILTERED");
    }
    PLAYER_REGEN_DISABLED(event) {
        this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    }
    PLAYER_REGEN_ENABLED(event) {
        this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        _wipe(this.totalDamage);
        _wipe(this.totalHealing);
        _wipe(this.firstSeen);
        _wipe(this.lastUpdated);
    }
    Ovale_UnitChanged(event, unitId, guid) {
        this.StartProfiling("Ovale_UnitChanged");
        if (unitId == "target" || unitId == "focus") {
            this.Debug(event, unitId, guid);
            this.UpdateHealth("UNIT_HEALTH_FREQUENT", unitId);
            this.UpdateHealth("UNIT_MAXHEALTH", unitId);
            this.StopProfiling("Ovale_UnitChanged");
        }
    }
    UpdateHealth(event, unitId) {
        if (!unitId) {
            return;
        }
        this.StartProfiling("OvaleHealth_UpdateHealth");
        let func = API_UnitHealth;
        let db = this.health;
        if (event == "UNIT_MAXHEALTH") {
            func = API_UnitHealthMax;
            db = this.maxHealth;
        }
        let amount = func(unitId);
        if (amount) {
            let guid = OvaleGUID.UnitGUID(unitId);
            this.Debug(event, unitId, guid, amount);
            if (guid) {
                if (amount > 0) {
                    db[guid] = amount;
                } else {
                    db[guid] = undefined;
                    this.firstSeen[guid] = undefined;
                    this.lastUpdated[guid] = undefined;
                }
                Ovale.refreshNeeded[guid] = true;
            }
        }
        this.StopProfiling("OvaleHealth_UpdateHealth");
    }
    UnitHealth(unitId: string, guid?: string) {
        let amount;
        if (unitId) {
            guid = guid || OvaleGUID.UnitGUID(unitId);
            if (guid) {
                if (unitId == "target" || unitId == "focus") {
                    amount = this.health[guid] || 0;
                } else {
                    amount = API_UnitHealth(unitId);
                    this.health[guid] = amount;
                }
            } else {
                amount = 0;
            }
        }
        return amount;
    }
    UnitHealthMax(unitId: string, guid?:string) {
        let amount;
        if (unitId) {
            guid = guid || OvaleGUID.UnitGUID(unitId);
            if (guid) {
                if (unitId == "target" || unitId == "focus") {
                    amount = this.maxHealth[guid] || 0;
                } else {
                    amount = API_UnitHealthMax(unitId);
                    this.maxHealth[guid] = amount;
                }
            } else {
                amount = 0;
            }
        }
        return amount;
    }
    UnitTimeToDie(unitId: string, guid?: string) {
        this.StartProfiling("OvaleHealth_UnitTimeToDie");
        let timeToDie = INFINITY;
        guid = guid || OvaleGUID.UnitGUID(unitId);
        if (guid) {
            let health = this.UnitHealth(unitId, guid);
            let maxHealth = this.UnitHealthMax(unitId, guid);
            if (health && maxHealth) {
                if (health == 0) {
                    timeToDie = 0;
                    this.firstSeen[guid] = undefined;
                    this.lastUpdated[guid] = undefined;
                } else if (maxHealth > 5) {
                    let [firstSeen, lastUpdated] = [this.firstSeen[guid], this.lastUpdated[guid]];
                    let damage = this.totalDamage[guid] || 0;
                    let healing = this.totalHealing[guid] || 0;
                    if (firstSeen && lastUpdated && lastUpdated > firstSeen && damage > healing) {
                        timeToDie = health * (lastUpdated - firstSeen) / (damage - healing);
                    }
                }
            }
        }
        this.StopProfiling("OvaleHealth_UnitTimeToDie");
        return timeToDie;
    }
    RequireHealthPercentHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        let verified = false;
        let threshold = tokens;
        if (index) {
            threshold = tokens[index];
            index = index + 1;
        }
        if (threshold) {
            let isBang = false;
            if (strsub(threshold, 1, 1) == "!") {
                isBang = true;
                threshold = strsub(threshold, 2);
            }
            threshold = _tonumber(threshold) || 0;
            let guid, unitId;
            if (strsub(requirement, 1, 7) == "target_") {
                if (targetGUID) {
                    guid = targetGUID;
                    unitId = OvaleGUID.GUIDUnit(guid);
                } else {
                    unitId = baseState.defaultTarget || "target";
                }
            } else if (strsub(requirement, 1, 4) == "pet_") {
                unitId = "pet";
            } else {
                unitId = "player";
            }
            guid = guid || OvaleGUID.UnitGUID(unitId);
            let health = OvaleHealth.UnitHealth(unitId, guid) || 0;
            let maxHealth = OvaleHealth.UnitHealthMax(unitId, guid) || 0;
            let healthPercent = (maxHealth > 0) && (health / maxHealth * 100) || 100;
            if (!isBang && healthPercent <= threshold || isBang && healthPercent > threshold) {
                verified = true;
            }
            let result = verified && "passed" || "FAILED";
            if (isBang) {
                this.Log("    Require %s health > %f%% (%f) at time=%f: %s", unitId, threshold, healthPercent, atTime, result);
            } else {
                this.Log("    Require %s health <= %f%% (%f) at time=%f: %s", unitId, threshold, healthPercent, atTime, result);
            }
        } else {
            Ovale.OneTimeMessage("Warning: requirement '%s' is missing a threshold argument.", requirement);
        }
        return [verified, requirement, index];
    }
}

class HealthState implements StateModule{
    CleanState(): void {
    }
    InitializeState(): void {
    }
    ResetState(): void {
    }
    RequireHealthPercentHandler(spellId, atTime, requirement, tokens, index, targetGUID) {
        return OvaleHealth.RequireHealthPercentHandler(spellId, atTime, requirement, tokens, index, targetGUID);
    }
}

export const healthState = new HealthState();
OvaleState.RegisterState(healthState);

OvaleHealth = new OvaleHealthClass();