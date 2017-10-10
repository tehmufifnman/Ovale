interface MasqueSkinGroup {
    AddButton(frame: UIFrame):void;
}
    
declare module "Masque" {
    const masque: {
        Group(name:string): MasqueSkinGroup;
    }
    export default masque;
}