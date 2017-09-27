interface AceDBOptions {
    GetOptionsTable(db:Database):Database;
}

declare module "AceDBOptions-3.0" {
    let aceAddon:AceDBOptions; 
    export default aceAddon;
}
