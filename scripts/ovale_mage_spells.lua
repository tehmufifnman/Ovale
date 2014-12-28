local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_mage_spells"
	local desc = "[6.0.2] Ovale: Mage spells"
	local code = [[
# Mage spells and functions.

Define(arcane_barrage 44425)
	SpellInfo(arcane_barrage cd=3)
	SpellAddDebuff(arcane_barrage arcane_charge_debuff=0 if_spell=arcane_charge)
Define(arcane_blast 30451)
	SpellAddBuff(arcane_blast presence_of_mind_buff=0 if_spell=presence_of_mind)
	SpellAddBuff(arcane_blast profound_magic_buff=0 itemset=T16_caster itemcount=2 specialization=arcane)
	SpellAddBuff(arcane_blast ice_floes_buff=0 if_spell=ice_floes)
	SpellAddDebuff(arcane_blast arcane_charge_debuff=1 if_spell=arcane_charge)
Define(arcane_brilliance 1459)
	SpellAddBuff(arcane_brilliance arcane_brilliance_buff=1)
Define(arcane_brilliance_buff 1459)
	SpellInfo(arcane_brilliance_buff duration=3600)
Define(arcane_charge 114664)
Define(arcane_charge_debuff 36032)
	SpellInfo(arcane_charge_debuff duration=15 max_stacks=4)
Define(arcane_explosion 1449)
	SpellAddDebuff(arcane_explosion arcane_charge_debuff=refresh if_spell=arcane_charge)
Define(arcane_instability_buff 166872)
	SpellInfo(arcane_instability_buff duration=15)
Define(arcane_missiles 5143)
	SpellInfo(arcane_missiles duration=2)
	SpellAddBuff(arcane_missiles arcane_instability_buff=0 itemset=T17 itemcount=4)
	SpellAddBuff(arcane_missiles arcane_power_buff=extend,2 if_spell=overpowered)
	SpellAddDebuff(arcane_missiles arcane_charge_debuff=1 if_spell=arcane_charge)
Define(arcane_missiles_buff 79683)
	SpellInfo(arcane_missiles_buff duration=20 max_stacks=3)
Define(arcane_orb 153626)
	SpellInfo(arcane_orb cd=15)
	SpellAddDebuff(arcane_orb arcane_charge_debuff=1 if_spell=arcane_charge)
Define(arcane_orb_talent 21)
Define(arcane_power 12042)
	SpellInfo(arcane_power cd=90 gcd=0)
	SpellInfo(arcane_power addcd=90 glyph=glyph_of_arcane_power)
	SpellAddBuff(arcane_power arcane_power_buff=1)
Define(arcane_power_buff 12042)
	SpellInfo(arcane_power_buff duration=15)
	SpellInfo(arcane_power_buff addduration=15 glyph=glyph_of_arcane_power)
Define(blast_wave 157981)
Define(blazing_speed 108843)
	SpellInfo(blazing_speed cd=25 gcd=0)
Define(blink 1953)
	SpellInfo(blink cd=15 glyph=!glyph_of_rapid_displacement)
Define(blizzard 10)
	SpellInfo(blizzard channel=8 haste=spell)
	SpellAddBuff(blizzard ice_floes_buff=0 if_spell=ice_floes)
Define(brain_freeze 44549)
Define(brain_freeze_buff 57761)
	SpellInfo(brain_freeze_buff duration=15)
Define(cold_snap 11958)
	SpellInfo(cold_snap cd=180 gcd=0)
Define(combustion 11129)
	SpellInfo(combustion cd=45 gcd=0)
	SpellInfo(combustion cd=90 glyph=glyph_of_combustion)
	SpellInfo(combustion cd=36 itemset=T14 itemcount=4)
	SpellInfo(combustion cd=72 glyph=glyph_of_combustion itemset=T14 itemcount=4)
	SpellAddTargetDebuff(combustion combustion_debuff=1)
Define(combustion_debuff 83853)
	SpellInfo(combustion_debuff duration=10 haste=spell tick=1)
	SpellInfo(combustion_debuff addduration=10 glyph=glyph_of_combustion)
Define(comet_storm 153595)
	SpellInfo(comet_storm cd=30)
Define(cone_of_cold 120)
	SpellInfo(cone_of_cold cd=12)
Define(counterspell 2139)
	SpellInfo(counterspell cd=24 gcd=0 interrupt=1)
	SpellInfo(counterspell addcd=4 glyph=glyph_of_counterspell)
Define(deep_freeze 44572)
	SpellInfo(deep_freeze cd=30 interrupt=1)
	SpellInfo(deep_freeze gcd=0 glyph=glyph_of_deep_freeze)
	SpellAddBuff(deep_freeze fingers_of_frost_buff=-1 if_spell=fingers_of_frost)
Define(dragons_breath 31661)
	SpellInfo(dragons_breath cd=20)
Define(evocation 12051)
	SpellInfo(evocation cd=120 channel=3 haste=spell)
	SpellInfo(evocation addcd=-30 if_spell=improved_evocation)
	SpellAddBuff(evocation ice_floes_buff=0 if_spell=ice_floes)
	SpellAddDebuff(evocation arcane_charge_debuff=0 if_spell=arcane_charge)
Define(fingers_of_frost 112965)
Define(fingers_of_frost_buff 44544)
	SpellInfo(fingers_of_frost_buff duration=15 max_stacks=2)
Define(fireball 133)
Define(flamestrike 2120)
	SpellInfo(flamestrike cd=12)
	SpellInfo(flamestrike cd=0 if_spell=improved_flamestrike)
	SpellAddBuff(flamestrike ice_floes_buff=0 if_spell=ice_floes)
	SpellAddTargetDebuff(flamestrike flamestrike_debuff=1)
Define(flamestrike_debuff 2120)
	SpellInfo(flamestrike_debuff duration=8 haste=spell tick=2)
Define(frost_bomb 112948)
	SpellAddTargetDebuff(frost_bomb frost_bomb_debuff=1)
Define(frost_bomb_debuff 112948)
	SpellInfo(frost_bomb_debuff duration=12)
Define(frost_bomb_talent 13)
Define(frostbolt 116)
	SpellAddBuff(frostbolt ice_floes_buff=0 if_spell=ice_floes)
Define(frostfire_bolt 44614)
	SpellAddBuff(frostfire_bolt brain_freeze_buff=0 if_spell=brain_freeze)
	SpellAddBuff(frostfire_bolt ice_floes_buff=0 if_spell=ice_floes)
Define(frozen_orb 84714)
	SpellInfo(frozen_orb cd=60)
Define(frozen_orb_debuff 84721)
	SpellInfo(frozen_orb_debuff duration=2)
Define(glyph_of_arcane_power 62210)
Define(glyph_of_combustion 56368)
Define(glyph_of_cone_of_cold 115705)
Define(glyph_of_counterspell 115703)
Define(glyph_of_deep_freeze 115710)
Define(glyph_of_dragons_breath 159485)
Define(glyph_of_frostfire_bolt 61205)
Define(glyph_of_icy_veins 56364)
Define(glyph_of_rapid_displacement 146659)
Define(heating_up_buff 48107)
	SpellInfo(heating_up_buff duration=10)
Define(ice_barrier 11426)
	SpellInfo(ice_barrier cd=25)
Define(ice_floes 108839)
	SpellAddBuff(ice_floes ice_floes_buff=1)
Define(ice_floes_buff 108839)
	SpellInfo(ice_floes_buff duration=15)
Define(ice_lance 30455)
	SpellInfo(ice_lance max_travel_time=1.3) # maximum observed travel time with a bit of padding
	SpellAddBuff(ice_lance fingers_of_frost_buff=-1 if_spell=fingers_of_frost)
	SpellAddBuff(ice_lance icy_veins_buff=extend,2 if_spell=thermal_void)
Define(ice_nova 157997)
Define(ice_shard_buff 166869)
	SpellInfo(ice_shard_buff duration=10 max_stacks=10)
Define(icy_veins 12472)
	SpellInfo(icy_veins cd=180)
	SpellInfo(icy_veins addcd=-90 itemset=T14 itemcount=4)
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
Define(incanters_flow_talent 18)
Define(inferno_blast 108853)
	SpellInfo(inferno_blast cd=8)
Define(kindling_talent 19)
Define(living_bomb 44457)
	SpellInfo(living_bomb gcd=1)
	SpellAddTargetDebuff(living_bomb living_bomb_debuff=1)
Define(living_bomb_debuff 44457)
	SpellInfo(living_bomb duration=12 haste=spell tick=3)
Define(living_bomb_talent 13)
Define(meteor 153561)
	SpellInfo(meteor cd=45)
Define(meteor_talent 21)
Define(mirror_image 55342)
	SpellInfo(mirror_image cd=120)
Define(mirror_image_talent 16)
Define(nether_tempest 114923)
	SpellAddTargetDebuff(nether_tempest nether_tempest_debuff=1)
Define(nether_tempest_debuff 114923)
	SpellInfo(nether_tempest_debuff duration=12 haste=spell tick=1)
Define(overpowered 155147)
Define(overpowered_talent 19)
Define(pet_freeze 33395)
	SpellInfo(pet_freeze cd=25 gcd=0 sharedcd=pet_fingers_of_frost)
	SpellAddBuff(pet_freeze fingers_of_frost_buff=1 if_spell=fingers_of_frost)
Define(pet_water_jet 135029)
	SpellInfo(pet_water_jet cd=25 gcd=0 sharedcd=pet_fingers_of_frost)
	SpellAddTargetDebuff(pet_water_jet pet_water_jet_debuff=1)
Define(pet_water_jet_debuff 135029)
	SpellInfo(pet_water_jet_debuff duration=4)
Define(potent_flames_buff 145254)
	SpellInfo(potent_flames_buff duration=5 max_stacks=5)
Define(presence_of_mind 12043)
	SpellInfo(presence_of_mind cd=90 gcd=0)
	SpellAddBuff(presence_of_mind presence_of_mind_buff=1)
Define(presence_of_mind_buff 12043)
Define(profound_magic_buff 145252)
	SpellInfo(profound_magic_buff duration=10 max_stacks=4)
Define(prismatic_crystal 152087)
	SpellInfo(prismatic_crystal cd=90 duration=12 totem=1)
Define(prismatic_crystal_talent 20)
Define(pyroblast 11366)
	SpellAddBuff(pyroblast ice_floes_buff=0 if_spell=ice_floes)
	SpellAddBuff(pyroblast pyroblast_buff=0)
	SpellAddTargetDebuff(pyroblast pyroblast_debuff=1)
Define(pyroblast_buff 48108)
	SpellInfo(pyroblast_buff duration=15)
Define(pyroblast_debuff 11366)
	SpellInfo(pyroblast_debuff duration=18 haste=spell tick=3)
Define(pyromaniac_buff 166868)
	SpellInfo(pyromaniac_buff duration=4)
Define(rune_of_power 116011)
	SpellInfo(rune_of_power buff_totem=rune_of_power_buff duration=180 max_totems=2 totem=1)
	SpellAddBuff(rune_of_power ice_floes_buff=0 if_spell=ice_floes)
	SpellAddBuff(rune_of_power presence_of_mind_buff=0 if_spell=presence_of_mind)
Define(rune_of_power_buff 116014)
Define(scorch 2948)
Define(spellsteal 30449)
Define(supernova 157980)
Define(thermal_void 155149)
Define(thermal_void_talent 19)
Define(temporal_displacement_debuff 80354)
	SpellInfo(temporal_displacement_debuff duration=600)
Define(time_warp 80353)
	SpellInfo(time_warp cd=300 gcd=0)
	SpellAddBuff(time_warp time_warp_buff=1)
	SpellAddDebuff(time_warp temporal_displacement_debuff=1)
Define(time_warp_buff 80353)
	SpellInfo(time_warp_buff duration=40)
Define(water_elemental 31687)
	SpellInfo(water_elemental cd=60)
]]

	OvaleScripts:RegisterScript("MAGE", name, desc, code, "include")
end
