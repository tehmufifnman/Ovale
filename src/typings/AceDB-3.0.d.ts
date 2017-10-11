interface Database {
    RegisterCallback: (module: any, event: string, method: string) => void;
    RegisterDefaults: (defaults:any) => void;
}

interface AceDB {
    New<T>(name:string, defaultDb:T):Database & T;
}

declare module "AceDB-3.0" {
    let aceAddon:AceDB; 
    export default aceAddon;
}
