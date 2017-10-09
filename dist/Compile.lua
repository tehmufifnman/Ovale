local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./Compile", { "./Debug", "./Profiler", "./Artifact", "./AST", "./Condition", "./Cooldown", "./Data", "./Equipment", "./PaperDoll", "./Power", "./Score", "./SpellBook", "./Stance", "./Ovale", "./Controls" }, function(__exports, __Debug, __Profiler, __Artifact, __AST, __Condition, __Cooldown, __Data, __Equipment, __PaperDoll, __Power, __Score, __SpellBook, __Stance, __Ovale, __Controls)
local OvaleCompileBase = __Ovale.Ovale:NewModule("OvaleCompile", "AceEvent-3.0")
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
local self_compileOnStances = false
local self_canEvaluate = false
local self_serial = 0
local self_timesEvaluated = 0
local self_icon = {}
local NUMBER_PATTERN = "^%-?%d+%.?%d*$"
local HasTalent = function(talentId)
    if __SpellBook.OvaleSpellBook:IsKnownTalent(talentId) then
        return __SpellBook.OvaleSpellBook:GetTalentPoints(talentId) > 0
    else
        __exports.OvaleCompile:Print("Warning: unknown talent ID '%s'", talentId)
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
    return __PaperDoll.OvalePaperDoll.level >= value
end

local TestConditionMaxLevel = function(value)
    return __PaperDoll.OvalePaperDoll.level <= value
end

local TestConditionSpecialization = function(value)
    local spec, required = RequireValue(value)
    local isSpec = __PaperDoll.OvalePaperDoll:IsSpecialization(spec)
    return (required and isSpec) or ( not required and  not isSpec)
end

local TestConditionStance = function(value)
    self_compileOnStances = true
    local stance, required = RequireValue(value)
    local isStance = __Stance.OvaleStance:IsStance(stance)
    return (required and isStance) or ( not required and  not isStance)
end

local TestConditionSpell = function(value)
    local spell, required = RequireValue(value)
    local hasSpell = __SpellBook.OvaleSpellBook:IsKnownSpell(spell)
    return (required and hasSpell) or ( not required and  not hasSpell)
end

local TestConditionTalent = function(value)
    local talent, required = RequireValue(value)
    local hasTalent = HasTalent(talent)
    return (required and hasTalent) or ( not required and  not hasTalent)
end

local TestConditionEquipped = function(value)
    local item, required = RequireValue(value)
    local hasItemEquipped = __Equipment.OvaleEquipment:HasEquippedItem(item)
    return (required and hasItemEquipped) or ( not required and  not hasItemEquipped)
end

local TestConditionTrait = function(value)
    local trait, required = RequireValue(value)
    local hasTrait = __Artifact.OvaleArtifact:HasTrait(trait)
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
    __exports.OvaleCompile:StartProfiling("OvaleCompile_TestConditions")
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
        local equippedCount = __Equipment.OvaleEquipment:GetArmorSetCount(namedParams.itemset)
        boolean = (equippedCount >= namedParams.itemcount)
    end
    if boolean and namedParams.checkbox then
        local profile = __Ovale.Ovale.db.profile
        for _, checkbox in _ipairs(namedParams.checkbox) do
            local name, required = RequireValue(checkbox)
            local control = __Controls.checkBoxes[name] or {}
            control.triggerEvaluation = true
            __Controls.checkBoxes[name] = control
            local isChecked = profile.check[name]
            boolean = (required and isChecked) or ( not required and  not isChecked)
            if  not boolean then
                break
            end
        end
    end
    if boolean and namedParams.listitem then
        local profile = __Ovale.Ovale.db.profile
        for name, listitem in _pairs(namedParams.listitem) do
            local item, required = RequireValue(listitem)
            local control = __Controls.lists[name] or {
                items = {},
                default = nil
            }
            control.triggerEvaluation = true
            __Controls.lists[name] = control
            local isSelected = (profile.list[name] == item)
            boolean = (required and isSelected) or ( not required and  not isSelected)
            if  not boolean then
                break
            end
        end
    end
    __exports.OvaleCompile:StopProfiling("OvaleCompile_TestConditions")
    return boolean
end

local EvaluateAddCheckBox = function(node)
    local ok = true
    local name, positionalParams, namedParams = node.name, node.positionalParams, node.namedParams
    if TestConditions(positionalParams, namedParams) then
        local checkBox = __Controls.checkBoxes[name]
        if  not checkBox then
            self_serial = self_serial + 1
            __exports.OvaleCompile:Debug("New checkbox '%s': advance age to %d.", name, self_serial)
        end
        checkBox = checkBox or {}
        checkBox.text = node.description.value
        for _, v in _ipairs(positionalParams) do
            if v == "default" then
                checkBox.checked = true
                break
            end
        end
        __Controls.checkBoxes[name] = checkBox
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
        local list = __Controls.lists[name]
        if  not (list and list.items and list.items[item]) then
            self_serial = self_serial + 1
            __exports.OvaleCompile:Debug("New list '%s': advance age to %d.", name, self_serial)
        end
        list = list or {
            items = {},
            default = nil
        }
        list.items[item] = node.description.value
        for _, v in _ipairs(positionalParams) do
            if v == "default" then
                list.default = item
                break
            end
        end
        __Controls.lists[name] = list
    end
    return ok
end

local EvaluateItemInfo = function(node)
    local ok = true
    local itemId, positionalParams, namedParams = node.itemId, node.positionalParams, node.namedParams
    if itemId and TestConditions(positionalParams, namedParams) then
        local ii = __Data.OvaleData:ItemInfo(itemId)
        for k, v in _pairs(namedParams) do
            if k == "proc" then
                local buff = _tonumber(namedParams.buff)
                if buff then
                    local name = "item_proc_" + namedParams.proc
                    local list = __Data.OvaleData.buffSpellList[name] or {}
                    list[buff] = true
                    __Data.OvaleData.buffSpellList[name] = list
                else
                    ok = false
                    break
                end
            elseif  not __AST.OvaleAST.PARAMETER_KEYWORD[k] then
                ii[k] = v
            end
        end
        __Data.OvaleData.itemInfo[itemId] = ii
    end
    return ok
end

local EvaluateItemRequire = function(node)
    local ok = true
    local itemId, positionalParams, namedParams = node.itemId, node.positionalParams, node.namedParams
    if TestConditions(positionalParams, namedParams) then
        local property = node.property
        local count = 0
        local ii = __Data.OvaleData:ItemInfo(itemId)
        local tbl = ii.require[property] or {}
        for k, v in _pairs(namedParams) do
            if  not __AST.OvaleAST.PARAMETER_KEYWORD[k] then
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
    local name, positionalParams = node.name, node.positionalParams, node.namedParams
    local listDB
    if node.keyword == "ItemList" then
        listDB = "itemList"
    else
        listDB = "buffSpellList"
    end
    local list = __Data.OvaleData[listDB][name] or {}
    for _, _id in _pairs(positionalParams) do
        local id = _tonumber(_id)
        if id then
            list[id] = true
        else
            ok = false
            break
        end
    end
    __Data.OvaleData[listDB][name] = list
    return ok
end

local EvaluateScoreSpells = function(node)
    local ok = true
    local positionalParams = node.positionalParams, node.namedParams
    for _, _spellId in _ipairs(positionalParams) do
        local spellId = _tonumber(_spellId)
        if spellId then
            __Score.OvaleScore:AddSpell(_tonumber(spellId))
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
        __exports.OvaleCompile:Print("No spellId for name %s", node.name)
        return false
    end
    if TestConditions(positionalParams, namedParams) then
        local keyword = node.keyword
        local si = __Data.OvaleData:SpellInfo(spellId)
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
            if  not __AST.OvaleAST.PARAMETER_KEYWORD[k] then
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
    for powertype in _pairs(__Power.OvalePower.POWER_INFO) do
        local key = "add" + powertype
        addpower[key] = powertype
    end
    local ok = true
    local spellId, positionalParams, namedParams = node.spellId, node.positionalParams, node.namedParams
    if spellId and TestConditions(positionalParams, namedParams) then
        local si = __Data.OvaleData:SpellInfo(spellId)
        for k, v in _pairs(namedParams) do
            if k == "addduration" then
                local value = _tonumber(v)
                if value then
                    local realValue = value
                    if namedParams.pertrait ~= nil then
                        realValue = value * __Artifact.OvaleArtifact:TraitRank(namedParams.pertrait)
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
                local list = __Data.OvaleData.buffSpellList[v] or {}
                list[spellId] = true
                __Data.OvaleData.buffSpellList[v] = list
            elseif k == "dummy_replace" then
                local spellName = API_GetSpellInfo(v) or v
                __SpellBook.OvaleSpellBook:AddSpell(spellId, spellName)
            elseif k == "learn" and v == 1 then
                local spellName = API_GetSpellInfo(spellId)
                __SpellBook.OvaleSpellBook:AddSpell(spellId, spellName)
            elseif k == "sharedcd" then
                si[k] = v
                __Cooldown.OvaleCooldown:AddSharedCooldown(v, spellId)
            elseif addpower[k] ~= nil then
                local value = _tonumber(v)
                if value then
                    local realValue = value
                    if namedParams.pertrait ~= nil then
                        realValue = value * __Artifact.OvaleArtifact:TraitRank(namedParams.pertrait)
                    end
                    local power = si[k] or 0
                    si[k] = power + realValue
                else
                    ok = false
                    break
                end
            elseif  not __AST.OvaleAST.PARAMETER_KEYWORD[k] then
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
        local si = __Data.OvaleData:SpellInfo(spellId)
        local tbl = si.require[property] or {}
        for k, v in _pairs(namedParams) do
            if  not __AST.OvaleAST.PARAMETER_KEYWORD[k] then
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
            local positionalParams = node.positionalParams, node.namedParams
            local spellId = positionalParams[1]
            if spellId and __Condition.OvaleCondition:IsSpellBookCondition(node.func) then
                if  not __SpellBook.OvaleSpellBook:IsKnownSpell(spellId) and  not __Cooldown.OvaleCooldown:IsSharedCooldown(spellId) then
                    local spellName
                    if _type(spellId) == "number" then
                        spellName = __SpellBook.OvaleSpellBook:GetSpellName(spellId)
                    end
                    if spellName then
                        local name = API_GetSpellInfo(spellName)
                        if spellName == name then
                            __exports.OvaleCompile:Debug("Learning spell %s with ID %d.", spellName, spellId)
                            __SpellBook.OvaleSpellBook:AddSpell(spellId, spellName)
                        end
                    else
                        local functionCall = node.name
                        if node.paramsAsString then
                            functionCall = node.name .. "(" .. node.paramsAsString .. ")"
                        end
                        __exports.OvaleCompile:Print("Unknown spell with ID %s used in %s.", spellId, functionCall)
                    end
                end
            end
        end
    end
end

local AddToBuffList = function(buffId, statName, isStacking)
    if statName then
        for _, useName in _pairs(__Data.OvaleData.STAT_USE_NAMES) do
            if isStacking or  not strfind(useName, "_stacking_") then
                local name = useName .. "_" .. statName .. "_buff"
                local list = __Data.OvaleData.buffSpellList[name] or {}
                list[buffId] = true
                __Data.OvaleData.buffSpellList[name] = list
                local shortStatName = __Data.OvaleData.STAT_SHORTNAME[statName]
                if shortStatName then
                    name = useName .. "_" .. shortStatName .. "_buff"
                    list = __Data.OvaleData.buffSpellList[name] or {}
                    list[buffId] = true
                    __Data.OvaleData.buffSpellList[name] = list
                end
                name = useName .. "_any_buff"
                list = __Data.OvaleData.buffSpellList[name] or {}
                list[buffId] = true
                __Data.OvaleData.buffSpellList[name] = list
            end
        end
    else
        local si = __Data.OvaleData.spellInfo[buffId]
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
        trinket[1], trinket[2] = __Equipment.OvaleEquipment:GetEquippedTrinkets()
        for i = 1, 2, 1 do
            local itemId = trinket[i]
            local ii = itemId and __Data.OvaleData:ItemInfo(itemId)
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
local OvaleCompileClassBase = __Ovale.RegisterPrinter(__Debug.OvaleDebug:RegisterDebugging(__Profiler.OvaleProfiler:RegisterProfiling(OvaleCompileBase)))
local OvaleCompileClass = __class(OvaleCompileClassBase, {
    constructor = function(self)
        self.serial = nil
        self.ast = nil
        OvaleCompileClassBase.constructor(self)
        self:RegisterMessage("Ovale_CheckBoxValueChanged", "ScriptControlChanged")
        self:RegisterMessage("Ovale_EquipmentChanged", "EventHandler")
        self:RegisterMessage("Ovale_ListValueChanged", "ScriptControlChanged")
        self:RegisterMessage("Ovale_ScriptChanged")
        self:RegisterMessage("Ovale_SpecializationChanged", "Ovale_ScriptChanged")
        self:RegisterMessage("Ovale_SpellsChanged", "EventHandler")
        self:RegisterMessage("Ovale_StanceChanged")
        self:RegisterMessage("Ovale_TalentsChanged", "EventHandler")
        self:SendMessage("Ovale_ScriptChanged")
    end,
    OnDisable = function(self)
        self:UnregisterMessage("Ovale_CheckBoxValueChanged")
        self:UnregisterMessage("Ovale_EquipmentChanged")
        self:UnregisterMessage("Ovale_ListValueChanged")
        self:UnregisterMessage("Ovale_ScriptChanged")
        self:UnregisterMessage("Ovale_SpecializationChanged")
        self:UnregisterMessage("Ovale_SpellsChanged")
        self:UnregisterMessage("Ovale_StanceChanged")
        self:UnregisterMessage("Ovale_TalentsChanged")
    end,
    Ovale_ScriptChanged = function(self, event)
        self:CompileScript(__Ovale.Ovale.db.profile.source)
        self:EventHandler(event)
    end,
    Ovale_StanceChanged = function(self, event)
        if self_compileOnStances then
            self:EventHandler(event)
        end
    end,
    ScriptControlChanged = function(self, event, name)
        if  not name then
            self:EventHandler(event)
        else
            local control
            if event == "Ovale_CheckBoxValueChanged" then
                control = __Controls.checkBoxes[name]
            elseif event == "Ovale_ListValueChanged" then
                control = __Controls.checkBoxes[name]
            end
            if control and control.triggerEvaluation then
                self:EventHandler(event)
            end
        end
    end,
    EventHandler = function(self, event)
        self_serial = self_serial + 1
        self:Debug("%s: advance age to %d.", event, self_serial)
        __Ovale.Ovale:needRefresh()
    end,
    CompileScript = function(self, name)
        __Debug.OvaleDebug:ResetTrace()
        self:Debug("Compiling script '%s'.", name)
        if self.ast then
            __AST.OvaleAST:Release(self.ast)
            self.ast = nil
        end
        self.ast = __AST.OvaleAST:ParseScript(name)
        __Controls.ResetControls()
    end,
    EvaluateScript = function(self, ast, forceEvaluation)
        self:StartProfiling("OvaleCompile_EvaluateScript")
        if _type(ast) ~= "table" then
            forceEvaluation = ast
            ast = self.ast
        end
        local changed = false
        self_canEvaluate = self_canEvaluate
        if self_canEvaluate and ast and (forceEvaluation or  not self.serial or self.serial < self_serial) then
            self:Debug("Evaluating script.")
            changed = true
            local ok = true
            self_compileOnStances = false
            _wipe(self_icon)
            __Data.OvaleData:Reset()
            __Cooldown.OvaleCooldown:ResetSharedCooldowns()
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
    end,
    GetFunctionNode = function(self, name)
        local node
        if self.ast and self.ast.annotation and self.ast.annotation.customFunction then
            node = self.ast.annotation.customFunction[name]
        end
        return node
    end,
    GetIconNodes = function(self)
        return self_icon
    end,
    DebugCompile = function(self)
        self:Print("Total number of times the script was evaluated: %d", self_timesEvaluated)
    end,
})
__exports.OvaleCompile = OvaleCompileClass()
end)
