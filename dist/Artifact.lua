local OVALE, Ovale = ...
require(OVALE, Ovale, "Artifact", { "./OvaleDebug", "./L" }, function(__exports, __OvaleDebug, __L)
local OvaleArtifact = Ovale:NewModule("OvaleArtifact", "AceEvent-3.0")
local LibArtifactData = LibStub("LibArtifactData-1.0")
Ovale.OvaleArtifact = OvaleArtifact
local OvaleState = nil
local tsort = table.sort
local tinsert = table.insert
local tremove = table.remove
local tconcat = table.concat
local self_traits = {}
__OvaleDebug.OvaleDebug:RegisterDebugging(OvaleArtifact)
local OvaleArtifact = __class()
function OvaleArtifact:OnInitialize()
end
function OvaleArtifact:OnEnable()
    self:RegisterEvent("SPELLS_CHANGED", "UpdateTraits")
    LibArtifactData:RegisterCallback(OvaleArtifact, "ARTIFACT_ADDED", "UpdateTraits")
    LibArtifactData:RegisterCallback(OvaleArtifact, "ARTIFACT_EQUIPPED_CHANGED", "UpdateTraits")
    LibArtifactData:RegisterCallback(OvaleArtifact, "ARTIFACT_ACTIVE_CHANGED", "UpdateTraits")
    LibArtifactData:RegisterCallback(OvaleArtifact, "ARTIFACT_TRAITS_CHANGED", "UpdateTraits")
end
function OvaleArtifact:OnDisable()
    LibArtifactData:UnregisterCallback(OvaleArtifact, "ARTIFACT_ADDED")
    LibArtifactData:UnregisterCallback(OvaleArtifact, "ARTIFACT_EQUIPPED_CHANGED")
    LibArtifactData:UnregisterCallback(OvaleArtifact, "ARTIFACT_ACTIVE_CHANGED")
    LibArtifactData:UnregisterCallback(OvaleArtifact, "ARTIFACT_TRAITS_CHANGED")
    self:UnregisterEvent("SPELLS_CHANGED")
end
function OvaleArtifact:UpdateTraits(message)
    local artifactId, traits = LibArtifactData:GetArtifactTraits()
    self_traits = {}
    if  not traits then
        break
    end
    for k, v in ipairs(traits) do
        self_traits[v.spellID] = v
    end
end
function OvaleArtifact:HasTrait(spellId)
    return self_traits[spellId] and self_traits[spellId].currentRank
end
function OvaleArtifact:TraitRank(spellId)
    if  not self_traits[spellId] then
        return 0
    end
    return self_traits[spellId].currentRank
end
do
    local output = {}
local OvaleArtifact = __class()
    function OvaleArtifact:DebugTraits()
        wipe(output)
        local array = {}
        for k, v in pairs(self_traits) do
            tinsert(array, tostring(v.name) + ": " + tostring(k))
        end
        tsort(array)
        for _, v in ipairs(array) do
            output[#output + 1] = v
        end
        return tconcat(output, "\n")
    end
end
do
    local debugOptions = {
        artifacttraits = {
            name = __L.L["Artifact traits"],
            type = "group",
            args = {
                artifacttraits = {
                    name = __L.L["Artifact traits"],
                    type = "input",
                    multiline = 25,
                    width = "full",
                    get = function(info)
                        return OvaleArtifact:DebugTraits()
                    end
                }
            }
        }
    }
    for k, v in pairs(debugOptions) do
        __OvaleDebug.OvaleDebug.options.args[k] = v
    end
end
end))
