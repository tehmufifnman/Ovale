import __addon from "addon";
let [OVALE, Ovale] = __addon;
import { OvaleProfiler } from "./Profiler";
let _assert = assert;
let _setmetatable = setmetatable;
let tinsert = table.insert;
let _tostring = tostring;
let tremove = table.remove;
let _wipe = wipe;

export class OvalePool<T> {
    pool:LuaArray<T> = undefined;
    size = 0;
    unused = 0;
    name: string;
    
    constructor(name) {
        this.name = name || "OvalePool";
        this.Drain();
    }

    Get() {
        // OvalePool.StartProfiling(this.name);
        _assert(this.pool);
        let item = tremove(this.pool);
        if (item) {
            this.unused = this.unused - 1;
        } else {
            this.size = this.size + 1;
            item = <T>{}
        }
        // OvalePool.StopProfiling(this.name);
        return item;
    }
    Release(item:T):void {
        // OvalePool.StartProfiling(this.name);
        _assert(this.pool);
        this.Clean(item);
        _wipe(item);
        tinsert(this.pool, item);
        this.unused = this.unused + 1;
       // OvalePool.StopProfiling(this.name);
    }
    Drain():void {
        //OvalePool.StartProfiling(this.name);
        this.pool = {}
        this.size = this.size - this.unused;
        this.unused = 0;
        //OvalePool.StopProfiling(this.name);
    }
    DebuggingInfo():void {
        Ovale.Print("Pool %s has size %d with %d item(s).", _tostring(this.name), this.size, this.unused);
    }
    Clean(item: T): void {
    }

}
