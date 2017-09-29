import LibArtifactData from "LibArtifactData-1.0";
import { OvaleDebug } from "./Debug";
import { L } from "./Localization";
import { OvaleState } from "./State";
import { Ovale } from "./Ovale";
let tsort = table.sort;
let tinsert = table.insert;
let tremove = table.remove;
let tconcat = table.concat;


let OvaleArtifactBase = Ovale.NewModule("OvaleArtifact", "AceEvent-3.0");
class OvaleArtifact extends OvaleDebug.RegisterDebugging(OvaleArtifactBase) {
    self_traits = {}

    debugOptions = {
        artifacttraits: {
            name: L["Artifact traits"],
            type: "group",
            args: {
                artifacttraits: {
                    name: L["Artifact traits"],
                    type: "input",
                    multiline: 25,
                    width: "full",
                    get: (info) => {
                        return this.DebugTraits();
                    }
                }
            }
        }
    }    

    constructor() {
        super();
        for (const [k, v] of pairs(this.debugOptions)) {
            OvaleDebug.options.args[k] = v;
        }
    }

    OnInitialize() {
    }
    OnEnable() {
        this.RegisterEvent("SPELLS_CHANGED", this.UpdateTraits);
        LibArtifactData.RegisterCallback(OvaleArtifact, "ARTIFACT_ADDED", this.UpdateTraits);
        LibArtifactData.RegisterCallback(OvaleArtifact, "ARTIFACT_EQUIPPED_CHANGED", this.UpdateTraits);
        LibArtifactData.RegisterCallback(OvaleArtifact, "ARTIFACT_ACTIVE_CHANGED", this.UpdateTraits);
        LibArtifactData.RegisterCallback(OvaleArtifact, "ARTIFACT_TRAITS_CHANGED", this.UpdateTraits);
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
        this.self_traits = {}
        if (!traits) {
            return;
        }
        for (const [k, v] of ipairs(traits)) {
            this.self_traits[v.spellID] = v;
        }
    }
    HasTrait(spellId) {
        return this.self_traits[spellId] && this.self_traits[spellId].currentRank;
    }
    TraitRank(spellId) {
        if (!this.self_traits[spellId]) {
            return 0;
        }
        return this.self_traits[spellId].currentRank;
    }
    output = {}
    DebugTraits() {
        wipe(this.output);
        let array = {
        }
        for (const [k, v] of pairs(this.self_traits)) {
            tinsert(array, tostring(v.name) + ": " + tostring(k));
        }
        tsort(array);
        for (const [_, v] of ipairs(array)) {
            this.output[lualength(this.output) + 1] = v;
        }
        return tconcat(this.output, "\n");
    }
}
