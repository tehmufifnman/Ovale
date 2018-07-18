import { OvaleScripts } from "../Scripts";
export function register() {
    let name = "ovale_mage_spells";
    let desc = "[7.0] Ovale: Mage spells";
    let code = `
# Mage spells and functions.

Define(arcane_affinity 166871)
	SpellInfo(arcane_affinity duration=15)
Define(arcane_barrage 44425)
	SpellInfo(arcane_barrage cd=3 travel_time=1 arcanecharges=finisher)
Define(arcane_blast 30451)
	SpellAddBuff(arcane_blast presence_of_mind_buff=0 if_spell=presence_of_mind arcanecharges=-1)
	SpellAddBuff(arcane_blast profound_magic_buff=0 itemset=T16_caster itemcount=2 specialization=arcane)
	SpellAddBuff(arcane_blast ice_floes_buff=0 if_spell=ice_floes)
Define(arcane_brilliance 1459)
	SpellAddBuff(arcane_brilliance arcane_brilliance_buff=1)
Define(arcane_brilliance_buff 1459)
	SpellInfo(arcane_brilliance_buff duration=3600)
Define(arcane_charge 114664)
Define(arcane_charge_debuff 36032)
	SpellInfo(arcane_charge_debuff duration=15 max_stacks=4)
Define(arcane_explosion 1449)
	SpellInfo(arcane_explosion arcanecharges=-1)
Define(arcane_instability_buff 166872)
	SpellInfo(arcane_instability_buff duration=15)
Define(arcane_missiles 5143)
	SpellInfo(arcane_missiles duration=2 travel_time=1 arcanecharges=-1)
	SpellRequire(arcane_missiles unusable 1=buff,!arcane_missiles_buff)
	SpellAddBuff(arcane_missiles arcane_instability_buff=0 itemset=T17 itemcount=4 specialization=arcane)
	SpellAddBuff(arcane_missiles arcane_missiles_buff=-1)
	SpellAddBuff(arcane_missiles arcane_power_buff=extend,2 if_spell=overpowered)
Define(arcane_missiles_buff 79683)
	SpellInfo(arcane_missiles_buff duration=20 max_stacks=3)
Define(arcane_orb 153626)
	SpellInfo(arcane_orb cd=15)
Define(arcane_power 12042)
	SpellInfo(arcane_power cd=90 gcd=0)
	SpellAddBuff(arcane_power arcane_power_buff=1)
Define(arcane_power_buff 12042)
	SpellInfo(arcane_power_buff duration=15)
Define(blast_wave 157981)
Define(blazing_speed 108843)
	SpellInfo(blazing_speed cd=25 gcd=0 offgcd=1)
Define(blink 1953)
	SpellInfo(blink cd=15)
Define(blizzard 190356)
	SpellInfo(blizzard cd=8 haste=spell)
	SpellAddBuff(blizzard ice_floes_buff=0 if_spell=ice_floes)
Define(brain_freeze 44549)
Define(brain_freeze_buff 190446)
	SpellInfo(brain_freeze_buff duration=15)
Define(charged_up 205032)
	SpellInfo(charged_up arcanecharges=-4)
Define(cinderstorm 198929)
	SpellInfo(cinderstorm cd=9)
Define(cold_snap 11958)
	SpellInfo(cold_snap cd=180 gcd=0 offgcd=1)
Define(combustion 190319)
	SpellInfo(combustion cd=120 gcd=0)
	SpellAddBuff(combustion combustion_buff=1)
Define(combustion_buff 190319)
	SpellInfo(combustion_buff duration=10)
Define(comet_storm 153595)
	SpellInfo(comet_storm cd=30 travel_time=1)
Define(cone_of_cold 120)
	SpellInfo(cone_of_cold cd=12)
Define(counterspell 2139)
	SpellInfo(counterspell cd=24 gcd=0 interrupt=1)
Define(deep_freeze 44572)
	SpellInfo(deep_freeze cd=30 interrupt=1)
	SpellAddBuff(deep_freeze fingers_of_frost_buff=-1 if_spell=fingers_of_frost)
Define(dragons_breath 31661)
	SpellInfo(dragons_breath cd=20)
Define(ebonbolt 214634)
	SpellInfo(ebonbolt cd=45 tag=main)
	SpellAddBuff(ebonbolt brain_freeze_buff=1)
Define(erupting_infernal_core_buff 248147)
	SpellInfo(erupting_infernal_core_buff duration=30)
Define(evocation 12051)
	SpellInfo(evocation cd=120 channel=3 haste=spell)
	SpellInfo(evocation add_cd=-30 if_spell=improved_evocation)
	SpellAddBuff(evocation ice_floes_buff=0 if_spell=ice_floes)
Define(fingers_of_frost 112965)
Define(fingers_of_frost_buff 44544)
	SpellInfo(fingers_of_frost_buff duration=15 max_stacks=2)
	SpellInfo(fingers_of_frost_buff max_stacks=4 itemset=T18 itemcount=4)
Define(fire_blast 108853)
	SpellInfo(fire_blast gcd=0 offgcd=1 cd=12 charges=1)
	SpellInfo(fire_blast cd=10 charges=2 talent=flame_on_talent)
Define(fireball 133)
	SpellAddBuff(fireball erupting_infernal_core_buff=0)
Define(flamestrike 2120)
	SpellInfo(flamestrike cd=12)
	SpellInfo(flamestrike cd=0 if_spell=improved_flamestrike)
	SpellAddBuff(flamestrike ice_floes_buff=0 if_spell=ice_floes)
	SpellAddTargetDebuff(flamestrike flamestrike_debuff=1)
	SpellAddBuff(flamestrike hot_streak_buff=0)
Define(flamestrike_debuff 2120)
	SpellInfo(flamestrike_debuff duration=8 haste=spell tick=2)
Define(flurry 44614)
	SpellInfo(flurry mana=4)
Define(freeze 33395)
Define(frost_bomb 112948)
	SpellAddTargetDebuff(frost_bomb frost_bomb_debuff=1)
Define(frost_bomb_debuff 112948)
	SpellInfo(frost_bomb_debuff duration=12)
Define(frost_nova 122)
Define(frostbolt 116)
	SpellInfo(frostbolt travel_time=1)
	SpellAddBuff(frostbolt ice_floes_buff=0 if_spell=ice_floes)
Define(frostfire_bolt 44614)
	SpellInfo(frostfire_bolt travel_time=1)
	SpellAddBuff(frostfire_bolt brain_freeze_buff=0 if_spell=brain_freeze)
	SpellAddBuff(frostfire_bolt ice_floes_buff=0 if_spell=ice_floes)
Define(frozen_orb 84714)
	SpellInfo(frozen_orb cd=60)
	SpellAddBuff(frozen_orb frozen_mass_buff=1 itemset=T20 itemcount=2)
Define(frozen_orb_debuff 84721)
	SpellInfo(frozen_orb_debuff duration=2)
Define(frozen_mass_buff 242253)
	SpellInfo(frozen_mass_buff duration=10)
Define(frozen_touch 205030)
	SpellInfo(frozen_touch cd=30)
	SpellAddBuff(frozen_touch fingers_of_frost_buff=2)
Define(glacial_spike 199786)
	SpellInfo(glacial_spike mana=1 unusable=1)
	SpellRequire(glacial_spike unusable 0=buff,icicles_buff,5)
	SpellAddBuff(glacial_spike icicles_buff=0)
Define(heating_up_buff 48107)
	SpellInfo(heating_up_buff duration=10)
Define(hot_streak_buff 48108)
Define(ice_barrier 11426)
	SpellInfo(ice_barrier cd=25)
Define(ice_floes 108839)
	SpellAddBuff(ice_floes ice_floes_buff=1)
Define(ice_floes_buff 108839)
	SpellInfo(ice_floes_buff duration=15)
Define(ice_lance 30455)
	SpellInfo(ice_lance travel_time=1.3) # maximum observed travel time with a bit of padding
	SpellAddBuff(ice_lance fingers_of_frost_buff=-1 if_spell=fingers_of_frost)
	SpellAddBuff(ice_lance icy_veins_buff=extend,2 if_spell=thermal_void)
Define(ice_nova 157997)
Define(ice_shard_buff 166869)
	SpellInfo(ice_shard_buff duration=10 max_stacks=10)
Define(icicles_buff 205473)
	SpellInfo(icicles_buff duration=60)
Define(icy_hand 220817)
Define(icy_veins 12472)
	SpellInfo(icy_veins cd=180)
	SpellInfo(icy_veins add_cd=-90 itemset=T14 itemcount=4)
	SpellAddBuff(icy_veins icy_veins_buff=1)
Define(icy_veins_buff 12472)
	SpellInfo(icy_veins_buff duration=20)
Define(ignite_debuff 12654)
	SpellInfo(ignite_debuff duration=5 tick=1)
Define(improved_evocation 157614)
Define(improved_flamestrike 157621)
Define(incanters_flow 1463)
Define(incanters_flow_buff 116267)
	SpellInfo(incanters_flow_buff duration=25 max_stacks=5)
Define(inferno_blast 108853)
	SpellInfo(inferno_blast cd=8)
	SpellInfo(inferno_blast add_cd=-2 itemset=T17 itemcount=2)
Define(kaelthas_ultimate_ability_buff 209455)
Define(living_bomb 44457)
	SpellInfo(living_bomb gcd=1)
	SpellAddTargetDebuff(living_bomb living_bomb_debuff=1)
Define(living_bomb_debuff 44457)
	SpellInfo(living_bomb duration=12 haste=spell tick=3)
Define(mark_of_doom_debuff 184073)
	SpellInfo(mark_of_doom_debuff duration=10)
Define(meteor 153561)
	SpellInfo(meteor cd=45 travel_time=1)
Define(mirror_image 55342)
	SpellInfo(mirror_image cd=120)
Define(nether_tempest 114923)
	SpellAddTargetDebuff(nether_tempest nether_tempest_debuff=1)
Define(nether_tempest_debuff 114923)
	SpellInfo(nether_tempest_debuff duration=12 haste=spell tick=1)
Define(overpowered 155147)
Define(pet_freeze 33395)
Define(pet_water_jet 135029)
Define(pet_water_jet_debuff 135029)
Define(phoenixs_flames 194466)
Define(polymorph 118)
	SpellAddBuff(polymorph presence_of_mind_buff=0)
	SpellAddTargetDebuff(polymorph polymorph_debuff=1)
Define(polymorph_debuff 118)
	SpellInfo(polymorph_debuff duration=50)
Define(potent_flames_buff 145254)
	SpellInfo(potent_flames_buff duration=5 max_stacks=5)
Define(presence_of_mind 205025)
	SpellInfo(presence_of_mind cd=90 gcd=0)
	SpellAddBuff(presence_of_mind presence_of_mind_buff=1)
Define(presence_of_mind_buff 205025)
Define(profound_magic_buff 145252)
	SpellInfo(profound_magic_buff duration=10 max_stacks=4)
Define(prismatic_crystal 152087)
	SpellInfo(prismatic_crystal cd=90 duration=12 totem=1)
Define(pyroblast 11366)
	SpellInfo(pyroblast travel_time=1)
	SpellInfo(pyroblast damage=FirePyroblastHitDamage specialization=fire)
	SpellAddBuff(pyroblast ice_floes_buff=0 if_spell=ice_floes)
	SpellAddBuff(pyroblast pyroblast_buff=0)
	SpellAddTargetDebuff(pyroblast pyroblast_debuff=1)
	SpellAddBuff(pyroblast hot_streak_buff=0)
	SpellAddBuff(pyroblast erupting_infernal_core_buff=0)
Define(pyroblast_buff 48108)
	SpellInfo(pyroblast_buff duration=15)
Define(pyroblast_debuff 11366)
	SpellInfo(pyroblast_debuff duration=18 haste=spell tick=3)
Define(pyromaniac_buff 166868)
	SpellInfo(pyromaniac_buff duration=4)
Define(quickening_buff 198924)
	SpellAddBuff(arcane_barrage quickening_buff=0)
Define(ray_of_frost 205021)
	SpellInfo(ray_of_frost cd=60 channel=10 tag=main)
Define(rune_of_power 116011)
	SpellInfo(rune_of_power buff_totem=rune_of_power_buff duration=180 max_totems=2 totem=1)
	SpellAddBuff(rune_of_power ice_floes_buff=0 if_spell=ice_floes)
	SpellAddBuff(rune_of_power presence_of_mind_buff=0 if_spell=presence_of_mind)
Define(rune_of_power_buff 116014)
Define(scorch 2948)
	SpellInfo(scorch travel_time=1)
Define(shard_of_the_exodar_warp 207970)
Define(spellsteal 30449)
Define(summon_arcane_familiar 205022)
	SpellInfo(summon_arcane_familiar cd=10)
Define(supernova 157980)
Define(t18_class_trinket 124516)
Define(temporal_displacement_debuff 80354)
	SpellInfo(temporal_displacement_debuff duration=600)
Define(thermal_void 155149)
Define(time_warp 80353)
	SpellInfo(time_warp cd=300 gcd=0)
	SpellAddBuff(time_warp time_warp_buff=1)
	SpellAddDebuff(time_warp temporal_displacement_debuff=1)
Define(time_warp_buff 80353)
	SpellInfo(time_warp_buff duration=40)
Define(water_elemental 31687)
	SpellInfo(water_elemental cd=60)
	SpellInfo(water_elemental unusable=1 talent=lonely_winter_talent)
Define(water_elemental_freeze 33395)
	SpellInfo(water_elemental_freeze cd=25 gcd=0 shared_cd=water_elemental_fingers_of_frost)
	SpellInfo(water_elemental_freeze unusable=1 talent=lonely_winter_talent)
	SpellAddBuff(water_elemental_freeze fingers_of_frost_buff=1 if_spell=fingers_of_frost)
Define(water_elemental_water_jet 135029)
	SpellInfo(water_elemental_water_jet cd=25 gcd=0 shared_cd=water_elemental_fingers_of_frost)
	SpellInfo(water_elemental_water_jet unusable=1 talent=lonely_winter_talent)
	SpellAddBuff(water_elemental_water_jet brain_freeze_buff=1 itemset=T18 itemcount=2)
	SpellAddTargetDebuff(water_elemental_water_jet water_elemental_water_jet_debuff=1)
Define(water_elemental_water_jet_debuff 135029)
	SpellInfo(water_elemental_water_jet_debuff duration=4)
	SpellInfo(water_elemental_water_jet_debuff add_duration=10 itemset=T18 itemcount=4)
Define(winters_chill_debuff 157997) # TODO ???

# Talents
Define(alexstraszas_fury_talent 11)
Define(amplification_talent 1)
Define(arcane_familiar_talent 3)
Define(arcane_orb_talent 21)
Define(blast_wave_talent 6)
Define(blazing_soul_talent 4)
Define(bone_chilling_talent 1)
Define(chain_reaction_talent 11)
Define(charged_up_talent 11)
Define(chrono_shift_talent 13)
Define(comet_storm_talent 18)
Define(conflagration_talent 17)
Define(ebonbolt_talent 12)
Define(firestarter_talent 1)
Define(flame_on_talent 10)
Define(flame_patch_talent 16)
Define(freezing_rain_talent 16)
Define(frenetic_speed_talent 13)
Define(frigid_winds_talent 13)
Define(frozen_touch_talent 10)
Define(glacial_insulation_talent 4)
Define(glacial_spike_talent 21)
Define(ice_floes_talent 6)
Define(ice_nova_talent 3)
Define(ice_ward_talent 14)
Define(incanters_flow_talent 7)
Define(kindling_talent 19)
Define(living_bomb_talent 18)
Define(lonely_winter_talent 2)
Define(mana_shield_talent 4)
Define(meteor_talent 21)
Define(mirror_image_talent 8)
Define(nether_tempest_talent 18)
Define(overpowered_talent 19)
Define(phoenix_flames_talent 12)
Define(pyroclasm_talent 20)
Define(pyromaniac_talent 2)
Define(ray_of_frost_talent 20)
Define(resonance_talent 10)
Define(reverberate_talent 16)
Define(ring_of_frost_talent 15)
Define(rule_of_threes_talent 2)
Define(rune_of_power_talent 9)
Define(searing_touch_talent 3)
Define(shimmer_talent 5)
Define(slipstream_talent 6)
Define(splitting_ice_talent 17)
Define(supernova_talent 12)
Define(thermal_void_talent 19)
Define(time_anomaly_talent 20)
Define(touch_of_the_magi_talent 17)
	
# Artifacts
Define(mark_of_aluneth 210726)
	SpellInfo(mark_of_aluneth cd=60)
Define(mark_of_aluneth_debuff 210726) # ???
Define(phoenix_reborn 215773)

# Legendary items
Define(lady_vashjs_grasp 132411)
Define(rhonins_assaulting_armwraps_buff 208081)
Define(shard_of_the_exodar 132410)
Define(zannesu_journey_buff 226852)
	SpellAddBuff(blizzard zannesu_journey_buff=-1)

# Non-default tags for OvaleSimulationCraft.
	SpellInfo(arcane_orb tag=shortcd)
	SpellInfo(arcane_power tag=cd)
	SpellInfo(blink tag=shortcd)
	SpellInfo(cone_of_cold tag=shortcd)
	SpellInfo(dragons_breath tag=shortcd)
	SpellInfo(frost_bomb tag=shortcd)
	SpellInfo(ice_floes tag=shortcd)
	SpellInfo(rune_of_power tag=shortcd)

### Pyroblast
AddFunction FirePyroblastHitDamage asValue=1 { 2.423 * Spellpower() * { BuffPresent(pyroblast_buff asValue=1) * 1.25 } }
`;
    OvaleScripts.RegisterScript("MAGE", undefined, name, desc, code, "include");
}
