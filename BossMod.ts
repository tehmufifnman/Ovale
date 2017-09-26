import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleBossMod = Ovale.NewModule("OvaleBossMod");
Ovale.OvaleBossMod = OvaleBossMod;
let API_GetNumGroupMembers = GetNumGroupMembers;
let API_IsInGroup = IsInGroup;
let API_IsInInstance = IsInInstance;
let API_IsInRaid = IsInRaid;
let API_UnitExists = UnitExists;
let API_UnitLevel = UnitLevel;
let _BigWigsLoader = BigWigsLoader;
let _DBM = DBM;
import { OvaleDebug } from "./OvaleDebug";
import { OvaleProfiler } from "./OvaleProfiler";
OvaleDebug.RegisterDebugging(OvaleBossMod);
OvaleProfiler.RegisterProfiling(OvaleBossMod);
class OvaleBossMod {
    OnInitialize() {
        OvaleBossMod.EngagedDBM = undefined;
        OvaleBossMod.EngagedBigWigs = undefined;
    }
    OnEnable() {
        if (_DBM) {
            this.Debug("DBM is loaded");
            hooksecurefunc(_DBM, "StartCombat", function (_DBM, mod, delay, event, ...__args) {
                if (event != "TIMER_RECOVERY") {
                    OvaleBossMod.EngagedDBM = mod;
                }
            });
            hooksecurefunc(_DBM, "EndCombat", function (_DBM, mod) {
                OvaleBossMod.EngagedDBM = undefined;
            });
        }
        if (_BigWigsLoader) {
            this.Debug("BigWigs is loaded");
            _BigWigsLoader.RegisterMessage(OvaleBossMod, "BigWigs_OnBossEngage", function (_, mod, diff) {
                OvaleBossMod.EngagedBigWigs = mod;
            });
            _BigWigsLoader.RegisterMessage(OvaleBossMod, "BigWigs_OnBossDisable", function (_, mod) {
                OvaleBossMod.EngagedBigWigs = undefined;
            });
        }
    }
    OnDisable() {
    }
    IsBossEngaged(state) {
        if (!state.inCombat) {
            return false;
        }
        let dbmEngaged = (_DBM != undefined && OvaleBossMod.EngagedDBM != undefined && OvaleBossMod.EngagedDBM.inCombat);
        let bigWigsEngaged = (_BigWigsLoader != undefined && OvaleBossMod.EngagedBigWigs != undefined && OvaleBossMod.EngagedBigWigs.isEngaged);
        let neitherEngaged = (_DBM == undefined && _BigWigsLoader == undefined && OvaleBossMod.ScanTargets());
        if (dbmEngaged) {
            this.Debug("DBM Engaged: [name=%s]", OvaleBossMod.EngagedDBM.localization.general.name);
        }
        if (bigWigsEngaged) {
            this.Debug("BigWigs Engaged: [name=%s]", OvaleBossMod.EngagedBigWigs.displayName);
        }
        return dbmEngaged || bigWigsEngaged || neitherEngaged;
    }
    ScanTargets() {
        this.StartProfiling("OvaleBossMod:ScanTargets");
        const RecursiveScanTargets = function(target, depth) {
            let isWorldBoss = false;
            let dep = depth || 1;
            let isWorldBoss = target != undefined && API_UnitExists(target) && API_UnitLevel(target) < 0;
            if (isWorldBoss) {
                this.Debug("%s is worldboss (%s)", target, UnitName(target));
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
        this.StopProfiling("OvaleBossMod:ScanTargets");
        return bossEngaged;
    }
}
