declare class AceTimerModule {
    ScheduleTimer(method:string, interval:number):void;
    ScheduleRepeatingTimer(method:string, interval:number):number;
    CancelTimer(handle:number):void;
}

declare module "AceTimer-3.0"{
    const lib: Library<AceTimerModule>;
    export default lib;
}