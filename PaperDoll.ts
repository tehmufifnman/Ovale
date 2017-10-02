import { L } from "./Localization";
import { OvaleDebug } from "./Debug";
import { OvaleProfiler } from "./Profiler";
import { Ovale } from "./Ovale";
import { OvaleEquipment } from "./Equipment";
import { OvaleFuture } from "./Future";
import { OvaleStance } from "./Stance";
import { OvaleState } from "./State";

let OvalePaperDollBase = Ovale.NewModule("OvalePaperDoll", "AceEvent-3.0");
export let OvalePaperDoll: OvalePaperDollClass;
let _pairs = pairs;
let _select = select;
let _tonumber = tonumber;
let _type = type;
let API_GetCombatRating = GetCombatRating;
let API_GetCritChance = GetCritChance;
let API_GetMastery = GetMastery;
let API_GetMasteryEffect = GetMasteryEffect;
let API_GetMeleeHaste = GetMeleeHaste;
let API_GetMultistrike = GetMultistrike;
let API_GetMultistrikeEffect = GetMultistrikeEffect;
let API_GetRangedCritChance = GetRangedCritChance;
let API_GetRangedHaste = GetRangedHaste;
let API_GetSpecialization = GetSpecialization;
let API_GetSpellBonusDamage = GetSpellBonusDamage;
let API_GetSpellBonusHealing = GetSpellBonusHealing;
let API_GetSpellCritChance = GetSpellCritChance;
let API_GetTime = GetTime;
let API_UnitAttackPower = UnitAttackPower;
let API_UnitAttackSpeed = UnitAttackSpeed;
let API_UnitDamage = UnitDamage;
let API_UnitLevel = UnitLevel;
let API_UnitRangedAttackPower = UnitRangedAttackPower;
let API_UnitSpellHaste = UnitSpellHaste;
let API_UnitStat = UnitStat;
let _CR_CRIT_MELEE = CR_CRIT_MELEE;
let _CR_HASTE_MELEE = CR_HASTE_MELEE;
let self_playerGUID = undefined;
let OVALE_SPELLDAMAGE_SCHOOL = {
    DEATHKNIGHT: 4,
    DEMONHUNTER: 3,
    DRUID: 4,
    HUNTER: 4,
    MAGE: 5,
    MONK: 4,
    PALADIN: 2,
    PRIEST: 2,
    ROGUE: 4,
    SHAMAN: 4,
    WARLOCK: 6,
    WARRIOR: 4
}
let OVALE_HEALING_CLASS = {
    DRUID: true,
    MONK: true,
    PALADIN: true,
    PRIEST: true,
    SHAMAN: true
}
let OVALE_SPECIALIZATION_NAME = {
    DEATHKNIGHT: {
        1: "blood",
        2: "frost",
        3: "unholy"
    },
    DEMONHUNTER: {
        1: "havoc",
        2: "vengeance"
    },
    DRUID: {
        1: "balance",
        2: "feral",
        3: "guardian",
        4: "restoration"
    },
    HUNTER: {
        1: "beast_mastery",
        2: "marksmanship",
        3: "survival"
    },
    MAGE: {
        1: "arcane",
        2: "fire",
        3: "frost"
    },
    MONK: {
        1: "brewmaster",
        2: "mistweaver",
        3: "windwalker"
    },
    PALADIN: {
        1: "holy",
        2: "protection",
        3: "retribution"
    },
    PRIEST: {
        1: "discipline",
        2: "holy",
        3: "shadow"
    },
    ROGUE: {
        1: "assassination",
        2: "outlaw",
        3: "subtlety"
    },
    SHAMAN: {
        1: "elemental",
        2: "enhancement",
        3: "restoration"
    },
    WARLOCK: {
        1: "affliction",
        2: "demonology",
        3: "destruction"
    },
    WARRIOR: {
        1: "arms",
        2: "fury",
        3: "protection"
    }
}

class OvalePaperDollClass extends OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(OvalePaperDollBase)) {
    class = Ovale.playerClass;
    level = API_UnitLevel("player");
    specialization = undefined;
    STAT_NAME = {
        snapshotTime: true,
        agility: true,
        intellect: true,
        spirit: true,
        stamina: true,
        strength: true,
        attackPower: true,
        rangedAttackPower: true,
        spellBonusDamage: true,
        spellBonusHealing: true,
        masteryEffect: true,
        meleeCrit: true,
        meleeHaste: true,
        rangedCrit: true,
        rangedHaste: true,
        spellCrit: true,
        spellHaste: true,
        multistrike: true,
        critRating: true,
        hasteRating: true,
        masteryRating: true,
        multistrikeRating: true,
        mainHandWeaponDamage: true,
        offHandWeaponDamage: true,
        baseDamageMultiplier: true
    }
    SNAPSHOT_STAT_NAME = {
        snapshotTime: true,
        masteryEffect: true,
        baseDamageMultiplier: true
    }
    snapshotTime = 0;
    agility = 0;
    intellect = 0;
    spirit = 0;
    stamina = 0;
    strength = 0;
    attackPower = 0;
    rangedAttackPower = 0;
    spellBonusDamage = 0;
    spellBonusHealing = 0;
    masteryEffect = 0;
    meleeCrit = 0;
    meleeHaste = 0;
    rangedCrit = 0;
    rangedHaste = 0;
    spellCrit = 0;
    spellHaste = 0;
    multistrike = 0;
    critRating = 0;
    hasteRating = 0;
    masteryRating = 0;
    multistrikeRating = 0;
    mainHandWeaponDamage = 0;
    offHandWeaponDamage = 0;
    baseDamageMultiplier = 1;

    
    OnInitialize() {
    }
    OnEnable() {
        self_playerGUID = Ovale.playerGUID;
        this.RegisterEvent("COMBAT_RATING_UPDATE");
        this.RegisterEvent("MASTERY_UPDATE");
        this.RegisterEvent("MULTISTRIKE_UPDATE");
        this.RegisterEvent("PLAYER_ALIVE", "UpdateStats");
        this.RegisterEvent("PLAYER_DAMAGE_DONE_MODS");
        this.RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateStats");
        this.RegisterEvent("PLAYER_LEVEL_UP");
        this.RegisterEvent("SPELL_POWER_CHANGED");
        this.RegisterEvent("UNIT_ATTACK_POWER");
        this.RegisterEvent("UNIT_DAMAGE", "UpdateDamage");
        this.RegisterEvent("UNIT_LEVEL");
        this.RegisterEvent("UNIT_RANGEDDAMAGE");
        this.RegisterEvent("UNIT_RANGED_ATTACK_POWER");
        this.RegisterEvent("UNIT_SPELL_HASTE");
        this.RegisterEvent("UNIT_STATS");
        this.RegisterMessage("Ovale_EquipmentChanged", "UpdateDamage");
        this.RegisterMessage("Ovale_StanceChanged", "UpdateDamage");
        this.RegisterMessage("Ovale_TalentsChanged", "UpdateStats");
        OvaleFuture.RegisterSpellcastInfo(this);
        OvaleState.RegisterState(this, this.statePrototype);
    }
    OnDisable() {
        OvaleState.UnregisterState(this);
        OvaleFuture.UnregisterSpellcastInfo(this);
        this.UnregisterEvent("COMBAT_RATING_UPDATE");
        this.UnregisterEvent("MASTERY_UPDATE");
        this.UnregisterEvent("MULTISTRIKE_UPDATE");
        this.UnregisterEvent("PLAYER_ALIVE");
        this.UnregisterEvent("PLAYER_DAMAGE_DONE_MODS");
        this.UnregisterEvent("PLAYER_ENTERING_WORLD");
        this.UnregisterEvent("PLAYER_LEVEL_UP");
        this.UnregisterEvent("SPELL_POWER_CHANGED");
        this.UnregisterEvent("UNIT_ATTACK_POWER");
        this.UnregisterEvent("UNIT_DAMAGE");
        this.UnregisterEvent("UNIT_LEVEL");
        this.UnregisterEvent("UNIT_RANGEDDAMAGE");
        this.UnregisterEvent("UNIT_RANGED_ATTACK_POWER");
        this.UnregisterEvent("UNIT_SPELL_HASTE");
        this.UnregisterEvent("UNIT_STATS");
        this.UnregisterMessage("Ovale_EquipmentChanged");
        this.UnregisterMessage("Ovale_StanceChanged");
        this.UnregisterMessage("Ovale_TalentsChanged");
    }
    COMBAT_RATING_UPDATE(event) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.meleeCrit = API_GetCritChance();
        this.rangedCrit = API_GetRangedCritChance();
        this.spellCrit = API_GetSpellCritChance(OVALE_SPELLDAMAGE_SCHOOL[this.class]);
        this.critRating = API_GetCombatRating(_CR_CRIT_MELEE);
        this.hasteRating = API_GetCombatRating(_CR_HASTE_MELEE);
        this.snapshotTime = API_GetTime();
        Ovale.refreshNeeded[self_playerGUID] = true;
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    MASTERY_UPDATE(event) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.masteryRating = API_GetMastery();
        if (this.level < 80) {
            this.masteryEffect = 0;
        } else {
            this.masteryEffect = API_GetMasteryEffect();
            Ovale.refreshNeeded[self_playerGUID] = true;
        }
        this.snapshotTime = API_GetTime();
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    MULTISTRIKE_UPDATE(event) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.multistrikeRating = API_GetMultistrike();
        this.multistrike = API_GetMultistrikeEffect();
        this.snapshotTime = API_GetTime();
        Ovale.refreshNeeded[self_playerGUID] = true;
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    PLAYER_LEVEL_UP(event, level, ...__args) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.level = _tonumber(level) || API_UnitLevel("player");
        this.snapshotTime = API_GetTime();
        Ovale.refreshNeeded[self_playerGUID] = true;
        this.DebugTimestamp("%s: level = %d", event, this.level);
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    PLAYER_DAMAGE_DONE_MODS(event, unitId) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.spellBonusDamage = API_GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[this.class]);
        this.spellBonusHealing = API_GetSpellBonusHealing();
        this.snapshotTime = API_GetTime();
        Ovale.refreshNeeded[self_playerGUID] = true;
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    SPELL_POWER_CHANGED(event) {
        this.StartProfiling("OvalePaperDoll_UpdateStats");
        this.spellBonusDamage = API_GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[this.class]);
        this.spellBonusDamage = API_GetSpellBonusDamage(OVALE_SPELLDAMAGE_SCHOOL[this.class]);
        this.snapshotTime = API_GetTime();
        Ovale.refreshNeeded[self_playerGUID] = true;
        this.StopProfiling("OvalePaperDoll_UpdateStats");
    }
    UNIT_ATTACK_POWER(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            let [base, posBuff, negBuff] = API_UnitAttackPower(unitId);
            this.attackPower = base + posBuff + negBuff;
            this.snapshotTime = API_GetTime();
            Ovale.refreshNeeded[self_playerGUID] = true;
            this.UpdateDamage(event);
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_LEVEL(event, unitId) {
        Ovale.refreshNeeded[unitId] = true;
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            this.level = API_UnitLevel(unitId);
            this.DebugTimestamp("%s: level = %d", event, this.level);
            this.snapshotTime = API_GetTime();
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_RANGEDDAMAGE(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            this.rangedHaste = API_GetRangedHaste();
            this.snapshotTime = API_GetTime();
            Ovale.refreshNeeded[self_playerGUID] = true;
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_RANGED_ATTACK_POWER(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            let [base, posBuff, negBuff] = API_UnitRangedAttackPower(unitId);
            Ovale.refreshNeeded[self_playerGUID] = true;
            this.rangedAttackPower = base + posBuff + negBuff;
            this.snapshotTime = API_GetTime();
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_SPELL_HASTE(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            this.meleeHaste = API_GetMeleeHaste();
            this.spellHaste = API_UnitSpellHaste(unitId);
            this.snapshotTime = API_GetTime();
            Ovale.refreshNeeded[self_playerGUID] = true;
            this.UpdateDamage(event);
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UNIT_STATS(event, unitId) {
        if (unitId == "player") {
            this.StartProfiling("OvalePaperDoll_UpdateStats");
            this.strength = API_UnitStat(unitId, 1);
            this.agility = API_UnitStat(unitId, 2);
            this.stamina = API_UnitStat(unitId, 3);
            this.intellect = API_UnitStat(unitId, 4);
            this.spirit = 0;
            this.snapshotTime = API_GetTime();
            Ovale.refreshNeeded[self_playerGUID] = true;
            this.StopProfiling("OvalePaperDoll_UpdateStats");
        }
    }
    UpdateDamage(event) {
        this.StartProfiling("OvalePaperDoll_UpdateDamage");
        let [minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, _1, _2, damageMultiplier] = API_UnitDamage("player");
        let [mainHandAttackSpeed, offHandAttackSpeed] = API_UnitAttackSpeed("player");
        this.baseDamageMultiplier = damageMultiplier;
        if (this.class == "DRUID" && OvaleStance.IsStance("druid_cat_form")) {
            damageMultiplier = damageMultiplier * 2;
        } else if (this.class == "MONK" && OvaleEquipment.HasOneHandedWeapon()) {
            damageMultiplier = damageMultiplier * 1.25;
        }
        let avgDamage = (minDamage + maxDamage) / 2 / damageMultiplier;
        let mainHandWeaponSpeed = mainHandAttackSpeed * this.GetMeleeHasteMultiplier();
        let normalizedMainHandWeaponSpeed = OvaleEquipment.mainHandWeaponSpeed || 0;
        if (this.class == "DRUID") {
            if (OvaleStance.IsStance("druid_cat_form")) {
                normalizedMainHandWeaponSpeed = 1;
            } else if (OvaleStance.IsStance("druid_bear_form")) {
                normalizedMainHandWeaponSpeed = 2.5;
            }
        }
        this.mainHandWeaponDamage = avgDamage / mainHandWeaponSpeed * normalizedMainHandWeaponSpeed;
        if (OvaleEquipment.HasOffHandWeapon()) {
            let avgOffHandDamage = (minOffHandDamage + maxOffHandDamage) / 2 / damageMultiplier;
            offHandAttackSpeed = offHandAttackSpeed || mainHandAttackSpeed;
            let offHandWeaponSpeed = offHandAttackSpeed * this.GetMeleeHasteMultiplier();
            let normalizedOffHandWeaponSpeed = OvaleEquipment.offHandWeaponSpeed || 0;
            if (this.class == "DRUID") {
                if (OvaleStance.IsStance("druid_cat_form")) {
                    normalizedOffHandWeaponSpeed = 1;
                } else if (OvaleStance.IsStance("druid_bear_form")) {
                    normalizedOffHandWeaponSpeed = 2.5;
                }
            }
            this.offHandWeaponDamage = avgOffHandDamage / offHandWeaponSpeed * normalizedOffHandWeaponSpeed;
        } else {
            this.offHandWeaponDamage = 0;
        }
        this.snapshotTime = API_GetTime();
        Ovale.refreshNeeded[self_playerGUID] = true;
        this.StopProfiling("OvalePaperDoll_UpdateDamage");
    }
    UpdateSpecialization(event) {
        this.StartProfiling("OvalePaperDoll_UpdateSpecialization");
        let newSpecialization = API_GetSpecialization();
        if (this.specialization != newSpecialization) {
            let oldSpecialization = this.specialization;
            this.specialization = newSpecialization;
            this.snapshotTime = API_GetTime();
            Ovale.refreshNeeded[self_playerGUID] = true;
            this.SendMessage("Ovale_SpecializationChanged", this.GetSpecialization(newSpecialization), this.GetSpecialization(oldSpecialization));
        }
        this.StopProfiling("OvalePaperDoll_UpdateSpecialization");
    }
    UpdateStats(event) {
        this.UpdateSpecialization(event);
        this.COMBAT_RATING_UPDATE(event);
        this.MASTERY_UPDATE(event);
        this.PLAYER_DAMAGE_DONE_MODS(event, "player");
        this.SPELL_POWER_CHANGED(event);
        this.UNIT_ATTACK_POWER(event, "player");
        this.UNIT_RANGEDDAMAGE(event, "player");
        this.UNIT_RANGED_ATTACK_POWER(event, "player");
        this.UNIT_SPELL_HASTE(event, "player");
        this.UNIT_STATS(event, "player");
        this.UpdateDamage(event);
    }
    GetSpecialization(specialization?) {
        specialization = specialization || this.specialization;
        return OVALE_SPECIALIZATION_NAME[this.class][specialization];
    }
    IsSpecialization(name) {
        if (name && this.specialization) {
            if (_type(name) == "number") {
                return name == this.specialization;
            } else {
                return name == OVALE_SPECIALIZATION_NAME[this.class][this.specialization];
            }
        }
        return false;
    }
    GetMasteryMultiplier(snapshot) {
        snapshot = snapshot || this;
        return 1 + snapshot.masteryEffect / 100;
    }
    GetMeleeHasteMultiplier(snapshot?) {
        snapshot = snapshot || this;
        return 1 + snapshot.meleeHaste / 100;
    }
    GetRangedHasteMultiplier(snapshot) {
        snapshot = snapshot || this;
        return 1 + snapshot.rangedHaste / 100;
    }
    GetSpellHasteMultiplier(snapshot) {
        snapshot = snapshot || this;
        return 1 + snapshot.spellHaste / 100;
    }
    GetHasteMultiplier(haste, snapshot) {
        snapshot = snapshot || this;
        let multiplier = 1;
        if (haste == "melee") {
            multiplier = this.GetMeleeHasteMultiplier(snapshot);
        } else if (haste == "ranged") {
            multiplier = this.GetRangedHasteMultiplier(snapshot);
        } else if (haste == "spell") {
            multiplier = this.GetSpellHasteMultiplier(snapshot);
        }
        return multiplier;
    }
    UpdateSnapshot(tbl, snapshot, updateAllStats?) {
        if (_type(snapshot) != "table") {
            [snapshot, updateAllStats] = [this, snapshot];
        }
        let nameTable = updateAllStats && OvalePaperDoll.STAT_NAME || OvalePaperDoll.SNAPSHOT_STAT_NAME;
        for (const [k] of _pairs(nameTable)) {
            tbl[k] = snapshot[k];
        }
    }
    CopySpellcastInfo(spellcast, dest) {
        this.UpdateSnapshot(dest, spellcast, true);
    }
    SaveSpellcastInfo(spellcast, atTime, state) {
        let paperDollModule = state || this;
        this.UpdateSnapshot(spellcast, true);
    }
}
OvalePaperDoll.statePrototype = {
}
let statePrototype = OvalePaperDoll.statePrototype;
statePrototype.class = undefined;
statePrototype.level = undefined;
statePrototype.specialization = undefined;
statePrototype.snapshotTime = undefined;
statePrototype.agility = undefined;
statePrototype.intellect = undefined;
statePrototype.spirit = undefined;
statePrototype.stamina = undefined;
statePrototype.strength = undefined;
statePrototype.attackPower = undefined;
statePrototype.rangedAttackPower = undefined;
statePrototype.spellBonusDamage = undefined;
statePrototype.spellBonusHealing = undefined;
statePrototype.masteryEffect = undefined;
statePrototype.meleeCrit = undefined;
statePrototype.meleeHaste = undefined;
statePrototype.rangedCrit = undefined;
statePrototype.rangedHaste = undefined;
statePrototype.spellCrit = undefined;
statePrototype.spellHaste = undefined;
statePrototype.multistrike = undefined;
statePrototype.critRating = undefined;
statePrototype.hasteRating = undefined;
statePrototype.masteryRating = undefined;
statePrototype.multistrikeRating = undefined;
statePrototype.mainHandWeaponDamage = undefined;
statePrototype.offHandWeaponDamage = undefined;
statePrototype.baseDamageMultiplier = undefined;
class OvalePaperDoll {
    InitializeState(state) {
        state.class = undefined;
        state.level = undefined;
        state.specialization = undefined;
        state.snapshotTime = 0;
        state.agility = 0;
        state.intellect = 0;
        state.spirit = 0;
        state.stamina = 0;
        state.strength = 0;
        state.attackPower = 0;
        state.rangedAttackPower = 0;
        state.spellBonusDamage = 0;
        state.spellBonusHealing = 0;
        state.masteryEffect = 0;
        state.meleeCrit = 0;
        state.meleeHaste = 0;
        state.rangedCrit = 0;
        state.rangedHaste = 0;
        state.spellCrit = 0;
        state.spellHaste = 0;
        state.multistrike = 0;
        state.critRating = 0;
        state.hasteRating = 0;
        state.masteryRating = 0;
        state.multistrikeRating = 0;
        state.mainHandWeaponDamage = 0;
        state.offHandWeaponDamage = 0;
        state.baseDamageMultiplier = 1;
    }
    ResetState(state) {
        state.class = this.class;
        state.level = this.level;
        state.specialization = this.specialization;
        this.UpdateSnapshot(state, true);
    }
}
statePrototype.GetMasteryMultiplier = OvalePaperDoll.GetMasteryMultiplier;
statePrototype.GetMeleeHasteMultiplier = OvalePaperDoll.GetMeleeHasteMultiplier;
statePrototype.GetRangedHasteMultiplier = OvalePaperDoll.GetRangedHasteMultiplier;
statePrototype.GetSpellHasteMultiplier = OvalePaperDoll.GetSpellHasteMultiplier;
statePrototype.GetHasteMultiplier = OvalePaperDoll.GetHasteMultiplier;
statePrototype.UpdateSnapshot = OvalePaperDoll.UpdateSnapshot;

OvalePaperDoll = new OvalePaperDollClass();
