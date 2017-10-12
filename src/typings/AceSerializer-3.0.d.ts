declare class AceSerializer {
    Serialize(...args):string;
    Deserialize(messsage:string):any[];
}
declare module "AceSerializer-3.0" {
    const lib: Library<AceSerializer>;
    export default lib;
}