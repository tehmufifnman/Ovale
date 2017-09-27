interface AceConfig{
    RegisterOptionsTable(appName: string, options: any, title?:string):void;
}

 
declare module "AceConfig-3.0" {
    const config:AceConfig;
    export default config;
}
