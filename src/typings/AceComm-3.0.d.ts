declare class AceComm{
    RegisterComm(msgPrefix:string):void;
    SendCommMessage(msgPrefix:string, message: string, channel: string):void;
}

 
declare module "AceComm-3.0" {
    const lib: Library<AceComm>;
    export default lib;
}
