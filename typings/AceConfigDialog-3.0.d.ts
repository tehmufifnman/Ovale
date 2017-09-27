interface AceConfigDialog{
    SetDefaultSize(appName:string, width: number, height:number):void;
    Open(appName: string):void;
    Close(appName: string):void;
    AddToBlizOptions(appName: string, name?: string, addon?:string):void;
    OpenFrames:LuaDictionary<any>;
}

declare module "AceConfigDialog-3.0" {
    let aceConfigDialog:AceConfigDialog; 
    export default aceConfigDialog;
}