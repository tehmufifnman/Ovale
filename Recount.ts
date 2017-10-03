import { Ovale } from "./Ovale";
import { L } from "./Localization";
import { OvaleScore } from "./Score";
import AceLocale from "AceLocale-3.0";
import Recount from "Recount";

let OvaleRecountBase = Ovale.NewModule("OvaleRecount");
export let OvaleRecount: OvaleRecountClass;
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
    let SortedData, total;
    GameTooltip.ClearLines();
    GameTooltip.AddLine(name);
}
class OvaleRecountClass extends OvaleRecountBase {
    OnInitialize() {
        if (Recount) {
            let aceLocale = AceLocale && AceLocale.GetLocale("Recount", true);
            if (!aceLocale) {
                aceLocale = _setmetatable<LuaObj<string>>({}, {
                    __index: function (t, k) {
                        t[k] = k;
                        return k;
                    }
                });
            }
            Recount.AddModeTooltip(Ovale.GetName(), DataModes, TooltipFuncs, undefined, undefined, undefined, undefined);
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
                Recount.AddAmount(source, Ovale.GetName(), scored);
                Recount.AddAmount(source, `${Ovale.GetName()}Max`, scoreMax);
            }
        }
    }
}
