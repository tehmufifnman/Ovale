local __exports = LibStub:NewLibrary("ovale/scripts/ovale_rogue_spells", 80000)
if not __exports then return end
local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
__exports.register = function()
    local name = "ovale_rogue_spells"
    local desc = "[7.0] Ovale: Rogue spells"
    local code = [[
# Rogue spells and functions.

# Aliases
SpellList(lethal_poison_buff deadly_poison_buff wound_poison_buff)
SpellList(non_lethal_poison_buff crippling_poison_buff leeching_poison_buff)
SpellList(roll_the_bones_buff broadside_buff buried_treasure_buff grand_melee_buff ruthless_precision_buff skull_and_crossbones_buff true_bearing_buff)
SpellList(exsanguinated rupture_debuff_exsanguinated garrote_debuff_exsanguinated)

# Learned spells.
Define(adrenaline_rush 13750)
	SpellInfo(adrenaline_rush cd=180)
	SpellAddBuff(adrenaline_rush adrenaline_rush_buff=1)
Define(adrenaline_rush_buff 13750)
	SpellInfo(adrenaline_rush_buff duration=20)
Define(alacrity_buff 193538)
	SpellInfo(alacrity_buff duration=20 max_stacks=5)
Define(ambush 8676)
	SpellInfo(ambush combopoints=-2 energy=50 stealthed=1)
Define(backstab 53)
	SpellInfo(backstab combopoints=-1 energy=35)
	SpellInfo(backstab replace=gloomblade talent=gloomblade_talent)
	SpellRequire(backstab combopoints -2=buff,shadow_blades_buff)
Define(between_the_eyes 199804)
	SpellInfo(between_the_eyes combopoints=1 max_combopoints=5 energy=25 cd=30)
	SpellInfo(between_the_eyes max_combopoints=6 talent=deeper_stratagem_talent)
Define(blade_flurry 13877)
	SpellInfo(blade_flurry cd=25 energy=15 charges=2)
	SpellAddBuff(blade_flurry blade_flurry_buff=toggle)
	SpellRequire(blade_flurry unusable 1=buff,blade_flurry_buff)
Define(blade_flurry_buff 13877)
	SpellInfo(blade_flurry_buff duration=12)
	SpellInfo(blade_flurry_buff duration=15 talent=dancing_steel_talent)
Define(blade_rush 271877)
	SpellInfo(blade_rush cd=45)
	SpellAddBuff(blade_rush blade_rush_buff=1)
Define(blade_rush_buff 271896)
	SpellInfo(blade_rush_buff duration=5)
Define(blind 2094)
	SpellInfo(blind cd=120)
	SpellInfo(blind add_cd=30 talent=blinding_powder_talent)
	SpellAddTargetDebuff(blind blind_debuff=1)
Define(blind_debuff 2094)
	SpellInfo(blind_debuff duration=60)
Define(blindside 111240)
	SpellInfo(blindside energy=30 combopoints=-1 target_health_pct=30)
	SpellRequire(blindside target_health_pct 100=buff,blindside_buff)
	SpellRequire(blindside energy_percent 0=buff,blindside_buff)
	SpellAddBuff(blindside blindside_buff=-1)
Define(blindside_buff 121153)
	SpellInfo(blindside_buff duration=10)
Define(cheap_shot 1833)
	SpellInfo(cheap_shot combopoints=-2 energy=40 interrupt=1 stealthed=1)
	SpellInfo(cheap_shot energy=0 talent=dirty_tricks_talent)
	SpellRequire(cheap_shot energy_percent 0=buff,shot_in_the_dark_buff specialization=subtlety)
	SpellAddTargetDebuff(cheap_shot find_weakness_debuff=1 talent=find_weakness_talent specialization=subtlety)
Define(cloak_of_shadows 31224)
	SpellInfo(cloak_of_shadows cd=120)
Define(cloak_of_shadows_buff 31224)
	SpellInfo(cloak_of_shadows_buff duration=5)
Define(crimson_tempest 121411)
	SpellInfo(crimson_tempest energy=35 combopoints=1 max_combopoints=5)
	SpellInfo(crimson_tempest max_combopoints=6 talent=deeper_stratagem_talent)
	SpellAddTargetDebuff(crimson_tempest crimson_tempest_debuff=1)
Define(crimson_tempest_debuff 121411)
	SpellInfo(crimson_tempest_debuff duration=2 add_duration_combopoints=2 tick=2 haste=melee)
Define(crimson_vial 185311)
	SpellInfo(crimson_vial energy=30 cd=30)
	SpellAddBuff(crimson_vial crimson_vial_buff=1)
Define(crimson_vial_buff 185311)
	SpellInfo(crimson_vial_buff duration=6)
Define(crippling_poison 3408)
	SpellAddBuff(crippling_poison crippling_poison_buff=1)
Define(crippling_poison_buff 3408)
	SpellInfo(crippling_poison_buff duration=3600)
Define(crippling_poison_debuff 3409)
	SpellInfo(crippling_poison_debuff duration=12)
Define(deadly_poison 2823)
	SpellAddBuff(deadly_poison deadly_poison_buff=1)
	SpellAddBuff(deadly_poison leeching_poison_buff talent=leeching_poison_talent)
Define(deadly_poison_buff 2823)
	SpellInfo(deadly_poison_buff duration=3600)
Define(deadly_poison_debuff 2818)
	SpellInfo(deadly_poison_debuff duration=12 tick=2 haste=melee)
Define(elaborate_planning_buff 193640)
	SpellInfo(elaborate_planning_buff duration=5)
Define(dispatch 2098)
	SpellInfo(dispatch energy=35 combopoints=1 max_combopoints=5)
	SpellInfo(dispatch max_combopoints=6 talent=deeper_stratagem_talent)
Define(distract 1725)
	SpellInfo(distract energy=30 cd=30)
Define(envenom 32645)
	SpellInfo(envenom combopoints=1 max_combopoints=5 energy=25)
	SpellInfo(envenom max_combopoints=6 talent=deeper_stratagem_talent)
	SpellAddBuff(envenom envenom_buff=1)
Define(envenom_buff 32645)
	SpellInfo(envenom_buff duration=1 add_duration_combopoints=1)
Define(evasion 5277)
	SpellInfo(evasion cd=120)
	SpellAddBuff(evasion evasion_buff=1)
Define(evasion_buff 5277)
	SpellInfo(evasion_buff duration=10)
Define(eviscerate 196819)
	SpellInfo(eviscerate combopoints=1 max_combopoints=5 energy=35)
	SpellInfo(eviscerate max_combopoints=6 talent=deeper_stratagem_talent)
	SpellRequire(eviscerate energy_percent 80=stealthed,1 talent=shadow_focus_talent)
	SpellAddBuff(eviscerate shuriken_combo_buff=0)
Define(exsanguinate 200806)
	SpellInfo(exsanguinate energy=25 cd=45 tag=main)
	SpellAddTargetDebuff(exsanguinate rupture_debuff_exsanguinated=1 if_target_debuff=rupture_debuff) #TODO if_target_debuff is not implemented here
	SpellAddTargetDebuff(exsanguinate garrote_debuff_exsanguinated=1 if_target_debuff=garrote_debuff)
Define(fan_of_knives 51723)
	SpellInfo(fan_of_knives combopoints=-1 energy=35)
	SpellAddBuff(fan_of_knives hidden_blades_buff=0 talent=hidden_blades_talent)
Define(feint 1966)
	SpellInfo(feint energy=35 cd=15)
Define(find_weakness_debuff 91021)
	SpellInfo(find_weakness_debuff duration=10)
Define(garrote 703)
	SpellInfo(garrote cd=15 combopoints=-1 energy=45)
	SpellAddTargetDebuff(garrote garrote_debuff=1)
Define(garrote_debuff 703)
	SpellInfo(garrote_debuff duration=18 tick=2 haste=melee)
Define(garrote_debuff_exsanguinated -703) #TODO negative number for hidden auras?
	SpellInfo(garrote_debuff_exsanguinated duration=garrote_debuff) #TODO use an aura as a duration to mirror the duration
Define(ghostly_strike 196937)
	SpellInfo(ghostly_strike combopoints=-1 energy=35)
	SpellAddTargetDebuff(ghostly_strike ghostly_strike_debuff=1)
Define(ghostly_strike_debuff 196937)
	SpellInfo(ghostly_strike_debuff duration=10)
Define(gloomblade 200758)
	SpellInfo(gloomblade combopoints=-1 energy=35)
	SpellInfo(gloomblade replace=backstab talent=gloomblade_talent)
	SpellRequire(gloomblade combopoints -2=buff,shadow_blades_buff)
Define(gouge 1776)
	SpellInfo(gouge combopoints=-1 cd=15 energy=25 tag=main)
	SpellInfo(gouge energy=0 talent=dirty_tricks_talent)
Define(grappling_hook 195457)
	SpellInfo(grappling_hook cd=60)
	SpellInfo(grappling_hook add_cd=-30 talent=retractable_hook_talent)
Define(hidden_blades_buff 270070)
	SpellInfo(hidden_blades_buff max_stacks=20)
Define(internal_bleeding_debuff 154953)
	SpellInfo(internal_bleeding_debuff duration=6 tick=1 haste=melee)
Define(kick 1766)
	SpellInfo(kick cd=15 gcd=0 interrupt=1 offgcd=1)
Define(kidney_shot 408)
	SpellInfo(kidney_shot cd=20 combopoints=1 max_combopoints=5 energy=25 interrupt=1)
	SpellInfo(kidney_shot max_combopoints=6 talent=deeper_stratagem_talent)
	SpellRequire(kidney_shot energy_percent 80=stealthed,1 talent=shadow_focus_talent)
	SpellAddTargetDebuff(kidney_shot internal_bleeding_debuff=1 talent=internal_bleeding_talent)
Define(killing_spree 51690)
	SpellInfo(killing_spree cd=120)
	SpellAddBuff(killing_spree killing_spree_buff=1)
Define(killing_spree_buff 51690)
	SpellInfo(killing_spree_buff duration=2)
Define(leeching_poison_buff 108211)
	SpellInfo(leeching_poison_buff duration=3600)
Define(loaded_dice_buff 256171)
	SpellInfo(loaded_dice_buff duration=45)
Define(marked_for_death 137619)
	SpellInfo(marked_for_death cd=30 combopoints=-6 gcd=0 offgcd=1)
Define(master_assassin_buff 256735)
	SpellInfo(master_assassin_buff duration=3)
Define(master_of_shadows 196980)
	SpellInfo(master_of_shadows duration=3)
Define(mutilate 1329)
	SpellInfo(mutilate combopoints=-2 energy=50)
	SpellRequire(mutilate add_energy -5=buff,lethal_poison_buff talent=venom_rush_talent)
Define(nightblade 195452)
	SpellInfo(nightblade energy=25 combopoints=1 max_combopoints=5)
	SpellInfo(nightblade max_combopoints=6 talent=deeper_stratagem_talent)
	SpellRequire(nightblade energy_percent 80=stealthed,1 talent=shadow_focus_talent)
	SpellAddTargetDebuff(nightblade nightblade_debuff=1)
Define(nightblade_debuff 195452)
	SpellInfo(nightblade_debuff duration=6 add_duration_combopoints=2 tick=2 haste=melee)
Define(opportunity_buff 195627)
	SpellInfo(opportunity_buff duration=10)
Define(pick_lock 1804)
Define(pick_pocket 921)
Define(pistol_shot 185763)
	SpellInfo(pistol_shot combopoints=-1 energy=40)
	SpellAddBuff(pistol_shot opportunity_buff=-1)
	SpellRequire(pistol_shot energy_percent 0=buff,opportunity_buff)
	SpellRequire(pistol_shot combopionts -2=buff,opportunity_buff talent=quick_draw_talent)
Define(poisoned_knife 185565)
	SpellInfo(poisoned_knife energy=40 combopoints=-1)
Define(prey_on_the_weak_debuff 255909)
	SpellInfo(prey_on_the_weak_debuff duration=6)
Define(riposte 199754)
	SpellInfo(riposte cd=120)
Define(riposte_buff 199754)
	SpellInfo(riposte_buff duration=10)
Define(roll_the_bones 193316)
	SpellInfo(roll_the_bones energy=25 combopoints=1 max_combopoints=5)
	SpellInfo(roll_the_bones max_combopoints=6 talent=deeper_stratagem_talent)
	SpellInfo(roll_the_bones replace=slice_and_dice talent=slice_and_dice_talent)
	SpellAddBuff(roll_the_bones loaded_dice_buff=0 talent=loaded_dice_talent)
Define(rupture 1943)
	SpellInfo(rupture combopoints=1 max_combopoints=5 energy=25)
	SpellInfo(rupture max_combopoints=6 talent=deeper_stratagem_talent)
	SpellAddTargetDebuff(rupture rupture_debuff=1)
Define(rupture_debuff 1943)
	SpellInfo(rupture_debuff add_duration_combopoints=4 duration=4 tick=2)
Define(rupture_debuff_exsanguinated -1943)
	SpellInfo(rupture_debuff_exsanguinated duration=rupture_debuff)
Define(sap 6770)
	SpellInfo(sap energy=35 stealthed=1)
	SpellInfo(sap energy=0 talent=dirty_tricks_talent)
Define(secret_technique 280719)
	SpellInfo(secret_technique energy=30 cd=45 combopoints=1 max_combopoints=5)
	SpellInfo(secret_technique max_combopoints=6 talent=deeper_stratagem_talent)
	SpellRequire(secret_technique energy_percent 80=stealthed,1 talent=shadow_focus_talent)
Define(shadow_blades 121471)
	SpellInfo(shadow_blades cd=180)
	SpellAddBuff(shadow_blades shadow_blades_buff=1)
Define(shadow_blades_buff 121471)
	SpellInfo(shadow_blades_buff duration=20)
Define(shadow_dance 185313)
	SpellInfo(shadow_dance cd=60 gcd=0 charges=2)
	SpellInfo(shadow_dance charges=3 talent=enveloping_shadows_talent)
	SpellAddBuff(shadow_dance shadow_dance_buff=1)
	SpellAddBuff(shadow_dance master_of_shadows=1 talent=master_of_shadows_talent)
Define(shadow_dance_buff 185422)
	SpellInfo(shadow_dance_buff duration=5)
Define(shadowstep 36554)
	SpellInfo(shadowstep cd=30 gcd=0 offgcd=1 charges=2)
Define(shadowstrike 185438)
	SpellInfo(shadowstrike combopoints=-2 energy=40 stealthed=1)
	SpellRequire(shadowstrike combopoints -3=buff,shadow_blades_buff)
	SpellAddTargetDebuff(shadowstrike find_weakness_debuff=1 talent=find_weakness_talent)
Define(shroud_of_concealment 114018)
	SpellInfo(shroud_of_concealment cd=360 stealthed=1)
Define(shuriken_combo_buff 245640)
	SpellInfo(shuriken_combo_buff duration=15 max_stacks=5)
Define(shuriken_storm 197835)
	SpellInfo(shuriken_storm energy=35 combopoints=-1)
	SpellAddBuff(shuriken_storm shuriken_combo_buff=1)
Define(shuriken_tornado 277925)
	SpellInfo(shuriken_tornado energy=60 cd=60)
Define(shuriken_toss 114014)
	SpellInfo(shuriken_toss combopoints=-1 energy=40 travel_time=1)
Define(sinister_strike 193315)
	SpellInfo(sinister_strike combopoints=-1 energy=45)
Define(slice_and_dice 5171)
	SpellInfo(slice_and_dice combopoints=1 max_combopoints=5 energy=25)
	SpellInfo(slice_and_dice max_combopoints=6 talent=deeper_stratagem_talent)
	SpellAddBuff(slice_and_dice slice_and_dice_buff=1)
	SpellInfo(slice_and_dice replace=roll_the_bones talent=slice_and_dice_talent)
Define(slice_and_dice_buff 5171)
	SpellInfo(slice_and_dice add_duration_combopoints=6 duration=6)
Define(shot_in_the_dark_buff 257506)
Define(sprint 2983)
	SpellInfo(sprint cd=60)
	SpellAddBuff(sprint sprint_buff=1)
Define(sprint_buff 2983)
	SpellInfo(sprint_buff duration=8)
Define(stealth 1784)
	SpellInfo(stealth cd=2 to_stance=rogue_stealth)
	SpellRequire(stealth unusable 1=stealthed,1)
	SpellRequire(stealth unusable 1=combat,1)
	SpellAddBuff(stealth stealth_buff=1)
	SpellAddBuff(stealth master_of_shadows=1 talent=master_of_shadows_talent specialization=subtlety)
Define(stealth_buff 1784)
Define(subterfuge_buff 115192)
	SpellInfo(subterfuge_buff duration=3)
Define(symbols_of_death 212283)
	SpellInfo(symbols_of_death cd=30 energy=-40 tag=shortcd)
	SpellAddBuff(symbols_of_death symbols_of_death_buff=1)
Define(symbols_of_death_buff 212283)
	SpellInfo(symbols_of_death_buff duration=10)
Define(toxic_blade 245388)
	SpellInfo(toxic_blade energy=20 cd=25 combopoints=-1 tag=main)
	SpellAddTargetDebuff(toxic_blade toxic_blade_debuff=1)
Define(toxic_blade_debuff 245389)
	SpellInfo(toxic_blade_debuff duration=9)
Define(tricks_of_the_trade 57934)
	SpellInfo(tricks_of_the_trade cd=30)
Define(vanish 1856)
	SpellInfo(vanish cd=120 gcd=0)
	SpellAddBuff(vanish vanish_buff=1)
	SpellRequire(vanish unusable 1=stealthed,1)
	SpellAddBuff(vanish master_of_shadows=1 talent=master_of_shadows_talent specialization=subtlety)
Define(vanish_buff 11327)
	SpellInfo(vanish_aura duration=3)
Define(vendetta 79140)
	SpellInfo(vendetta cd=120)
	SpellAddTargetDebuff(vendetta vendetta_debuff=1)
Define(vendetta_debuff 79140)
	SpellInfo(vendetta_debuff duration=20)
Define(wound_poison 8679)
	SpellAddBuff(wound_poison wound_poison_buff=1)
	SpellAddBuff(wound_poison leeching_poison_buff talent=leeching_poison_talent)
Define(wound_poison_buff 8679)
	SpellInfo(wound_poison_buff duration=3600)
Define(wound_poison_debuff 8679)
	SpellInfo(wound_poison_debuff duration=12)
	

# Roll the Bones buffs
Define(broadside_buff 193356)
	SpellInfo(broadside_buff duration=12 add_duration_combopoints=6)
Define(buried_treasure_buff 199600)
	SpellInfo(buried_treasure_buff duration=12 add_duration_combopoints=6)
Define(grand_melee_buff 193358)	
	SpellInfo(grand_melee_buff duration=12 add_duration_combopoints=6)
Define(ruthless_precision_buff 193357)
	SpellInfo(ruthless_precision_buff duration=12 add_duration_combopoints=6)
Define(skull_and_crossbones_buff 199603)
	SpellInfo(skull_and_crossbones_buff duration=12 add_duration_combopoints=6)
Define(true_bearing_buff 193359)
	SpellInfo(true_bearing_buff duration=12 add_duration_combopoints=6)


# Azerite Traits
Define(ace_up_your_sleeve_trait 278676)
Define(deadshot_trait 272935)

# Leegendary items
Define(the_dreadlords_deceit_item 137021)
Define(the_dreadlords_deceit_assassination_buff 208693)
Define(the_dreadlords_deceit_outlaw_buff 208692)
Define(the_dreadlords_deceit_subtlety_buff 228224)

# Talents
Define(acrobatic_strikes_talent 4)
Define(alacrity_talent 17)
Define(blade_rush_talent 20)
Define(blinding_powder_talent 14)
Define(blindside_talent 3)
Define(cheat_death_talent 11)
Define(crimson_tempest_talent 21)
Define(dancing_steel_talent 19)
Define(dark_shadow_talent 16)
Define(deeper_stratagem_talent 8)
Define(dirty_tricks_talent 13)
Define(elaborate_planning_talent 2)
Define(elusiveness_talent 12)
Define(enveloping_shadows_talent 18)
Define(exsanguinate_talent 18)
Define(find_weakness_talent 2)
Define(ghostly_strike_talent 3)
Define(gloomblade_talent 3)
Define(hidden_blades_talent 20)
Define(hit_and_run_talent 6)
Define(internal_bleeding_talent 13)
Define(iron_stomach_talent 10)
Define(iron_wire_talent 14)
Define(killing_spree_talent 21)
Define(leeching_poison_talent 10)
Define(loaded_dice_talent 16)
Define(marked_for_death_talent 9)
Define(master_assassin_talent 6)
Define(master_of_shadows_talent 19)
Define(master_poisoner_talent 1)
Define(night_terrors_talent 14)
Define(nightstalker_talent 4)
Define(poison_bomb_talent 19)
Define(prey_on_the_weak_talent 15)
Define(quick_draw_talent 2)
Define(retractable_hook_talent 5)
Define(secret_technique_talent 20)
Define(shadow_focus_talent 6)
Define(shot_in_the_dark_talent 13)
Define(shuriken_tornado_talent 21)
Define(slice_and_dice_talent 18)
Define(soothing_darkness_talent 10)
Define(subterfuge_talent 5)
Define(toxic_blade_talent 17)
Define(venom_rush_talent 16)
Define(vigor_talent 7)
Define(weaponmaster_talent 1)

# Non-default tags for OvaleSimulationCraft.
	SpellInfo(vanish tag=shortcd)
	SpellInfo(goremaws_bite tag=main)
]]
    OvaleScripts:RegisterScript("ROGUE", nil, name, desc, code, "include")
end
