import { L } from "./Localization";
import { OvaleDebug } from "./Debug";
import { OvaleOptions } from "./Options";
import { Ovale } from "./Ovale";

let OvaleVersionBase = Ovale.NewModule("OvaleVersion", "AceComm-3.0", "AceSerializer-3.0", "AceTimer-3.0");
export let OvaleVersion: OvaleVersionClass;
let format = string.format;
let _ipairs = ipairs;
let _next = next;
let _pairs = pairs;
let tinsert = table.insert;
let tsort = table.sort;
let _wipe = wipe;
let API_IsInGroup = IsInGroup;
let API_IsInGuild = IsInGuild;
let API_IsInRaid = IsInRaid;
let _LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE;
let self_printTable = {
}
let self_userVersion = {
}
let self_timer;
let MSG_PREFIX = Ovale.MSG_PREFIX;
let OVALE_VERSION = "@project-version@";
let REPOSITORY_KEYWORD = `@${"project-version"}@`;
{
    let actions = {
        ping: {
            name: L["Ping for Ovale users in group"],
            type: "execute",
            func: function () {
                OvaleVersion.VersionCheck();
            }
        },
        version: {
            name: L["Show version number"],
            type: "execute",
            func: function () {
                OvaleVersion.Print(OvaleVersion.version);
            }
        }
    }
    for (const [k, v] of _pairs(actions)) {
        OvaleOptions.options.args.actions.args[k] = v;
    }
    OvaleOptions.RegisterOptions(OvaleVersion);
}
class OvaleVersionClass extends OvaleDebug.RegisterDebugging(OvaleVersionBase) {
    version = (OVALE_VERSION == REPOSITORY_KEYWORD) && "development version" || OVALE_VERSION;
    warned = false;
    
    constructor() {
        super();
        this.RegisterComm(MSG_PREFIX);
    }
    OnCommReceived(prefix, message, channel, sender) {
        if (prefix == MSG_PREFIX) {
            let [ok, msgType, version] = this.Deserialize(message);
            if (ok) {
                this.Debug(msgType, version, channel, sender);
                if (msgType == "V") {
                    let msg = this.Serialize("VR", this.version);
                    this.SendCommMessage(MSG_PREFIX, msg, channel);
                } else if (msgType == "VR") {
                    self_userVersion[sender] = version;
                }
            }
        }
    }
    VersionCheck() {
        if (!self_timer) {
            _wipe(self_userVersion);
            let message = this.Serialize("V", this.version);
            let channel;
            if (API_IsInGroup(_LE_PARTY_CATEGORY_INSTANCE)) {
                channel = "INSTANCE_CHAT";
            } else if (API_IsInRaid()) {
                channel = "RAID";
            } else if (API_IsInGroup()) {
                channel = "PARTY";
            } else if (API_IsInGuild()) {
                channel = "GUILD";
            }
            if (channel) {
                this.SendCommMessage(MSG_PREFIX, message, channel);
            }
            self_timer = this.ScheduleTimer("PrintVersionCheck", 3);
        }
    }
    PrintVersionCheck() {
        if (_next(self_userVersion)) {
            _wipe(self_printTable);
            for (const [sender, version] of _pairs(self_userVersion)) {
                tinsert(self_printTable, format(">>> %s is using Ovale %s", sender, version));
            }
            tsort(self_printTable);
            for (const [, v] of _ipairs(self_printTable)) {
                this.Print(v);
            }
        } else {
            this.Print(">>> No other Ovale users present.");
        }
        self_timer = undefined;
    }
}

OvaleVersion =new OvaleVersionClass();