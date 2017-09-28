import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleBossModBase = Ovale.NewModule("OvaleBossMod");
let API_GetNumGroupMembers = GetNumGroupMembers;
let API_IsInGroup = IsInGroup;
let API_IsInInstance = IsInInstance;
let API_IsInRaid = IsInRaid;
let API_UnitExists = UnitExists;
let API_UnitLevel = UnitLevel;
let _BigWigsLoader = BigWigsLoader;
let _DBM = DBM;
import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
class OvaleBossModClass extends OvaleBossModBase {
    debug = OvaleDebug.RegisterDebugging(this);
    profiler = OvaleProfiler.RegisterProfiling(this);

    EngagedDBM = undefined;
    EngagedBigWigs = undefined;

    OnInitialize() {
    }
    OnEnable() {
        if (_DBM) {
            this.debug.Debug("DBM is loaded");
            hooksecurefunc(_DBM, "StartCombat", (_DBM, mod, delay, event, ...__args) => {
                if (event != "TIMER_RECOVERY") {
                    this.EngagedDBM = mod;
                }
            });
            hooksecurefunc(_DBM, "EndCombat", (_DBM, mod) => {
                this.EngagedDBM = undefined;
            });
        }
        if (_BigWigsLoader) {
            this.debug.Debug("BigWigs is loaded");
            _BigWigsLoader.RegisterMessage(OvaleBossMod, "BigWigs_OnBossEngage", (_, mod, diff) => {
                this.EngagedBigWigs = mod;
            });
            _BigWigsLoader.RegisterMessage(OvaleBossMod, "BigWigs_OnBossDisable", (_, mod) => {
                this.EngagedBigWigs = undefined;
            });
        }
    }
    OnDisable() {
    }
    IsBossEngaged(state) {
        if (!state.inCombat) {
            return false;
        }
        let dbmEngaged = (_DBM != undefined && this.EngagedDBM != undefined && this.EngagedDBM.inCombat);
        let bigWigsEngaged = (_BigWigsLoader != undefined && this.EngagedBigWigs != undefined && this.EngagedBigWigs.isEngaged);
        let neitherEngaged = (_DBM == undefined && _BigWigsLoader == undefined && this.ScanTargets());
        if (dbmEngaged) {
            this.debug.Debug("DBM Engaged: [name=%s]", this.EngagedDBM.localization.general.name);
        }
        if (bigWigsEngaged) {
            this.debug.Debug("BigWigs Engaged: [name=%s]", this.EngagedBigWigs.displayName);
        }
        return dbmEngaged || bigWigsEngaged || neitherEngaged;
    }
    ScanTargets() {
        this.profiler.StartProfiling("OvaleBossMod:ScanTargets");
        const RecursiveScanTargets = (target, depth?) => {
            let isWorldBoss = false;
            let dep = depth || 1;
            isWorldBoss = target != undefined && API_UnitExists(target) && API_UnitLevel(target) < 0;
            if (isWorldBoss) {
                this.debug.Debug("%s is worldboss (%s)", target, UnitName(target));
            }
            return isWorldBoss || (dep <= 3 && RecursiveScanTargets(target + "target", dep + 1));
        }
        let bossEngaged = false;
        bossEngaged = bossEngaged || API_UnitExists("boss1") || API_UnitExists("boss2") || API_UnitExists("boss3") || API_UnitExists("boss4");
        bossEngaged = bossEngaged || RecursiveScanTargets("target") || RecursiveScanTargets("pet") || RecursiveScanTargets("focus") || RecursiveScanTargets("focuspet") || RecursiveScanTargets("mouseover") || RecursiveScanTargets("mouseoverpet");
        if (!bossEngaged) {
            if ((API_IsInInstance() && API_IsInGroup(LE_PARTY_CATEGORY_INSTANCE) && API_GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 1)) {
                for (let i = 1; i <= API_GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE); i += 1) {
                    bossEngaged = bossEngaged || RecursiveScanTargets("party" + i) || RecursiveScanTargets("party" + i + "pet");
                }
            }
            if ((!API_IsInInstance() && API_IsInGroup(LE_PARTY_CATEGORY_HOME) && API_GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 1)) {
                for (let i = 1; i <= API_GetNumGroupMembers(LE_PARTY_CATEGORY_HOME); i += 1) {
                    bossEngaged = bossEngaged || RecursiveScanTargets("party" + i) || RecursiveScanTargets("party" + i + "pet");
                }
            }
            if ((API_IsInInstance() && API_IsInRaid(LE_PARTY_CATEGORY_INSTANCE) && API_GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 1)) {
                for (let i = 1; i <= API_GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE); i += 1) {
                    bossEngaged = bossEngaged || RecursiveScanTargets("raid" + i) || RecursiveScanTargets("raid" + i + "pet");
                }
            }
            if ((!API_IsInInstance() && API_IsInRaid(LE_PARTY_CATEGORY_HOME) && API_GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 1)) {
                for (let i = 1; i <= API_GetNumGroupMembers(LE_PARTY_CATEGORY_HOME); i += 1) {
                    bossEngaged = bossEngaged || RecursiveScanTargets("raid" + i) || RecursiveScanTargets("raid" + i + "pet");
                }
            }
        }
        this.profiler.StopProfiling("OvaleBossMod:ScanTargets");
        return bossEngaged;
    }
}

export const OvaleBossMod = new OvaleBossModClass();