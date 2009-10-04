Ovale.defaut["PALADIN"] = 
[[
Define(SEALRIGHTEOUSNESS 21084)
Define(SEALCOMMAND 20375)
Define(SEALVENGEANCE 31801)
Define(SEALCORRUPTION 53736)
Define(JUDGELIGHT 20271)
Define(JUDGEWISDOM 53408)
Define(CONSECRATE 26573)
Define(DIVINESTORM 53385)
Define(HAMMEROFWRATH 24275)
Define(CRUSADERSTRIKE 35395)
Define(HOLYSHOCK 20473)
Define(THEARTOFWAR 59578)
Define(FLASHOFLIGHT 19750)
Define(EXORCISM 879)
Define(AVENGINGWRATH 31884)
Define(SHIELDOFRIGHTEOUSNESS 53600)
Define(HOLYSHIELD 20925)
Define(HAMMEROFTHERIGHTEOUS 53595)
Define(HOLYWRATH 2812)

AddListItem(sceau piete SpellName(SEALRIGHTEOUSNESS))
AddListItem(sceau autorite SpellName(SEALCOMMAND))
AddListItem(sceau vengeance SpellName(SEALVENGEANCE))
AddListItem(jugement lumiere SpellName(JUDGELIGHT))
AddListItem(jugement sagesse SpellName(JUDGEWISDOM))
AddCheckBox(consecration SpellName(CONSECRATE))
AddCheckBox(tempete SpellName(DIVINESTORM))
AddCheckBox(coleredivine SpellName(HOLYWRATH))
ScoreSpells(SEALRIGHTEOUSNESS SEALCOMMAND SEALVENGEANCE SEALCORRUPTION HOLYSHIELD HAMMEROFTHERIGHTEOUS CRUSADERSTRIKE
	HAMMEROFWRATH JUDGELIGHT JUDGEWISDOM DIVINESTORM CONSECRATE EXORCISM HOLYWRATH HOLYSHOCK SHIELDOFRIGHTEOUSNESS)

AddIcon
{
     if List(sceau piete) and BuffExpires(SEALRIGHTEOUSNESS 3) Spell(SEALRIGHTEOUSNESS)
     if List(sceau autorite) and BuffExpires(SEALCOMMAND 3) Spell(SEALCOMMAND)
     if List(sceau vengeance)
     {
          if BuffExpires(SEALVENGEANCE 3) Spell(SEALVENGEANCE)
          if BuffExpires(SEALCORRUPTION 3) Spell(SEALCORRUPTION)
     }
     if TargetTargetIsPlayer(yes) Spell(HOLYSHIELD)
     Spell(HAMMEROFTHERIGHTEOUS)
     
     Spell(CRUSADERSTRIKE)
     Spell(HAMMEROFWRATH usable=1)
     if List(jugement lumiere) Spell(JUDGELIGHT)
     if List(jugement sagesse) Spell(JUDGEWISDOM)
     if CheckBoxOn(tempete) Spell(DIVINESTORM)
     if CheckBoxOn(consecration) Spell(CONSECRATE)
     if BuffPresent(THEARTOFWAR) Spell(EXORCISM)
     if CheckBoxOn(coleredivine) Spell(HOLYWRATH)
     
     Spell(HOLYSHOCK) 
     if HasShield() Spell(SHIELDOFRIGHTEOUSNESS)
     if BuffPresent(THEARTOFWAR) Spell(FLASHOFLIGHT priority=2)
}

AddIcon
{
     Spell(AVENGINGWRATH)
     Item(Trinket0Slot usable=1)
     Item(Trinket1Slot usable=1)
}
]]
