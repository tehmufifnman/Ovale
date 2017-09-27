import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvalePool = {
}
Ovale.OvalePool = OvalePool;
import { OvaleProfiler } from "./OvaleProfiler";
let _assert = assert;
let _setmetatable = setmetatable;
let tinsert = table.insert;
let _tostring = tostring;
let tremove = table.remove;
let _wipe = wipe;
OvaleProfiler.RegisterProfiling(OvalePool, "OvalePool");
OvalePool.name = "OvalePool";
OvalePool.pool = undefined;
OvalePool.size = 0;
OvalePool.unused = 0;
OvalePool.__index = OvalePool;
{
    _setmetatable(OvalePool, {
        __call: function (self, ...__args) {
            return this.NewPool(...__args);
        }
    });
}
class OvalePool {
    NewPool(name) {
        name = name || this.name;
        let obj = _setmetatable({
            name: name
        }, this);
        obj.Drain();
        return obj;
    }
    Get() {
        OvalePool.StartProfiling(this.name);
        _assert(this.pool);
        let item = tremove(this.pool);
        if (item) {
            this.unused = this.unused - 1;
        } else {
            this.size = this.size + 1;
            item = {
            }
        }
        OvalePool.StopProfiling(this.name);
        return item;
    }
    Release(item) {
        OvalePool.StartProfiling(this.name);
        _assert(this.pool);
        this.Clean(item);
        _wipe(item);
        tinsert(this.pool, item);
        this.unused = this.unused + 1;
        OvalePool.StopProfiling(this.name);
    }
    Clean(item) {
    }
    Drain() {
        OvalePool.StartProfiling(this.name);
        this.pool = {
        }
        this.size = this.size - this.unused;
        this.unused = 0;
        OvalePool.StopProfiling(this.name);
    }
    DebuggingInfo() {
        Ovale.Print("Pool %s has size %d with %d item(s).", _tostring(this.name), this.size, this.unused);
    }
}
