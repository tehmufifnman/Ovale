import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleVersion = Ovale.NewModule("OvaleVersion", "AceComm-3.0", "AceSerializer-3.0", "AceTimer-3.0");
Ovale.OvaleVersion = OvaleVersion;
import { L } from "./L";
import { OvaleDebug } from "./OvaleDebug";
import { OvaleOptions } from "./OvaleOptions";
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
OvaleDebug.RegisterDebugging(OvaleVersion);
let self_printTable = {  }
let self_userVersion = {  }
let self_timer;
import { MSG_PREFIX } from "./MSG_PREFIX";
let OVALE_VERSION = "7.3.0.2";
let REPOSITORY_KEYWORD = "@" + "project-version" + "@";
{
    let actions = { ping: { name: L["Ping for Ovale users in group"], type: "execute", func: function () {
        OvaleVersion.VersionCheck();
    } }, version: { name: L["Show version number"], type: "execute", func: function () {
        OvaleVersion.Print(OvaleVersion.version);
    } } }
    for (const [k, v] of _pairs(actions)) {
        OvaleOptions.options.args.actions.args[k] = v;
    }
    OvaleOptions.RegisterOptions(OvaleVersion);
}
OvaleVersion.version = (OVALE_VERSION == REPOSITORY_KEYWORD) && "development version" || OVALE_VERSION;
OvaleVersion.warned = false;
class OvaleVersion {
    OnEnable() {
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
            for (const [_, v] of _ipairs(self_printTable)) {
                this.Print(v);
            }
        } else {
            this.Print(">>> No other Ovale users present.");
        }
        self_timer = undefined;
    }
}
