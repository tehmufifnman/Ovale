// interface ModuleEvents {
//     OnEnable?: () => void;
//     OnInitialize?: () => void;
//     RegisterEvent?: (name: string, method?: string) => void;
//     RegisterMessage?: (name: string, method?: string) => void;
//     UnregisterEvent?: (name: string) => void;
//     UnregisterMessage?: (name: string) => void;
//     GetName?: () => string;
//     SendMessage?: (message:string) => void;
// }

interface Addon {
    NewModule(name:string, module: "AceEvent-3.0"): new() => (AceEvent);
    NewModule(name:string, module: "AceTimer-3.0"): new() => (AceTimerModule);
    NewModule(name:string, module1: "AceEvent-3.0", module2: "AceTimer-3.0"): new() => (AceEvent & AceTimerModule);
    db:any;
    Print(message:string, ...parameters):void;
}

declare class AceAddon {
    NewAddon<T, U>(o: new() => T, name: string, dependency: new() => U):new() => (T & U & Addon);

    GetAddon(name:string):Addon;
}
 
declare module "AceAddon-3.0" {
    export default AceAddon;
}