local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_paladin_spells"
	local desc = "[7.0] Ovale: Paladin spells"
	local code = [[
# Paladin spells and functions.

# Learned spells.
Define(aegis_of_light 204150)
	SpellInfo(aegis_of_light cd=300 duration=6)
Define(aegis_of_light_buff 204150)
Define(ardent_defender 31850)
	SpellInfo(ardent_defender cd=120 gcd=0 offgcd=1)
	SpellAddBuff(ardent_defender ardent_defender_buff=1)
Define(ardent_defender_buff 31850)
	SpellInfo(ardent_defender_buff duration=8)
Define(avengers_reprieve_buff 185676)
	SpellInfo(avengers_reprieve_buff duration=10)
Define(avengers_shield 31935)
	SpellInfo(avengers_shield cd=15 travel_time=1)
	SpellAddBuff(avengers_shield avengers_reprieve_buff=1 itemset=T18 itemcount=2 specialization=protection)
	SpellAddBuff(avengers_shield grand_crusader_buff=0 if_spell=grand_crusader)
	SpellAddBuff(avengers_shield faith_barricade_buff=1 itemset=T17 itemcount=2 specialization=protection)
Define(avenging_wrath_heal 31842)
	SpellInfo(avenging_wrath_heal cd=180 gcd=0)
	SpellInfo(avenging_wrath_heal addcd=-60 itemset=T16_heal itemcount=4)
Define(avenging_wrath_melee 31884)
	SpellInfo(avenging_wrath_melee cd=120 gcd=0)
	SpellInfo(avenging_wrath_melee replace=crusade talent=crusade_talent)
	SpellAddBuff(avenging_wrath_melee avenging_wrath_melee_buff=1)
Define(avenging_wrath_melee_buff 31884)
	SpellInfo(avenging_wrath_melee_buff duration=20)
	SpellInfo(avenging_wrath_melee_buff addduration=10 if_spell=sanctified_wrath)
Define(bastion_of_light 204035)
	SpellInfo(bastion_of_light cd=180 gcd=0 offgcd=1)
Define(bastion_of_power_buff 144569)
	SpellInfo(bastion_of_power_buff duration=20)
Define(beacon_of_light 53563)
	SpellInfo(beacon_of_light cd=3)
	SpellAddTargetBuff(beacon_of_light beacon_of_light_buff=1)
Define(beacon_of_light_buff 53563)
Define(blade_of_justice 184575)
	SpellInfo(blade_of_justice holy=-2 cd=10.5)
	SpellInfo(blade_of_justice replace=divine_hammer talent=divine_hammer_talent)
Define(blade_of_wrath_talent 11)
Define(blazing_contempt_buff 166831)
	SpellInfo(blazing_contempt_buff duration=20)
Define(blessed_hammer 204019)
Define(blessed_hammer_talent 2)
Define(blinding_light 115750)
	SpellInfo(blinding_light cd=120 interrupt=1 tag=main)
	SpellInfo(blinding_light tag=main specialization=protection)
Define(cleanse 4987)
	SpellInfo(cleanse cd=8)
Define(consecration 26573)
	SpellInfo(consecration cd=9 tag=main)
	SpellInfo(consecration cd_haste=melee specialization=protection)
Define(consecration_debuff 81298)
	SpellInfo(consecration_debuff duration=9 tick=1)
	SpellInfo(consecration_debuff haste=melee if_spell=sanctity_of_battle)
Define(crusade 231895)
	SpellInfo(crusade cd=120)
	SpellAddBuff(crusade crusade_buff=1)
Define(crusade_buff 231895)
	SpellInfo(crusade_buff duration=20 max_stacks=15)
Define(crusade_talent 20)
Define(crusader_strike 35395)
	SpellInfo(crusader_strike holy=-1 cd=4.5)
	SpellInfo(crusader_strike cd_haste=melee if_spell=sanctity_of_battle)
	SpellInfo(crusader_strike cd=3.5 talent=the_fires_of_justice_talent)
	SpellInfo(crusader_strike unusable=1 talent=zeal_talent)
Define(crusaders_fury_buff 165442)
	SpellInfo(crusaders_fury_buff duration=10)
Define(defender_of_the_light_buff 167742)
	SpellInfo(defender_of_the_light_buff duration=8)
Define(divine_crusader_buff 144595)
	SpellInfo(divine_crusader_buff duration=12)
Define(divine_hammer 198034)
	SpellInfo(divine_hammer cd=12 holy=-2)
Define(divine_hammer_talent 12)
Define(divine_protection 498)
	SpellInfo(divine_protection cd=60 gcd=0 offgcd=1 tag=cd)
	SpellInfo(divine_protection cd=30 if_spell=unbreakable_spirit)
	SpellAddBuff(divine_protection divine_protection_buff=1)
Define(divine_protection_buff 498)
	SpellInfo(divine_protection_buff duration=8)
Define(divine_purpose 223817)
Define(divine_purpose_buff 223819)
	SpellInfo(divine_purpose_buff duration=12)
Define(divine_shield 642)
	SpellInfo(divine_shield cd=300 gcd=0 offgcd=1)
	SpellInfo(divine_shield cd=150 if_spell=unbreakable_spirit)
	SpellAddBuff(divine_shield divine_shield_buff=1)
	SpellRequire(divine_shield unusable 1=target_debuff,forbearance_debuff)
Define(divine_shield_buff 642)
	SpellInfo(divine_shield_buff duration=8)
Define(divine_steed 190784)
	SpellInfo(divine_steed cd=45)
	SpellAddBuff(divine_steed divine_steed_buff=1)
Define(divine_steed_buff 221886)
	SpellInfo(divine_steed_buff duration=3)
Define(divine_storm 53385)
	SpellInfo(divine_storm holy=3)
	SpellRequire(divine_storm holy 0=buff,divine_storm_no_holy_buff)
	SpellRequire(divine_storm holy 2=buff,the_fires_of_justice_buff)
	SpellAddBuff(divine_storm divine_crusader_buff=0)
	SpellAddBuff(divine_storm divine_purpose_buff=0 if_spell=divine_purpose)
	SpellAddBuff(divine_storm final_verdict_buff=0 if_spell=final_verdict)
SpellList(divine_storm_no_holy_buff divine_crusader_buff divine_purpose_buff)
Define(empowered_divine_storm 174718)
Define(empowered_hammer_of_wrath 157496)
Define(empowered_seals 152263)
Define(empowered_seals_talent 19)
Define(enhanced_hand_of_sacrifice 6940)
Define(enhanced_holy_shock 157478)
Define(enhanced_holy_shock_buff 160002)
	SpellInfo(enhanced_holy_shock_buff duration=15)
Define(eternal_flame 114163)
	SpellInfo(eternal_flame cd=1 holy=finisher max_holy=3)
	SpellInfo(eternal_flame gcd=0 offgcd=1 tag=shortcd)
	SpellRequire(eternal_flame holy 0=buff,word_of_glory_no_holy_buff)
	SpellAddBuff(eternal_flame bastion_of_glory_buff=0 if_spell=shield_of_the_righteous)
	SpellAddBuff(eternal_flame bastion_of_power_buff=0 if_spell=shield_of_the_righteous itemset=T16_tank itemcount=4)
	SpellAddBuff(eternal_flame divine_purpose_buff=0 if_spell=divine_purpose)
	SpellAddBuff(eternal_flame lawful_words_buff=0 itemset=T17 itemcount=4 specialization=holy)
	SpellAddTargetBuff(eternal_flame eternal_flame_buff=1)
Define(eternal_flame_buff 114163)
	SpellInfo(eternal_flame_buff duration=30 haste=spell tick=3)
Define(execution_sentence 213757)
	SpellInfo(execution_sentence cd=20 holy=3)
	SpellRequire(execution_sentence holy 2=buff,the_fires_of_justice_buff)
Define(exorcism 879)
	SpellInfo(exorcism holy=-1 cd=15)
	SpellInfo(exorcism cd_haste=melee if_spell=sanctity_of_battle)
	SpellRequire(exorcism holy -3=buff,exorcism_holy_generator_buff)
	SpellAddBuff(exorcism blazing_contempt_buff=0 itemset=T17 itemcount=4 specialization=retribution)
Define(faith_barricade_buff 165447)
	SpellInfo(faith_barricade_buff duration=5)
Define(final_verdict 157048)
	SpellInfo(final_verdict holy=3)
	SpellRequire(final_verdict holy 0=buff,divine_purpose_buff if_spell=divine_purpose)
	SpellAddBuff(final_verdict divine_purpose_buff=0 if_spell=divine_purpose)
	SpellAddBuff(final_verdict final_verdict_buff=1)
Define(final_verdict_buff 157048)
	SpellInfo(final_verdict_buff duration=30)
Define(fist_of_justice_talent 7)
Define(final_stand_talent 15)
Define(final_verdict_talent 21)
Define(flash_of_light 19750)
	SpellAddBuff(flash_of_light selfless_healer_buff=0 if_spell=selfless_healer)
Define(forbearance_debuff 25771)
	SpellInfo(forbearance_debuff duration=30)
Define(grand_crusader 85043)
Define(grand_crusader_buff 85416)
	SpellInfo(grand_crusader_buff duration=6)
Define(greater_blessing_of_might 203528)
	SpellAddBuff(greater_blessing_of_might greater_blessing_of_might_buff=1)
	SpellRequire(greater_blessing_of_might unusable 1=buff,greater_blessing_of_might_buff)
Define(greater_blessing_of_might_buff 203528)
Define(greater_judgment_talent 6)
Define(guardian_of_ancient_kings 86659)
	SpellInfo(guardian_of_ancient_kings cd=300 gcd=0 offgcd=1)
	SpellAddBuff(guardian_of_ancient_kings guardian_of_ancient_kings_buff=1)
Define(guardian_of_ancient_kings_buff 86659)
	SpellInfo(guardian_of_ancient_kings_buff duration=8)
Define(hammer_of_justice 853)
	SpellInfo(hammer_of_justice cd=60 interrupt=1)
Define(hammer_of_the_righteous 53595)
	SpellInfo(hammer_of_the_righteous holy=-1 cd=4.5)
	SpellInfo(hammer_of_the_righteous cd_haste=melee protection=protection)
	SpellInfo(hammer_of_the_righteous replace=blessed_hammer talent=blessed_hammer_talent)
Define(hammer_of_wrath 24275)
	SpellInfo(hammer_of_wrath cd=6 target_health_pct=20)
	SpellInfo(hammer_of_wrath holy=-1 specialization=retribution)
	SpellInfo(hammer_of_wrath cd_haste=melee if_spell=sanctity_of_battle)
	SpellInfo(hammer_of_wrath replace=hammer_of_wrath_empowered unusable=1 if_spell=empowered_hammer_of_wrath)
	SpellRequire(hammer_of_wrath cd 3=buff,avenging_wrath_melee_buff if_spell=sanctified_wrath)
	SpellRequire(hammer_of_wrath target_health_pct 100=buff,hammer_of_wrath_no_target_health_pct_buff specialization=retribution)
	SpellAddBuff(hammer_of_wrath crusaders_fury_buff=0 itemset=T17 itemcount=2 specialization=retribution)
Define(hammer_of_wrath_empowered 158392)
	SpellInfo(hammer_of_wrath_empowered cd=6 target_health_pct=35)
	SpellInfo(hammer_of_wrath_empowered holy=-1 specialization=retribution)
	SpellInfo(hammer_of_wrath_empowered cd_haste=melee if_spell=sanctity_of_battle)
	SpellRequire(hammer_of_wrath_empowered cd 3=buff,avenging_wrath_melee_buff if_spell=sanctified_wrath)
	SpellRequire(hammer_of_wrath_empowered target_health_pct 100=buff,hammer_of_wrath_no_target_health_pct_buff specialization=retribution)
	SpellAddBuff(hammer_of_wrath_empowered crusaders_fury_buff=0 itemset=T17 itemcount=2 specialization=retribution)
SpellList(hammer_of_wrath_no_target_health_pct_buff avenging_wrath_melee_buff crusaders_fury_buff)
Define(hand_of_freedom 1044)
	SpellInfo(hand_of_freedom cd=25)
Define(hand_of_protection 1022)
	SpellInfo(hand_of_protection cd=300 gcd=0 offgcd=1)
	SpellInfo(hand_of_protection cd=150 if_spell=unbreakable_spirit)
	SpellAddBuff(hand_of_protection hand_of_protection_buff=1)
Define(hand_of_protection_buff 1022)
	SpellInfo(hand_of_protection_buff duration=10)
Define(hand_of_sacrifice 6940)
	SpellInfo(hand_of_sacrifice cd=120 gcd=0 offgcd=1)
	SpellInfo(hand_of_sacrifice addcd=-30 if_spell=enhanced_hand_of_sacrifice)
	SpellAddTargetBuff(hand_of_sacrifice hand_of_sacrifice_buff=1)
Define(hand_of_sacrifice_buff 6940)
	SpellInfo(hand_of_sacrifice_buff duration=10)
Define(hand_of_the_protector 213652)
	SpellInfo(hand_of_the_protector cd=10 cd_haste=melee tag=shortcd)
Define(hand_of_the_protector_talent 13)
Define(harsh_word 136494)
	SpellInfo(harsh_word tag=shortcd)
Define(holy_light 82326)
Define(holy_prism 114165)
	SpellInfo(holy_prism cd=20)
Define(holy_shock 20473)
	SpellInfo(holy_shock cd=6 holy=-1)
	SpellInfo(holy_shock cd_haste=melee if_spell=sanctity_of_battle)
	SpellInfo(holy_shock addcd=-1 itemset=T14_heal itemcount=4)
	SpellRequire(holy_shock cd 0=buff,enhanced_holy_shock_buff if_spell=enhanced_holy_shock)
	SpellRequire(holy_shock cd 3=buff,avenging_wrath_melee_buff if_spell=sanctified_wrath)
Define(holy_wrath 210220)
	SpellInfo(holy_wrath cd=180)
Define(improved_forbearance 157482)
Define(judgment 20271)
	SpellInfo(judgment cd=6)
	SpellInfo(judgment cd_haste=melee specialization=protection)
	SpellInfo(judgment holy=-1 if_spell=judgments_of_the_wise)
	SpellInfo(judgment holy=-1 specialization=retribution)
	SpellRequire(judgment cd 3=buff,avenging_wrath_melee_buff if_spell=sanctified_wrath)
	SpellAddBuff(judgment selfless_healer_buff=1 if_spell=selfless_healer)
Define(judgment_debuff 197277)
	SpellInfo(judgment_debuff duration=8)
Define(justicars_vengeance 215661)
	SpellInfo(justicars_vengeance holy=5)
	SpellRequire(justicars_vengeance holy 4=buff,the_fires_of_justice_buff)
	SpellRequire(justicars_vengeance holy 0=buff,divine_purpose_buff)
Define(knight_templar_talent 14)
Define(lawful_words_buff 166780)
	SpellInfo(lawful_words_buff duration=10)
Define(lay_on_hands 633)
	SpellInfo(lay_on_hands cd=600)
	SpellInfo(lay_on_hands cd=300 if_spell=unbreakable_spirit)
	SpellRequire(lay_on_hands unusable 1=target_debuff,forbearance_debuff)
	SpellAddTargetDebuff(lay_on_hands forbearance_debuff=1)
Define(liadrins_righteousness_buff 156989)
	SpellInfo(liadrins_righteousness_buff duration=20)
Define(light_of_dawn 85222)
	SpellInfo(light_of_dawn holy=finisher max_holy=3)
	SpellRequire(light_of_dawn holy 0=buff,light_of_dawn_no_holy_buff)
SpellList(light_of_dawn_no_holy_buff divine_purpose_buff lights_favor_buff)
Define(light_of_the_protector 184092)
	SpellInfo(light_of_the_protector cd=15 cd_haste=melee tag=shortcd)
	SpellInfo(light_of_the_protector replace=hand_of_the_protector talent=hand_of_the_protector_talent)
Define(lights_favor_buff 166781)
	SpellInfo(lights_favor_buff duration=10)
Define(lights_hammer 114158)
	SpellInfo(lights_hammer cd=60)
Define(lights_hammer_talent 17)
Define(maraads_truth_buff 156990)
	SpellInfo(maraads_truth_buff duration=20)
Define(rebuke 96231)
	SpellInfo(rebuke cd=15 gcd=0 interrupt=1 offgcd=1)
Define(redemption 7328)
Define(righteous_fury 25780)
	SpellAddBuff(righteous_fury righteous_fury_buff=toggle)
Define(righteous_fury_buff 25780)
Define(sacred_shield 20925)
	SpellInfo(sacred_shield cd=6)
	SpellAddBuff(sacred_shield sacred_shield_buff=1)
Define(sacred_shield_buff 20925)
	SpellInfo(sacred_shield duration=30 haste=spell tick=6)
Define(sanctified_wrath 53376)
Define(sanctified_wrath_tank 171648)
Define(sanctified_wrath_talent 14)
Define(selfless_healer 85804)
Define(selfless_healer_buff 114250)
	SpellInfo(selfless_healer_buff duration=15 max_stacks=3)
Define(selfless_healer_talent 7)
Define(seraphim 152262)
	SpellInfo(seraphim cd=30 gcd=0)
Define(seraphim_buff 152262)
	SpellInfo(seraphim_buff duration=15)
Define(seraphim_talent 20)
Define(shield_of_the_righteous 53600)
	SpellInfo(shield_of_the_righteous cd=1 gcd=0 offgcd=1)
	SpellInfo(shield_of_the_righteous cd_haste=melee haste=melee specialization=protection)
	SpellAddBuff(shield_of_the_righteous shield_of_the_righteous_buff=1)
Define(shield_of_the_righteous_buff 132403)
	SpellInfo(shield_of_the_righteous_buff duration=4)
Define(shield_of_vengeance 184662)
	SpellInfo(shield_of_vengeance cd=90)
Define(speed_of_light 85499)
	SpellInfo(speed_of_light cd=45 gcd=0 offgcd=1)
Define(t18_class_trinket 124518)
Define(templars_verdict 85256)
	SpellInfo(templars_verdict holy=3)
	SpellRequire(templars_verdict holy 2=buff,the_fires_of_justice_buff talent=the_fires_of_justice_talent)
	SpellRequire(templars_verdict holy 0=buff,divine_purpose_buff if_spell=divine_purpose)
	SpellAddBuff(templars_verdict divine_purpose_buff=0 if_spell=divine_purpose)
Define(the_fires_of_justice_buff 209785)
	SpellInfo(the_fires_of_justice_buff duration=15)
Define(the_fires_of_justice_talent 4)
Define(unbreakable_spirit 114154)
Define(uthers_insight_buff 156988)
	SpellInfo(uthers_insight_buff duration=21 haste=spell tick=3)
Define(virtues_blade_talent 10)
Define(wake_of_ashes 205273)
	SpellInfo(wake_of_ashes cd=30 tag=main)
Define(whisper_of_the_nathrezim 137020)
Define(whisper_of_the_nathrezim_buff 207633)
Define(wings_of_liberty_buff 185647)
	SpellInfo(wings_of_liberty_buff duration=10 max_stacks=10)
Define(word_of_glory 85673)
	SpellInfo(word_of_glory cd=1 holy=finisher max_holy=3)
	SpellInfo(word_of_glory gcd=0 offgcd=1)
	SpellRequire(word_of_glory holy 0=buff,word_of_glory_no_holy_buff)
	SpellAddBuff(word_of_glory bastion_of_glory_buff=0 if_spell=shield_of_the_righteous)
	SpellAddBuff(word_of_glory bastion_of_power_buff=0 if_spell=shield_of_the_righteous itemset=T16_tank itemcount=4)
	SpellAddBuff(word_of_glory divine_purpose_buff=0 if_spell=divine_purpose)
	SpellAddBuff(word_of_glory lawful_words_buff=0 itemset=T17 itemcount=4 specialization=holy)
SpellList(word_of_glory_no_holy_buff bastion_of_power_buff divine_purpose_buff lawful_words_buff)
Define(zeal 217020)
	SpellInfo(zeal cd=4.5 holy=-1)

# Artifacts
Define(eye_of_tyr 209202)
	SpellInfo(eye_of_tyr cd=60)
	SpellAddTargetDebuff(eye_of_tyr eye_of_tyr_debuff=1)
Define(eye_of_tyr_debuff 209202)
	SpellInfo(eye_of_tyr_debuff duration=9)

# Talents
Define(bastion_of_light_talent 5)
Define(righteous_protector_talent 19)
Define(seraphim_talent 20)
Define(crusaders_judgment_talent 6)
Define(zeal_talent 5)
]]

	OvaleScripts:RegisterScript("PALADIN", nil, name, desc, code, "include")
end
