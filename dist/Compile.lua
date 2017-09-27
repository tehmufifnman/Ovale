local OVALE, Ovale = ...
require(OVALE, Ovale, "Compile", { "./L", "./OvaleDebug", "./OvaleProfiler", "./db", "./checkBox", "./db", "./list", "./checkBox", "./list" }, function(__exports, __L, __OvaleDebug, __OvaleProfiler, __db, __checkBox, __db, __list, __checkBox, __list)
local OvaleCompile = Ovale:NewModule("OvaleCompile", "AceEvent-3.0")
Ovale.OvaleCompile = OvaleCompile
local OvaleArtifact = nil
local OvaleAST = nil
local OvaleCondition = nil
local OvaleCooldown = nil
local OvaleData = nil
local OvaleEquipment = nil
local OvalePaperDoll = nil
local OvalePower = nil
local OvaleScore = nil
local OvaleScripts = nil
local OvaleSpellBook = nil
local OvaleStance = nil
local _ipairs = ipairs
local _pairs = pairs
local _tonumber = tonumber
local _tostring = tostring
local _type = type
local strfind = string.find
local strmatch = string.match
local strsub = string.sub
local _wipe = wipe
local API_GetSpellInfo = GetSpellInfo
__OvaleDebug.OvaleDebug:RegisterDebugging(OvaleCompile)
__OvaleProfiler.OvaleProfiler:RegisterProfiling(OvaleCompile)
local self_compileOnStances = false
local self_canEvaluate = false
local self_requirePreload = {
    1 = "OvaleEquipment",
    2 = "OvaleSpellBook",
    3 = "OvaleStance"
}
local self_serial = 0
local self_timesEvaluated = 0
local self_icon = {}
local NUMBER_PATTERN = "^%-?%d+%.?%d*$"
OvaleCompile.serial = nil
OvaleCompile.ast = nil
local HasTalent = function(talentId)
    if OvaleSpellBook:IsKnownTalent(talentId) then
        return OvaleSpellBook:GetTalentPoints(talentId) > 0
    else
        OvaleCompile:Print("Warning: unknown talent ID '%s'", talentId)
        return false
    end
end
local RequireValue = function(value)
    local required = (strsub(_tostring(value), 1, 1) ~= "!")
    if  not required then
        value = strsub(value, 2)
        if strmatch(value, NUMBER_PATTERN) then
            value = _tonumber(value)
        end
    end
    return value, required
end
local TestConditionLevel = function(value)
    return OvalePaperDoll.level >= value
end
local TestConditionMaxLevel = function(value)
    return OvalePaperDoll.level <= value
end
local TestConditionSpecialization = function(value)
    local spec, required = RequireValue(value)
    local isSpec = OvalePaperDoll:IsSpecialization(spec)
    return (required and isSpec) or ( not required and  not isSpec)
end
local TestConditionStance = function(value)
    self_compileOnStances = true
    local stance, required = RequireValue(value)
    local isStance = OvaleStance:IsStance(stance)
    return (required and isStance) or ( not required and  not isStance)
end
local TestConditionSpell = function(value)
    local spell, required = RequireValue(value)
    local hasSpell = OvaleSpellBook:IsKnownSpell(spell)
    return (required and hasSpell) or ( not required and  not hasSpell)
end
local TestConditionTalent = function(value)
    local talent, required = RequireValue(value)
    local hasTalent = HasTalent(talent)
    return (required and hasTalent) or ( not required and  not hasTalent)
end
local TestConditionEquipped = function(value)
    local item, required = RequireValue(value)
    local hasItemEquipped = OvaleEquipment:HasEquippedItem(item)
    return (required and hasItemEquipped) or ( not required and  not hasItemEquipped)
end
local TestConditionTrait = function(value)
    local trait, required = RequireValue(value)
    local hasTrait = OvaleArtifact:HasTrait(trait)
    return (required and hasTrait) or ( not required and  not hasTrait)
end
local TEST_CONDITION_DISPATCH = {
    if_spell = TestConditionSpell,
    if_equipped = TestConditionEquipped,
    if_stance = TestConditionStance,
    level = TestConditionLevel,
    maxLevel = TestConditionMaxLevel,
    specialization = TestConditionSpecialization,
    talent = TestConditionTalent,
    trait = TestConditionTrait,
    pertrait = TestConditionTrait
}
local TestConditions = function(positionalParams, namedParams)
    OvaleCompile:StartProfiling("OvaleCompile_TestConditions")
    local boolean = true
    for param, dispatch in _pairs(TEST_CONDITION_DISPATCH) do
        local value = namedParams[param]
        if _type(value) == "table" then
            for _, v in _ipairs(value) do
                boolean = dispatch(v)
                if  not boolean then
                    break
                end
            end
        elseif value then
            boolean = dispatch(value)
        end
        if  not boolean then
            break
        end
    end
    if boolean and namedParams.itemset and namedParams.itemcount then
        local equippedCount = OvaleEquipment:GetArmorSetCount(namedParams.itemset)
        boolean = (equippedCount >= namedParams.itemcount)
    end
    if boolean and namedParams.checkbox then
        for _, checkbox in _ipairs(namedParams.checkbox) do
            local name, required = RequireValue(checkbox)
            __checkBox.control.triggerEvaluation = true
            Ovale.checkBox[name] = __checkBox.control
            local isChecked = __db.profile.check[name]
            boolean = (required and isChecked) or ( not required and  not isChecked)
            if  not boolean then
                break
            end
        end
    end
    if boolean and namedParams.listitem then
        for name, listitem in _pairs(namedParams.listitem) do
            local item, required = RequireValue(listitem)
            __list.control.triggerEvaluation = true
            Ovale.list[name] = __list.control
            local isSelected = (__db.profile.list[name] == item)
            boolean = (required and isSelected) or ( not required and  not isSelected)
            if  not boolean then
                break
            end
        end
    end
    OvaleCompile:StopProfiling("OvaleCompile_TestConditions")
    return boolean
end
local EvaluateAddCheckBox = function(node)
    local ok = true
    local name, positionalParams, namedParams = node.name, node.positionalParams, node.namedParams
    if TestConditions(positionalParams, namedParams) then
        if  not __checkBox.checkBox then
            self_serial = self_serial + 1
            OvaleCompile:Debug("New checkbox '%s': advance age to %d.", name, self_serial)
        end
        __checkBox.checkBox = __checkBox.checkBox or {}
        __checkBox.checkBox.text = node.description.value
        for _, v in _ipairs(positionalParams) do
            if v == "default" then
                __checkBox.checkBox.checked = true
                break
            end
        end
        Ovale.checkBox[name] = __checkBox.checkBox
    end
    return ok
end
local EvaluateAddIcon = function(node)
    local ok = true
    local positionalParams, namedParams = node.positionalParams, node.namedParams
    if TestConditions(positionalParams, namedParams) then
        self_icon[#self_icon + 1] = node
    end
    return ok
end
local EvaluateAddListItem = function(node)
    local ok = true
    local name, item, positionalParams, namedParams = node.name, node.item, node.positionalParams, node.namedParams
    if TestConditions(positionalParams, namedParams) then
        if  not (__list.list and __list.list.items and __list.list.items[item]) then
            self_serial = self_serial + 1
            OvaleCompile:Debug("New list '%s': advance age to %d.", name, self_serial)
        end
        __list.list = __list.list or {
            items = {},
            default = nil
        }
        __list.list.items[item] = node.description.value
        for _, v in _ipairs(positionalParams) do
            if v == "default" then
                __list.list.default = item
                break
            end
        end
        Ovale.list[name] = __list.list
    end
    return ok
end
local EvaluateItemInfo = function(node)
    local ok = true
    local itemId, positionalParams, namedParams = node.itemId, node.positionalParams, node.namedParams
    if itemId and TestConditions(positionalParams, namedParams) then
        local ii = OvaleData:ItemInfo(itemId)
        for k, v in _pairs(namedParams) do
            if k == "proc" then
                local buff = _tonumber(namedParams.buff)
                if buff then
                    local name = "item_proc_" + namedParams.proc
                    local __list.list = OvaleData.buffSpellList[name] or {}
                    __list.list[buff] = true
                    OvaleData.buffSpellList[name] = __list.list
                else
                    ok = false
                    break
                end
            elseif  not OvaleAST.PARAMETER_KEYWORD[k] then
                ii[k] = v
            end
        end
        OvaleData.itemInfo[itemId] = ii
    end
    return ok
end
local EvaluateItemRequire = function(node)
    local ok = true
    local itemId, positionalParams, namedParams = node.itemId, node.positionalParams, node.namedParams
    if TestConditions(positionalParams, namedParams) then
        local property = node.property
        local count = 0
        local ii = OvaleData:ItemInfo(itemId)
        local tbl = ii.require[property] or {}
        for k, v in _pairs(namedParams) do
            if  not OvaleAST.PARAMETER_KEYWORD[k] then
                tbl[k] = v
                count = count + 1
            end
        end
        if count > 0 then
            ii.require[property] = tbl
        end
    end
    return ok
end
local EvaluateList = function(node)
    local ok = true
    local name, positionalParams, namedParams = node.name, node.positionalParams, node.namedParams
    local listDB
    if node.keyword == "ItemList" then
        listDB = "itemList"
    else
        listDB = "buffSpellList"
    end
    local __list.list = OvaleData[listDB][name] or {}
    for _, id in _pairs(positionalParams) do
        id = _tonumber(id)
        if id then
            __list.list[id] = true
        else
            ok = false
            break
        end
    end
    OvaleData[listDB][name] = __list.list
    return ok
end
local EvaluateScoreSpells = function(node)
    local ok = true
    local positionalParams, namedParams = node.positionalParams, node.namedParams
    for _, spellId in _ipairs(positionalParams) do
        spellId = _tonumber(spellId)
        if spellId then
            OvaleScore:AddSpell(_tonumber(spellId))
        else
            ok = false
            break
        end
    end
    return ok
end
local EvaluateSpellAuraList = function(node)
    local ok = true
    local spellId, positionalParams, namedParams = node.spellId, node.positionalParams, node.namedParams
    if  not spellId then
        OvaleCompile:Print("No spellId for name %s", node.name)
        return false
    end
    if TestConditions(positionalParams, namedParams) then
        local keyword = node.keyword
        local si = OvaleData:SpellInfo(spellId)
        local auraTable
        if strfind(keyword, "^SpellDamage") then
            auraTable = si.aura.damage
        elseif strfind(keyword, "^SpellAddPet") then
            auraTable = si.aura.pet
        elseif strfind(keyword, "^SpellAddTarget") then
            auraTable = si.aura.target
        else
            auraTable = si.aura.player
        end
        local filter = strfind(node.keyword, "Debuff") and "HARMFUL" or "HELPFUL"
        local tbl = auraTable[filter] or {}
        local count = 0
        for k, v in _pairs(namedParams) do
            if  not OvaleAST.PARAMETER_KEYWORD[k] then
                tbl[k] = v
                count = count + 1
            end
        end
        if count > 0 then
            auraTable[filter] = tbl
        end
    end
    return ok
end
local EvaluateSpellInfo = function(node)
    local addpower = {}
    for powertype, _ in _pairs(OvalePower.POWER_INFO) do
        local key = "add" + powertype
        addpower[key] = powertype
    end
    local ok = true
    local spellId, positionalParams, namedParams = node.spellId, node.positionalParams, node.namedParams
    if spellId and TestConditions(positionalParams, namedParams) then
        local si = OvaleData:SpellInfo(spellId)
        for k, v in _pairs(namedParams) do
            if k == "addduration" then
                local value = _tonumber(v)
                if value then
                    local realValue = value
                    if namedParams.pertrait ~= nil then
                        realValue = value * OvaleArtifact:TraitRank(namedParams.pertrait)
                    end
                    local addDuration = si.addduration or 0
                    si.addduration = addDuration + realValue
                else
                    ok = false
                    break
                end
            elseif k == "addcd" then
                local value = _tonumber(v)
                if value then
                    local addCd = si.addcd or 0
                    si.addcd = addCd + value
                else
                    ok = false
                    break
                end
            elseif k == "addlist" then
                local __list.list = OvaleData.buffSpellList[v] or {}
                __list.list[spellId] = true
                OvaleData.buffSpellList[v] = __list.list
            elseif k == "dummy_replace" then
                local spellName = API_GetSpellInfo(v) or v
                OvaleSpellBook:AddSpell(spellId, spellName)
            elseif k == "learn" and v == 1 then
                local spellName = API_GetSpellInfo(spellId)
                OvaleSpellBook:AddSpell(spellId, spellName)
            elseif k == "sharedcd" then
                si[k] = v
                OvaleCooldown:AddSharedCooldown(v, spellId)
            elseif addpower[k] ~= nil then
                local powertype = addpower[k]
                local value = _tonumber(v)
                if value then
                    local realValue = value
                    if namedParams.pertrait ~= nil then
                        realValue = value * OvaleArtifact:TraitRank(namedParams.pertrait)
                    end
                    local power = si[k] or 0
                    si[k] = power + realValue
                else
                    ok = false
                    break
                end
            elseif  not OvaleAST.PARAMETER_KEYWORD[k] then
                si[k] = v
            end
        end
    end
    return ok
end
local EvaluateSpellRequire = function(node)
    local ok = true
    local spellId, positionalParams, namedParams = node.spellId, node.positionalParams, node.namedParams
    if TestConditions(positionalParams, namedParams) then
        local property = node.property
        local count = 0
        local si = OvaleData:SpellInfo(spellId)
        local tbl = si.require[property] or {}
        for k, v in _pairs(namedParams) do
            if  not OvaleAST.PARAMETER_KEYWORD[k] then
                tbl[k] = v
                count = count + 1
            end
        end
        if count > 0 then
            si.require[property] = tbl
        end
    end
    return ok
end
local AddMissingVariantSpells = function(annotation)
    if annotation.functionReference then
        for _, node in _ipairs(annotation.functionReference) do
            local positionalParams, namedParams = node.positionalParams, node.namedParams
            local spellId = positionalParams[1]
            if spellId and OvaleCondition:IsSpellBookCondition(node.func) then
                if  not OvaleSpellBook:IsKnownSpell(spellId) and  not OvaleCooldown:IsSharedCooldown(spellId) then
                    local spellName
                    if _type(spellId) == "number" then
                        spellName = OvaleSpellBook:GetSpellName(spellId)
                    end
                    if spellName then
                        local name = API_GetSpellInfo(spellName)
                        if spellName == name then
                            OvaleCompile:Debug("Learning spell %s with ID %d.", spellName, spellId)
                            OvaleSpellBook:AddSpell(spellId, spellName)
                        end
                    else
                        local functionCall = node.name
                        if node.paramsAsString then
                            functionCall = node.name + "(" + node.paramsAsString + ")"
                        end
                        OvaleCompile:Print("Unknown spell with ID %s used in %s.", spellId, functionCall)
                    end
                end
            end
        end
    end
end
local AddToBuffList = function(buffId, statName, isStacking)
    if statName then
        for _, useName in _pairs(OvaleData.STAT_USE_NAMES) do
            if isStacking or  not strfind(useName, "_stacking_") then
                local name = useName + "_" + statName + "_buff"
                local __list.list = OvaleData.buffSpellList[name] or {}
                __list.list[buffId] = true
                OvaleData.buffSpellList[name] = __list.list
                local shortStatName = OvaleData.STAT_SHORTNAME[statName]
                if shortStatName then
                    name = useName + "_" + shortStatName + "_buff"
                    __list.list = OvaleData.buffSpellList[name] or {}
                    __list.list[buffId] = true
                    OvaleData.buffSpellList[name] = __list.list
                end
                name = useName + "_any_buff"
                __list.list = OvaleData.buffSpellList[name] or {}
                __list.list[buffId] = true
                OvaleData.buffSpellList[name] = __list.list
            end
        end
    else
        local si = OvaleData.spellInfo[buffId]
        isStacking = si and (si.stacking == 1 or si.max_stacks)
        if si and si.stat then
            local stat = si.stat
            if _type(stat) == "table" then
                for _, name in _ipairs(stat) do
                    AddToBuffList(buffId, name, isStacking)
                end
            else
                AddToBuffList(buffId, stat, isStacking)
            end
        end
    end
end
local UpdateTrinketInfo = nil
do
    local trinket = {}
    UpdateTrinketInfo = function()
        trinket[1], trinket[2] = OvaleEquipment:GetEquippedTrinkets()
        for i = 1, 2, 1 do
            local itemId = trinket[i]
            local ii = itemId and OvaleData:ItemInfo(itemId)
            local buffId = ii and ii.buff
            if buffId then
                if _type(buffId) == "table" then
                    for _, id in _ipairs(buffId) do
                        AddToBuffList(id)
                    end
                else
                    AddToBuffList(buffId)
                end
            end
        end
    end
end
local OvaleCompile = __class()
function OvaleCompile:OnInitialize()
    OvaleArtifact = Ovale.OvaleArtifact
    OvaleAST = Ovale.OvaleAST
    OvaleCondition = Ovale.OvaleCondition
    OvaleCooldown = Ovale.OvaleCooldown
    OvaleData = Ovale.OvaleData
    OvaleEquipment = Ovale.OvaleEquipment
    OvalePaperDoll = Ovale.OvalePaperDoll
    OvalePower = Ovale.OvalePower
    OvaleScore = Ovale.OvaleScore
    OvaleScripts = Ovale.OvaleScripts
    OvaleSpellBook = Ovale.OvaleSpellBook
    OvaleStance = Ovale.OvaleStance
end
function OvaleCompile:OnEnable()
    self:RegisterMessage("Ovale_CheckBoxValueChanged", "ScriptControlChanged")
    self:RegisterMessage("Ovale_EquipmentChanged", "EventHandler")
    self:RegisterMessage("Ovale_ListValueChanged", "ScriptControlChanged")
    self:RegisterMessage("Ovale_ScriptChanged")
    self:RegisterMessage("Ovale_SpecializationChanged", "Ovale_ScriptChanged")
    self:RegisterMessage("Ovale_SpellsChanged", "EventHandler")
    self:RegisterMessage("Ovale_StanceChanged")
    self:RegisterMessage("Ovale_TalentsChanged", "EventHandler")
    self:SendMessage("Ovale_ScriptChanged")
end
function OvaleCompile:OnDisable()
    self:UnregisterMessage("Ovale_CheckBoxValueChanged")
    self:UnregisterMessage("Ovale_EquipmentChanged")
    self:UnregisterMessage("Ovale_ListValueChanged")
    self:UnregisterMessage("Ovale_ScriptChanged")
    self:UnregisterMessage("Ovale_SpecializationChanged")
    self:UnregisterMessage("Ovale_SpellsChanged")
    self:UnregisterMessage("Ovale_StanceChanged")
    self:UnregisterMessage("Ovale_TalentsChanged")
end
function OvaleCompile:Ovale_ScriptChanged(event)
    self:CompileScript(Ovale.db.profile.source)
    self:EventHandler(event)
end
function OvaleCompile:Ovale_StanceChanged(event)
    if self_compileOnStances then
        self:EventHandler(event)
    end
end
function OvaleCompile:ScriptControlChanged(event, name)
    if  not name then
        self:EventHandler(event)
    else
        local __list.control
        if event == "Ovale_CheckBoxValueChanged" then
            __list.control = Ovale.checkBox[name]
        elseif event == "Ovale_ListValueChanged" then
            __list.control = Ovale.list[name]
        end
        if __list.control and __list.control.triggerEvaluation then
            self:EventHandler(event)
        end
    end
end
function OvaleCompile:EventHandler(event)
    self_serial = self_serial + 1
    self:Debug("%s: advance age to %d.", event, self_serial)
    Ovale.refreshNeeded[Ovale.playerGUID] = true
end
function OvaleCompile:CompileScript(name)
    __OvaleDebug.OvaleDebug:ResetTrace()
    self:Debug("Compiling script '%s'.", name)
    if self.ast then
        OvaleAST:Release(self.ast)
        self.ast = nil
    end
    self.ast = OvaleAST:ParseScript(name)
    Ovale:ResetControls()
end
function OvaleCompile:EvaluateScript(ast, forceEvaluation)
    self:StartProfiling("OvaleCompile_EvaluateScript")
    if _type(ast) ~= "table" then
        forceEvaluation = ast
        ast = self.ast
    end
    local changed = false
    self_canEvaluate = self_canEvaluate or Ovale:IsPreloaded(self_requirePreload)
    if self_canEvaluate and ast and (forceEvaluation or  not self.serial or self.serial < self_serial) then
        self:Debug("Evaluating script.")
        changed = true
        local ok = true
        self_compileOnStances = false
        _wipe(self_icon)
        OvaleData:Reset()
        OvaleCooldown:ResetSharedCooldowns()
        self_timesEvaluated = self_timesEvaluated + 1
        self.serial = self_serial
        for _, node in _ipairs(ast.child) do
            local nodeType = node.type
            if nodeType == "checkbox" then
                ok = EvaluateAddCheckBox(node)
            elseif nodeType == "icon" then
                ok = EvaluateAddIcon(node)
            elseif nodeType == "list_item" then
                ok = EvaluateAddListItem(node)
            elseif nodeType == "item_info" then
                ok = EvaluateItemInfo(node)
            elseif nodeType == "item_require" then
                ok = EvaluateItemRequire(node)
            elseif nodeType == "list" then
                ok = EvaluateList(node)
            elseif nodeType == "score_spells" then
                ok = EvaluateScoreSpells(node)
            elseif nodeType == "spell_aura_list" then
                ok = EvaluateSpellAuraList(node)
            elseif nodeType == "spell_info" then
                ok = EvaluateSpellInfo(node)
            elseif nodeType == "spell_require" then
                ok = EvaluateSpellRequire(node)
            else
            end
            if  not ok then
                break
            end
        end
        if ok then
            AddMissingVariantSpells(ast.annotation)
            UpdateTrinketInfo()
        end
    end
    self:StopProfiling("OvaleCompile_EvaluateScript")
    return changed
end
function OvaleCompile:GetFunctionNode(name)
    local node
    if self.ast and self.ast.annotation and self.ast.annotation.customFunction then
        node = self.ast.annotation.customFunction[name]
    end
    return node
end
function OvaleCompile:GetIconNodes()
    return self_icon
end
function OvaleCompile:DebugCompile()
    self:Print("Total number of times the script was evaluated: %d", self_timesEvaluated)
end
end))
