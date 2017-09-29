interface AceGUI {
    Create(name:string):UIFrame;
    ClearFocus();
    RegisterAsContainer(container: {frame: UIFrame}):void;
    RegisterWidgetType(name: string, width: new() => {frame: UIFrame}, version: number):void;
}

declare module "AceGUI-3.0" {
    let aceAddon:AceGUI; 
    export default aceAddon;
}
