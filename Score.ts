import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleScore = Ovale.NewModule("OvaleScore", "AceEvent-3.0", "AceSerializer-3.0");
Ovale.OvaleScore = OvaleScore;
import { L } from "./L";
import { OvaleDebug } from "./OvaleDebug";
let OvaleFuture = undefined;
let _pairs = pairs;
let _type = type;
let API_IsInGroup = IsInGroup;
let API_SendAddonMessage = SendAddonMessage;
let API_UnitName = UnitName;
let _LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE;
import { MSG_PREFIX } from "./MSG_PREFIX";
let self_playerGUID = undefined;
let self_name = undefined;
OvaleDebug.RegisterDebugging(OvaleScore);
OvaleScore.damageMeter = {
}
OvaleScore.damageMeterMethod = {
}
OvaleScore.score = 0;
OvaleScore.maxScore = 0;
OvaleScore.scoredSpell = {
}
class OvaleScore {
    OnInitialize() {
        OvaleFuture = Ovale.OvaleFuture;
    }
    OnEnable() {
        self_playerGUID = Ovale.playerGUID;
        self_name = API_UnitName("player");
        this.RegisterEvent("CHAT_MSG_ADDON");
        this.RegisterEvent("PLAYER_REGEN_ENABLED");
        this.RegisterEvent("PLAYER_REGEN_DISABLED");
    }
    OnDisable() {
        this.UnregisterEvent("CHAT_MSG_ADDON");
        this.UnregisterEvent("PLAYER_REGEN_ENABLED");
        this.UnregisterEvent("PLAYER_REGEN_DISABLED");
    }
    CHAT_MSG_ADDON(event, ...__args) {
        let [prefix, message, channel, sender] = __args;
        if (prefix == MSG_PREFIX) {
            let [ok, msgType, scored, scoreMax, guid] = this.Deserialize(message);
            if (ok && msgType == "S") {
                this.SendScore(sender, guid, scored, scoreMax);
            }
        }
    }
    PLAYER_REGEN_ENABLED() {
        if (this.maxScore > 0 && API_IsInGroup()) {
            let message = this.Serialize("score", this.score, this.maxScore, self_playerGUID);
            let channel = API_IsInGroup(_LE_PARTY_CATEGORY_INSTANCE) && "INSTANCE_CHAT" || "RAID";
            API_SendAddonMessage(MSG_PREFIX, message, channel);
        }
    }
    PLAYER_REGEN_DISABLED() {
        this.score = 0;
        this.maxScore = 0;
    }
    RegisterDamageMeter(moduleName, addon, func) {
        if (!func) {
            func = addon;
        } else if (addon) {
            this.damageMeter[moduleName] = addon;
        }
        this.damageMeterMethod[moduleName] = func;
    }
    UnregisterDamageMeter(moduleName) {
        this.damageMeter[moduleName] = undefined;
        this.damageMeterMethod[moduleName] = undefined;
    }
    AddSpell(spellId) {
        this.scoredSpell[spellId] = true;
    }
    ScoreSpell(spellId) {
        if (OvaleFuture.inCombat && this.scoredSpell[spellId]) {
            import { scored } from "./frame";
            this.DebugTimestamp("Scored %s for %d.", scored, spellId);
            if (scored) {
                this.score = this.score + scored;
                this.maxScore = this.maxScore + 1;
                this.SendScore(self_name, self_playerGUID, scored, 1);
            }
        }
    }
    SendScore(name, guid, scored, scoreMax) {
        for (const [moduleName, method] of _pairs(this.damageMeterMethod)) {
            let addon = this.damageMeter[moduleName];
            if (addon) {
                addon[method](addon, name, guid, scored, scoreMax);
            } else if (_type(method) == "function") {
                method(name, guid, scored, scoreMax);
            }
        }
    }
}
