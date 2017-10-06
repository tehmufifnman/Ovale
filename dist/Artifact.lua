local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./Artifact", { "LibArtifactData-1.0", "./Debug", "./Localization", "./State", "./Ovale" }, function(__exports, LibArtifactData, __Debug, __Localization, __State, __Ovale)
local tsort = table.sort
local tinsert = table.insert
local tremove = table.remove
local tconcat = table.concat
local OvaleArtifactBase = __Ovale.Ovale:NewModule("OvaleArtifact", "AceEvent-3.0")
local OvaleArtifactClass = __class(__Debug.OvaleDebug:RegisterDebugging(OvaleArtifactBase), {
    constructor = function(self)
        self.self_traits = {}
        self.debugOptions = {
            artifacttraits = {
                name = __Localization.L["Artifact traits"],
                type = "group",
                args = {
                    artifacttraits = {
                        name = __Localization.L["Artifact traits"],
                        type = "input",
                        multiline = 25,
                        width = "full",
                        get = function(info)
                            return self:DebugTraits()
                        end
                    }
                }
            }
        }
        self.output = {}
        __Debug.OvaleDebug:RegisterDebugging(OvaleArtifactBase).constructor(self)
        for k, v in pairs(self.debugOptions) do
            __Debug.OvaleDebug.options.args[k] = v
        end
    end,
    OnInitialize = function(self)
    end,
    OnEnable = function(self)
        self:RegisterEvent("SPELLS_CHANGED", self.UpdateTraits)
        LibArtifactData:RegisterCallback(__exports.OvaleArtifact, "ARTIFACT_ADDED", self.UpdateTraits)
        LibArtifactData:RegisterCallback(__exports.OvaleArtifact, "ARTIFACT_EQUIPPED_CHANGED", self.UpdateTraits)
        LibArtifactData:RegisterCallback(__exports.OvaleArtifact, "ARTIFACT_ACTIVE_CHANGED", self.UpdateTraits)
        LibArtifactData:RegisterCallback(__exports.OvaleArtifact, "ARTIFACT_TRAITS_CHANGED", self.UpdateTraits)
    end,
    OnDisable = function(self)
        LibArtifactData:UnregisterCallback(__exports.OvaleArtifact, "ARTIFACT_ADDED")
        LibArtifactData:UnregisterCallback(__exports.OvaleArtifact, "ARTIFACT_EQUIPPED_CHANGED")
        LibArtifactData:UnregisterCallback(__exports.OvaleArtifact, "ARTIFACT_ACTIVE_CHANGED")
        LibArtifactData:UnregisterCallback(__exports.OvaleArtifact, "ARTIFACT_TRAITS_CHANGED")
        self:UnregisterEvent("SPELLS_CHANGED")
    end,
    UpdateTraits = function(self, message)
        local artifactId, traits = LibArtifactData:GetArtifactTraits()
        self.self_traits = {}
        if  not traits then
            return 
        end
        for k, v in ipairs(traits) do
            self.self_traits[v.spellID] = v
        end
    end,
    HasTrait = function(self, spellId)
        return self.self_traits[spellId] and self.self_traits[spellId].currentRank
    end,
    TraitRank = function(self, spellId)
        if  not self.self_traits[spellId] then
            return 0
        end
        return self.self_traits[spellId].currentRank
    end,
    DebugTraits = function(self)
        wipe(self.output)
        local array = {}
        for k, v in pairs(self.self_traits) do
            tinsert(array, tostring(v.name) .. ": " .. tostring(k))
        end
        tsort(array)
        for _, v in ipairs(array) do
            self.output[#self.output + 1] = v
        end
        return tconcat(self.output, "\\n")
    end,
})
__exports.OvaleArtifact = OvaleArtifactClass()
end)
