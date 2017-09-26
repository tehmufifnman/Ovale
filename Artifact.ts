import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleArtifact = Ovale.NewModule("OvaleArtifact", "AceEvent-3.0");
let LibArtifactData = LibStub("LibArtifactData-1.0");
import { OvaleDebug } from "./OvaleDebug";
Ovale.OvaleArtifact = OvaleArtifact;
import { L } from "./L";
let OvaleState = undefined;
let tsort = table.sort;
let tinsert = table.insert;
let tremove = table.remove;
let tconcat = table.concat;
let self_traits = {  }
OvaleDebug.RegisterDebugging(OvaleArtifact);
class OvaleArtifact {
    OnInitialize() {
    }
    OnEnable() {
        this.RegisterEvent("SPELLS_CHANGED", "UpdateTraits");
        LibArtifactData.RegisterCallback(OvaleArtifact, "ARTIFACT_ADDED", "UpdateTraits");
        LibArtifactData.RegisterCallback(OvaleArtifact, "ARTIFACT_EQUIPPED_CHANGED", "UpdateTraits");
        LibArtifactData.RegisterCallback(OvaleArtifact, "ARTIFACT_ACTIVE_CHANGED", "UpdateTraits");
        LibArtifactData.RegisterCallback(OvaleArtifact, "ARTIFACT_TRAITS_CHANGED", "UpdateTraits");
    }
    OnDisable() {
        LibArtifactData.UnregisterCallback(OvaleArtifact, "ARTIFACT_ADDED");
        LibArtifactData.UnregisterCallback(OvaleArtifact, "ARTIFACT_EQUIPPED_CHANGED");
        LibArtifactData.UnregisterCallback(OvaleArtifact, "ARTIFACT_ACTIVE_CHANGED");
        LibArtifactData.UnregisterCallback(OvaleArtifact, "ARTIFACT_TRAITS_CHANGED");
        this.UnregisterEvent("SPELLS_CHANGED");
    }
    UpdateTraits(message) {
        let [artifactId, traits] = LibArtifactData.GetArtifactTraits();
        self_traits = {  }
        if (!traits) {
            break;
        }
        for (const [k, v] of ipairs(traits)) {
            self_traits[v.spellID] = v;
        }
    }
    HasTrait(spellId) {
        return self_traits[spellId] && self_traits[spellId].currentRank;
    }
    TraitRank(spellId) {
        if (!self_traits[spellId]) {
            return 0;
        }
        return self_traits[spellId].currentRank;
    }
}
{
    let output = {  }
class OvaleArtifact {
        DebugTraits() {
            wipe(output);
            let array = {  }
            for (const [k, v] of pairs(self_traits)) {
                tinsert(array, tostring(v.name) + ": " + tostring(k));
            }
            tsort(array);
            for (const [_, v] of ipairs(array)) {
                output[lualength(output) + 1] = v;
            }
            return tconcat(output, "\n");
        }
}
}
{
    let debugOptions = { artifacttraits: { name: L["Artifact traits"], type: "group", args: { artifacttraits: { name: L["Artifact traits"], type: "input", multiline: 25, width: "full", get: function (info) {
        return OvaleArtifact.DebugTraits();
    } } } } }
    for (const [k, v] of pairs(debugOptions)) {
        OvaleDebug.options.args[k] = v;
    }
}
