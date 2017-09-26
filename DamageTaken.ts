import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleDamageTaken = Ovale.NewModule("OvaleDamageTaken", "AceEvent-3.0");
Ovale.OvaleDamageTaken = OvaleDamageTaken;
import { L } from "./L";
import { OvaleDebug } from "./OvaleDebug";
import { OvalePool } from "./OvalePool";
import { OvaleProfiler } from "./OvaleProfiler";
import { OvaleQueue } from "./OvaleQueue";
let bit_band = bit.band;
let bit_bor = bit.bor;
let strsub = string.sub;
let API_GetTime = GetTime;
let _SCHOOL_MASK_ARCANE = SCHOOL_MASK_ARCANE;
let _SCHOOL_MASK_FIRE = SCHOOL_MASK_FIRE;
let _SCHOOL_MASK_FROST = SCHOOL_MASK_FROST;
let _SCHOOL_MASK_HOLY = SCHOOL_MASK_HOLY;
let _SCHOOL_MASK_NATURE = SCHOOL_MASK_NATURE;
let _SCHOOL_MASK_NONE = SCHOOL_MASK_NONE;
let _SCHOOL_MASK_PHYSICAL = SCHOOL_MASK_PHYSICAL;
let _SCHOOL_MASK_SHADOW = SCHOOL_MASK_SHADOW;
OvaleDebug.RegisterDebugging(OvaleDamageTaken);
OvaleProfiler.RegisterProfiling(OvaleDamageTaken);
let self_playerGUID = undefined;
let self_pool = OvalePool("OvaleDamageTaken_pool");
let DAMAGE_TAKEN_WINDOW = 20;
let SCHOOL_MASK_MAGIC = bit_bor(_SCHOOL_MASK_ARCANE, _SCHOOL_MASK_FIRE, _SCHOOL_MASK_FROST, _SCHOOL_MASK_HOLY, _SCHOOL_MASK_NATURE, _SCHOOL_MASK_SHADOW);
OvaleDamageTaken.damageEvent = OvaleQueue.NewDeque("OvaleDamageTaken_damageEvent");
class OvaleDamageTaken {
    OnEnable() {
        self_playerGUID = Ovale.playerGUID;
        this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.RegisterEvent("PLAYER_REGEN_ENABLED");
    }
    OnDisable() {
        this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.UnregisterEvent("PLAYER_REGEN_ENABLED");
        self_pool.Drain();
    }
    COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...__args) {
        let [arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25] = __args;
        if (destGUID == self_playerGUID && strsub(cleuEvent, -7) == "_DAMAGE") {
            this.StartProfiling("OvaleDamageTaken_COMBAT_LOG_EVENT_UNFILTERED");
            let now = API_GetTime();
            let eventPrefix = strsub(cleuEvent, 1, 6);
            if (eventPrefix == "SWING_") {
                let amount = arg12;
                this.Debug("%s caused %d damage.", cleuEvent, amount);
                this.AddDamageTaken(now, amount);
            } else if (eventPrefix == "RANGE_" || eventPrefix == "SPELL_") {
                let [spellName, spellSchool, amount] = [arg13, arg14, arg15];
                let isMagicDamage = (bit_band(spellSchool, SCHOOL_MASK_MAGIC) > 0);
                if (isMagicDamage) {
                    this.Debug("%s (%s) caused %d magic damage.", cleuEvent, spellName, amount);
                } else {
                    this.Debug("%s (%s) caused %d damage.", cleuEvent, spellName, amount);
                }
                this.AddDamageTaken(now, amount, isMagicDamage);
            }
            this.StopProfiling("OvaleDamageTaken_COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    PLAYER_REGEN_ENABLED(event) {
        self_pool.Drain();
    }
    AddDamageTaken(timestamp, damage, isMagicDamage) {
        this.StartProfiling("OvaleDamageTaken_AddDamageTaken");
        let event = self_pool.Get();
        event.timestamp = timestamp;
        event.damage = damage;
        event.magic = isMagicDamage;
        this.damageEvent.InsertFront(event);
        this.RemoveExpiredEvents(timestamp);
        Ovale.refreshNeeded[self_playerGUID] = true;
        this.StopProfiling("OvaleDamageTaken_AddDamageTaken");
    }
    GetRecentDamage(interval) {
        let now = API_GetTime();
        let lowerBound = now - interval;
        this.RemoveExpiredEvents(now);
        let [total, totalMagic] = [0, 0];
        for (const [i, event] of this.damageEvent.FrontToBackIterator()) {
            if (event.timestamp < lowerBound) {
                break;
            }
            total = total + event.damage;
            if (event.magic) {
                totalMagic = totalMagic + event.damage;
            }
        }
        return [total, totalMagic];
    }
    RemoveExpiredEvents(timestamp) {
        this.StartProfiling("OvaleDamageTaken_RemoveExpiredEvents");
        while (true) {
            let event = this.damageEvent.Back();
            if (!event) {
                break;
            }
            if (event) {
                if (timestamp - event.timestamp < DAMAGE_TAKEN_WINDOW) {
                    break;
                }
                this.damageEvent.RemoveBack();
                self_pool.Release(event);
                Ovale.refreshNeeded[self_playerGUID] = true;
            }
        }
        this.StopProfiling("OvaleDamageTaken_RemoveExpiredEvents");
    }
    DebugDamageTaken() {
        this.damageEvent.DebuggingInfo();
        for (const [i, event] of this.damageEvent.BackToFrontIterator()) {
            this.Print("%d: %d damage", event.timestamp, event.damage);
        }
    }
}
