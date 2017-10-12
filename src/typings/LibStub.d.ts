

type Constructor<T> = new(...argv:any[]) => T;

interface Library<T> {
    Embed<U>(base: Constructor<U>): Constructor<T & U>;
}

declare module 'LibStub' {
    interface LibStub{
        NewLibrary(major:string, minor: string):any;
        GetLibrary(major:string, silent?: boolean):any;
        <T>(t: new() => T): T;
    }

    const libStub:LibStub;
    export default libStub;
}
