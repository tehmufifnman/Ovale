declare class AceEvent {
    RegisterEvent(event:"PLAYER_ENTERING_WORLD", callback: (event:string) => void):void;
    RegisterEvent(event:"UNIT_AURA", callback: (event: string, unitId:string) => void):void;
    RegisterEvent(event:string, callback: (event: string, ...parameters) => void):void;
    RegisterEvent(event: string, callback: string):void;
    RegisterEvent(event: string):void;
    RegisterMessage(event:string, callback: (event: string, ...parameters) => void):void;
    RegisterMessage(event: string, callback: string):void;
    RegisterMessage(event:string):void;
    UnregisterEvent(event:string):void;
    UnregisterMessage(event:string):void;
    SendMessage(event: string, ...parameters):void;
}

declare module "AceEvent-3.0" {
    export default AceEvent;
}

