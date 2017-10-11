declare module "Recount" {
    const recount: {
        Group(name:string);
        db: { profile: { CurDataSet: any }};
        db2: { combatants: string[] };
        AddModeTooltip(key:string, modes, tooltips, a, b, c, d):void;
        AddAmount(source: string, key:string, value: number);
    }
    export default recount;
}