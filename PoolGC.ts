import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvalePoolGC = {  }
Ovale.OvalePoolGC = OvalePoolGC;
let _setmetatable = setmetatable;
let _tostring = tostring;
OvalePoolGC.name = "OvalePoolGC";
OvalePoolGC.size = 0;
OvalePoolGC.__index = OvalePoolGC;
{
    _setmetatable(OvalePoolGC, { __call: function (self, ...__args) {
        return this.NewPool(...__args);
    } });
}
class OvalePoolGC {
    NewPool(name) {
        name = name || this.name;
        return _setmetatable({ name: name }, this);
    }
    Get() {
        this.size = this.size + 1;
        return {  };
    }
    Release(item) {
        this.Clean(item);
    }
    Clean(item) {
    }
    Drain() {
        this.size = 0;
    }
    DebuggingInfo() {
        Ovale.Print("Pool %s has size %d.", _tostring(this.name), this.size);
    }
}
