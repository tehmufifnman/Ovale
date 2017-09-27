import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleRecount = Ovale.NewModule("OvaleRecount");
Ovale.OvaleRecount = OvaleRecount;
let L = undefined;
let OvaleScore = undefined;
let Recount = LibStub("AceAddon-3.0").GetAddon("Recount", true);
let _setmetatable = setmetatable;
const DataModes = function(self, data, num) {
    if (!data) {
        return [0, 0];
    }
    let fight = data.Fights[Recount.db.profile.CurDataSet];
    let score;
    if (fight && fight.Ovale && fight.OvaleMax) {
        score = fight.Ovale * 1000 / fight.OvaleMax;
    } else {
        score = 0;
    }
    if (num == 1) {
        return score;
    }
    return [score, undefined];
}
const TooltipFuncs = function(self, name, data) {
    let [SortedData, total];
    GameTooltip.ClearLines();
    GameTooltip.AddLine(name);
}
class OvaleRecount {
    OnInitialize() {
        OvaleScore = Ovale.OvaleScore;
        if (Recount) {
            let AceLocale = LibStub("AceLocale-3.0", true);
            let L = AceLocale && AceLocale.GetLocale("Recount", true);
            if (!L) {
                L = _setmetatable({
                }, {
                    __index: function (t, k) {
                        t[k] = k;
                        return k;
                    }
                });
            }
            Recount.AddModeTooltip(OVALE, DataModes, TooltipFuncs, undefined, undefined, undefined, undefined);
        }
    }
    OnEnable() {
        if (Recount) {
            OvaleScore.RegisterDamageMeter("OvaleRecount", this, "ReceiveScore");
        }
    }
    OnDisable() {
        OvaleScore.UnregisterDamageMeter("OvaleRecount");
    }
    ReceiveScore(name, guid, scored, scoreMax) {
        if (Recount) {
            let source = Recount.db2.combatants[name];
            if (source) {
                Recount.AddAmount(source, OVALE, scored);
                Recount.AddAmount(source, OVALE + "Max", scoreMax);
            }
        }
    }
}
