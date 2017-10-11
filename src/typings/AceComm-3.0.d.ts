declare class AceComm{
    RegisterComm(msgPrefix:string):void;
    SendCommMessage(msgPrefix:string, message: string, channel: string):void;
}

 
declare module "AceComm-3.0" {
    export default AceComm;
}
