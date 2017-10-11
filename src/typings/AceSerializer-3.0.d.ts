declare class AceSerializer {
    Serialize(...args):string;
    Deserialize(messsage:string):any[];
}
declare module "AceSerializer-3.0" {
    export default AceSerializer;
}