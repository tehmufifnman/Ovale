interface LibDBIcon {
    Register(addon:string, broker, minimap:boolean);
    Refresh(OVALE, minimap);
    Hide(OVALE)
    Show(OVALE)
}
declare module "LibDBIcon-1.0" {
    const libDbIcon:LibDBIcon;
    export default libDbIcon;
}