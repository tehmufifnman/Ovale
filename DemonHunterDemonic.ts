import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleDemonHunterDemonic = Ovale.NewModule("OvaleDemonHunterDemonic", "AceEvent-3.0");
Ovale.OvaleDemonHunterDemonic = OvaleDemonHunterDemonic;
let OvaleDebug = undefined;
let OvaleAura = undefined;
let API_GetSpecialization = GetSpecialization;
let API_GetSpecializationInfo = GetSpecializationInfo;
let API_GetTime = GetTime;
let API_GetTalentInfoByID = GetTalentInfoByID;
let INFINITY = math.huge;
let HAVOC_DEMONIC_TALENT_ID = 22547;
let HAVOC_SPEC_ID = 577;
let HAVOC_EYE_BEAM_SPELL_ID = 198013;
let HAVOC_META_BUFF_ID = 162264;
let HIDDEN_BUFF_ID = -HAVOC_DEMONIC_TALENT_ID;
let HIDDEN_BUFF_DURATION = INFINITY;
let HIDDEN_BUFF_EXTENDED_BY_DEMONIC = "Extended by Demonic";
class OvaleDemonHunterDemonic {
    OnInitialize() {
        OvaleAura = Ovale.OvaleAura;
        OvaleDebug = Ovale.OvaleDebug;
        OvaleDebug.RegisterDebugging(OvaleDemonHunterDemonic);
    }
    OnEnable() {
        this.playerGUID = undefined;
        this.isDemonHunter = Ovale.playerClass == "DEMONHUNTER" && true || false;
        this.isHavoc = false;
        this.hasDemonic = false;
        if (this.isDemonHunter) {
            this.Debug("playerGUID: (%s)", Ovale.playerGUID);
            this.playerGUID = Ovale.playerGUID;
            this.RegisterMessage("Ovale_TalentsChanged");
        }
    }
    OnDisable() {
        this.UnregisterMessage("COMBAT_LOG_EVENT_UNFILTERED");
    }
    Ovale_TalentsChanged(event) {
        this.isHavoc = this.isDemonHunter && API_GetSpecializationInfo(API_GetSpecialization()) == HAVOC_SPEC_ID && true || false;
        this.hasDemonic = this.isHavoc && select(10, API_GetTalentInfoByID(HAVOC_DEMONIC_TALENT_ID, HAVOC_SPEC_ID)) && true || false;
        if (this.isHavoc && this.hasDemonic) {
            this.Debug("We are a havoc DH with Demonic.");
            this.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        } else {
            if (!this.isHavoc) {
                this.Debug("We are not a havoc DH.");
            } else if (!this.hasDemonic) {
                this.Debug("We don't have the Demonic talent.");
            }
            this.DropAura();
            this.UnregisterMessage("COMBAT_LOG_EVENT_UNFILTERED");
        }
    }
    COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, cleuEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...__args) {
        let [arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23, arg24, arg25] = __args;
        if (sourceGUID == this.playerGUID && cleuEvent == "SPELL_CAST_SUCCESS") {
            let [spellId, spellName] = [arg12, arg13];
            if (HAVOC_EYE_BEAM_SPELL_ID == spellId) {
                this.Debug("Spell %d (%s) has successfully been cast. Gaining Aura (only during meta).", spellId, spellName);
                this.GainAura();
            }
        }
        if (sourceGUID == this.playerGUID && cleuEvent == "SPELL_AURA_REMOVED") {
            let [spellId, spellName] = [arg12, arg13];
            if (HAVOC_META_BUFF_ID == spellId) {
                this.Debug("Aura %d (%s) is removed. Dropping Aura.", spellId, spellName);
                this.DropAura();
            }
        }
    }
    GainAura() {
        let now = API_GetTime();
        let aura_meta = OvaleAura.GetAura("player", HAVOC_META_BUFF_ID, "HELPFUL", true);
        if (OvaleAura.IsActiveAura(aura_meta, now)) {
            this.Debug("Adding '%s' (%d) buff to player %s.", HIDDEN_BUFF_EXTENDED_BY_DEMONIC, HIDDEN_BUFF_ID, this.playerGUID);
            let duration = HIDDEN_BUFF_DURATION;
            let ending = now + HIDDEN_BUFF_DURATION;
            OvaleAura.GainedAuraOnGUID(this.playerGUID, now, HIDDEN_BUFF_ID, this.playerGUID, "HELPFUL", undefined, undefined, 1, undefined, duration, ending, undefined, HIDDEN_BUFF_EXTENDED_BY_DEMONIC, undefined, undefined, undefined);
        } else {
            this.Debug("Aura 'Metamorphosis' (%d) is not present.", HAVOC_META_BUFF_ID);
        }
    }
    DropAura() {
        let now = API_GetTime();
        this.Debug("Removing '%s' (%d) buff on player %s.", HIDDEN_BUFF_EXTENDED_BY_DEMONIC, HIDDEN_BUFF_ID, this.playerGUID);
        OvaleAura.LostAuraOnGUID(this.playerGUID, now, HIDDEN_BUFF_ID, this.playerGUID);
    }
}
