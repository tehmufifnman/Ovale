declare interface AceLocale {
    GetLocale(name:string, optional:boolean):LuaObj<string>;
}

declare module "AceLocale-3.0" {
    const aceLocale:AceLocale;
    export default aceLocale;
}