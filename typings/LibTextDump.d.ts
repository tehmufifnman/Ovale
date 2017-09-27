interface TextDump{
    Clear():void;
    Lines():number;
    AddLine(line:string):void;
    Display():void;
}

interface LibTextDump {
    New: (name: string, width: number, height:number) => TextDump;
}

declare module "LibTextDump-1.0" {
    let aceAddon:LibTextDump; 
    export default aceAddon;
}
