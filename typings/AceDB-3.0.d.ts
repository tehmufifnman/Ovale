interface Database{
    RegisterCallback: (module: any, event: string, method: string) => void;
}

interface AceDB {
    New<T>(name:string, defaultDb:T):Database;
}

declare module "AceDB-3.0" {
    let aceAddon:AceDB; 
    export default aceAddon;
}
