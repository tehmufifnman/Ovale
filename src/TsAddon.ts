export interface AceModule {
    GetName?(): string;
}

export interface Addon {
    NewModule(name: string) : Constructor<AceModule>;
    NewModule<T>(name: string, dep1: Library<T>) : Constructor<AceModule & T>;
    NewModule<T, U>(name: string, dep1: Library<T>, dep2: Library<U>) : Constructor<AceModule & T & U>;
    NewModule<T, U, V>(name: string, dep1: Library<T>, dep2: Library<U>, dep3: Library<V>): Constructor<AceModule & T & U & V>;
    Print(message:string, ...parameters:any[]):void;
    GetName():string;
}

export function NewAddon<T>(name: string, dependency:Library<T>): Constructor<Addon & T> {
    const BaseClass = class {
        NewModule<T, U, V>(name: string, dep1?: Library<T>, dep2?: Library<U>, dep3?: Library<V>) {
            const BaseModule = class {
                GetName() {
                    return name;
                }
            };
            if (dep1) {
                if (dep2) {
                    if (dep3) {
                        return dep1.Embed(dep2.Embed(dep3.Embed(BaseModule)));
                    }                    
                    return dep1.Embed(dep2.Embed(BaseModule));
                }
                return dep1.Embed(BaseModule);
            }
            return BaseModule;
        }
        GetName() {
            return name;
        }
        Print(message: string, ...parameters:any[]) {                
        }
    };
    return dependency.Embed(BaseClass);
}
