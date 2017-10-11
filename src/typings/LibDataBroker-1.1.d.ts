declare class LibDataBroker {
    NewDataObject(addon: string, broker)
}

declare module "LibDataBroker-1.1" {
    const dataBrocker:LibDataBroker;
    export default dataBrocker;
}