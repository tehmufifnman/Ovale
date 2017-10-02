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

declare class AceModule {
    GetName?(): string;
    Print?(s: string, ...format): void;
}

interface Addon {
    NewModule(name:string): new () => AceModule;
    NewModule(name:string, module: "AceEvent-3.0"): new() => (AceEvent & AceModule);
    NewModule(name:string, module: "AceTimer-3.0"): new() => (AceTimerModule & AceModule);
    NewModule(name:string, module: "AceConsole-3.0"): new() => (AceConsole & AceModule);
    NewModule(name:string, module: "AceConsole-3.0", module2: "AceEvent-3.0"): new() => (AceConsole & AceEvent & AceModule);
    NewModule(name:string, module2: "AceEvent-3.0", module3: "AceSerializer-3.0"): new() => (AceEvent & AceModule & AceSerializer);
    NewModule(name:string, module1: "AceEvent-3.0", module2: "AceTimer-3.0"): new() => (AceEvent & AceTimerModule & AceModule);
    NewModule(name: string, module1: "AceComm-3.0", module2: "AceSerializer-3.0", module3: "AceTimer-3.0"): new() => (AceComm & AceSerializer & AceTimerModule);
    db:any;
    Print(message:string, ...parameters):void;
    GetName():string;
}

declare class AceAddon {
    NewAddon<T, U>(name: string, module: "AceEvent-3.0"):new() => (Addon & AceEvent);
    NewAddon<T, U>(o: new() => T, name: string, dependency: new() => U):new() => (T & U & Addon);

    GetAddon(name:string):Addon;
}
 
declare module "AceAddon-3.0" {
    const aceAddon: AceAddon;
    export default aceAddon;
}