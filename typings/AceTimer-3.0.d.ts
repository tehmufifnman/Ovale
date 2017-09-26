declare class AceTimerModule {
    ScheduleTimer: (method:string, interval:number) => void;
}

declare module "AceTimer-3.0"{
    export default AceTimerModule;
}