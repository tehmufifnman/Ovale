interface AceGUI {
    Create(name:string):UIFrame;
}

declare module "AceGUI-3.0" {
    let aceAddon:AceGUI; 
    export default aceAddon;
}
