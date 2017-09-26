import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleEnemies = Ovale.NewModule("OvaleEnemies", "AceEvent-3.0", "AceTimer-3.0");
Ovale.OvaleEnemies = OvaleEnemies;
import { L } from "./L";
import { OvaleDebug } from "./OvaleDebug";
import { OvaleProfiler } from "./OvaleProfiler";
let OvaleGUID = undefined;
let OvaleState = undefined;
let bit_band = bit.band;
let bit_bor = bit.bor;
let _ipairs = ipairs;
let _pairs = pairs;
let strfind = string.find;
let _tostring = tostring;
let _wipe = wipe;
let API_GetTime = GetTime;
let _COMBATLOG_OBJECT_AFFILIATION_MINE = COMBATLOG_OBJECT_AFFILIATION_MINE;
let _COMBATLOG_OBJECT_AFFILIATION_PARTY = COMBATLOG_OBJECT_AFFILIATION_PARTY;
let _COMBATLOG_OBJECT_AFFILIATION_RAID = COMBATLOG_OBJECT_AFFILIATION_RAID;
let _COMBATLOG_OBJECT_REACTION_FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY;
let GROUP_MEMBER = bit_bor(_COMBATLOG_OBJECT_AFFILIATION_MINE, _COMBATLOG_OBJECT_AFFILIATION_PARTY, _COMBATLOG_OBJECT_AFFILIATION_RAID);
OvaleDebug.RegisterDebugging(OvaleEnemies);
OvaleProfiler.RegisterProfiling(OvaleEnemies);
let CLEU_TAG_SUFFIXES = { 1: "_DAMAGE", 2: "_MISSED", 3: "_AURA_APPLIED", 4: "_AURA_APPLIED_DOSE", 5: "_AURA_REFRESH", 6: "_CAST_START", 7: "_INTERRUPT", 8: "_DISPEL", 9: "_DISPEL_FAILED", 10: "_STOLEN", 11: "_DRAIN", 12: "_LEECH" }
let CLEU_AUTOATTACK = { RANGED_DAMAGE: true, RANGED_MISSED: true, SWING_DAMAGE: true, SWING_MISSED: true }
let CLEU_UNIT_REMOVED = { UNIT_DESTROYED: true, UNIT_DIED: true, UNIT_DISSIPATES: true }
let self_playerGUID = undefined;
let self_enemyName = {  }
let self_enemyLastSeen = {  }
let self_taggedEnemyLastSeen = {  }
let self_reaperTimer = undefined;
let REAP_INTERVAL = 3;
OvaleEnemies.activeEnemies = 0;
OvaleEnemies.taggedEnemies = 0;
const IsTagEvent = function(cleuEvent) {
    let isTagEvent = false;
    if (CLEU_AUTOATTACK[cleuEvent]) {
        isTagEvent = true;
    } else {
        for (const [_, suffix] of _ipairs(CLEU_TAG_SUFFIXES)) {
            if (strfind(cleuEvent, suffix + "$")) {
                isTagEvent = true;
                break;
            }
        }
    }
    return isTagEvent;
}
const IsFriendly = function(unitFlags, isGroupMember) {
    return bit_band(unitFlags, _COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 && (!isGroupMember || bit_band(unitFlags, GROUP_MEMBER) > 0);
}
class OvaleEnemies {
    OnInitialize() {
        OvaleGUID = Ovale.OvaleGUID;
        OvaleState = Ovale.OvaleState;
    }
    OnEnable() {
        self_playerGUID = Ovale.playerGUID;
        if (!self_reaperTimer) {
            self_reaperTimer = this.ScheduleRepeatingTimer("RemoveInactiveEnemies", REAP_INTERVAL);
        }
        this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.RegisterEvent("PLAYER_REGEN_DISABLED");
        OvaleState.RegisterState(this, this.statePrototype);
    }
    OnDisable() {
        OvaleState.UnregisterState(this);
        if (!self_reaperTimer) {
            this.CancelTimer(self_reaperTimer);
            self_reaperTimer = undefined;
        }
        this.UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        this.UnregisterEvent("PLAYER_REGEN_DISABLED");
    }
    COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...__args) {
        if (CLEU_UNIT_REMOVED[cleuEvent]) {
            let now = API_GetTime();
            this.RemoveEnemy(cleuEvent, destGUID, now, true);
        } else if (sourceGUID && sourceGUID != "" && sourceName && sourceFlags && destGUID && destGUID != "" && destName && destFlags) {
            if (!IsFriendly(sourceFlags) && IsFriendly(destFlags, true)) {
                if (!cleuEvent == "SPELL_PERIODIC_DAMAGE" && IsTagEvent(cleuEvent)) {
                    let now = API_GetTime();
                    this.AddEnemy(cleuEvent, sourceGUID, sourceName, now);
                }
            } else if (IsFriendly(sourceFlags, true) && !IsFriendly(destFlags) && IsTagEvent(cleuEvent)) {
                let now = API_GetTime();
                let isPlayerTag = (sourceGUID == self_playerGUID) || OvaleGUID.IsPlayerPet(sourceGUID);
                this.AddEnemy(cleuEvent, destGUID, destName, now, isPlayerTag);
            }
        }
    }
    PLAYER_REGEN_DISABLED() {
        _wipe(self_enemyName);
        _wipe(self_enemyLastSeen);
        _wipe(self_taggedEnemyLastSeen);
        this.activeEnemies = 0;
        this.taggedEnemies = 0;
    }
    RemoveInactiveEnemies() {
        this.StartProfiling("OvaleEnemies_RemoveInactiveEnemies");
        let now = API_GetTime();
        for (const [guid, timestamp] of _pairs(self_enemyLastSeen)) {
            if (now - timestamp > REAP_INTERVAL) {
                this.RemoveEnemy("REAPED", guid, now);
            }
        }
        for (const [guid, timestamp] of _pairs(self_taggedEnemyLastSeen)) {
            if (now - timestamp > REAP_INTERVAL) {
                this.RemoveTaggedEnemy("REAPED", guid, now);
            }
        }
        this.StopProfiling("OvaleEnemies_RemoveInactiveEnemies");
    }
    AddEnemy(cleuEvent, guid, name, timestamp, isTagged) {
        this.StartProfiling("OvaleEnemies_AddEnemy");
        if (guid) {
            self_enemyName[guid] = name;
            let changed = false;
            {
                if (!self_enemyLastSeen[guid]) {
                    this.activeEnemies = this.activeEnemies + 1;
                    changed = true;
                }
                self_enemyLastSeen[guid] = timestamp;
            }
            if (isTagged) {
                if (!self_taggedEnemyLastSeen[guid]) {
                    this.taggedEnemies = this.taggedEnemies + 1;
                    changed = true;
                }
                self_taggedEnemyLastSeen[guid] = timestamp;
            }
            if (changed) {
                this.DebugTimestamp("%s: %d/%d enemy seen: %s (%s)", cleuEvent, this.taggedEnemies, this.activeEnemies, guid, name);
                Ovale.refreshNeeded[self_playerGUID] = true;
            }
        }
        this.StopProfiling("OvaleEnemies_AddEnemy");
    }
    RemoveEnemy(cleuEvent, guid, timestamp, isDead) {
        this.StartProfiling("OvaleEnemies_RemoveEnemy");
        if (guid) {
            let name = self_enemyName[guid];
            let changed = false;
            if (self_enemyLastSeen[guid]) {
                self_enemyLastSeen[guid] = undefined;
                if (this.activeEnemies > 0) {
                    this.activeEnemies = this.activeEnemies - 1;
                    changed = true;
                }
            }
            if (self_taggedEnemyLastSeen[guid]) {
                self_taggedEnemyLastSeen[guid] = undefined;
                if (this.taggedEnemies > 0) {
                    this.taggedEnemies = this.taggedEnemies - 1;
                    changed = true;
                }
            }
            if (changed) {
                this.DebugTimestamp("%s: %d/%d enemy %s: %s (%s)", cleuEvent, this.taggedEnemies, this.activeEnemies, isDead && "died" || "removed", guid, name);
                Ovale.refreshNeeded[self_playerGUID] = true;
                this.SendMessage("Ovale_InactiveUnit", guid, isDead);
            }
        }
        this.StopProfiling("OvaleEnemies_RemoveEnemy");
    }
    RemoveTaggedEnemy(cleuEvent, guid, timestamp) {
        this.StartProfiling("OvaleEnemies_RemoveTaggedEnemy");
        if (guid) {
            let name = self_enemyName[guid];
            let tagged = self_taggedEnemyLastSeen[guid];
            if (tagged) {
                self_taggedEnemyLastSeen[guid] = undefined;
                if (this.taggedEnemies > 0) {
                    this.taggedEnemies = this.taggedEnemies - 1;
                }
                this.DebugTimestamp("%s: %d/%d enemy removed: %s (%s), last tagged at %f", cleuEvent, this.taggedEnemies, this.activeEnemies, guid, name, tagged);
                Ovale.refreshNeeded[self_playerGUID] = true;
            }
        }
        this.StopProfiling("OvaleEnemies_RemoveEnemy");
    }
    DebugEnemies() {
        for (const [guid, seen] of _pairs(self_enemyLastSeen)) {
            let name = self_enemyName[guid];
            let tagged = self_taggedEnemyLastSeen[guid];
            if (tagged) {
                this.Print("Tagged enemy %s (%s) last seen at %f", guid, name, tagged);
            } else {
                this.Print("Enemy %s (%s) last seen at %f", guid, name, seen);
            }
        }
        this.Print("Total enemies: %d", this.activeEnemies);
        this.Print("Total tagged enemies: %d", this.taggedEnemies);
    }
}
OvaleEnemies.statePrototype = {  }
let statePrototype = OvaleEnemies.statePrototype;
statePrototype.activeEnemies = undefined;
statePrototype.taggedEnemies = undefined;
statePrototype.enemies = undefined;
class OvaleEnemies {
    InitializeState(state) {
        state.enemies = undefined;
    }
    ResetState(state) {
        this.StartProfiling("OvaleEnemies_ResetState");
        state.activeEnemies = this.activeEnemies;
        state.taggedEnemies = this.taggedEnemies;
        this.StopProfiling("OvaleEnemies_ResetState");
    }
    CleanState(state) {
        state.activeEnemies = undefined;
        state.taggedEnemies = undefined;
        state.enemies = undefined;
    }
}
