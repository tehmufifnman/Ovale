interface LibDBIcon {
    Register(addon:string, broker, data:any);
    Refresh(OVALE, minimap);
    Hide(OVALE)
    Show(OVALE)
}
declare module "LibDBIcon-1.0" {
    const libDbIcon:LibDBIcon;
    export default libDbIcon;
}