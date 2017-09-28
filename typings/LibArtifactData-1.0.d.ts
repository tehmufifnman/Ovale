declare module "LibArtifactData-1.0" {
    export default class LibArtifactData {
        static RegisterCallback(arg0: any, arg1: any, arg2: any): any;
        static UnregisterCallback(arg0: any, arg1: any): any;        
        static GetArtifactTraits():[string, LuaArray<{spellID: string}>];
    }
}