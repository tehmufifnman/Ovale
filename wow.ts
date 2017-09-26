var math = {
    floor: Math.floor,
    huge: Number.MAX_VALUE
};

interface LuaArray<T> {
    [key:number]:T;
    n?:number;
}

interface LuaObj<T> {
    [key: string]:T;
}

function ipairs<T>(a:LuaArray<T>) {
    const pairs:[number, T][] = [];
    for (let k in a) {
        pairs.push([parseInt(k), a[k]]);
    }
    return pairs.sort((x,y) => x[0] < y[0] ? -1 : (x[0] == y[0] ? 0 : 1));
}

function pairs<T = any>(a:LuaObj<T>) {
    const pairs:[string, T][] = [];
    for (let k in a) {
        pairs.push([k, a[k]]);
    }
    return pairs;
}

function next<T>(a:LuaArray<T>) {
    for (let k in a) {
        return [k, a[k]];
    }
    return undefined;
}

var bit = {
    band(...other:number[]) {
        let result = other[0];
        for (let i = 1; i < other.length; i++) {
            result &= other[i];
        }
        return result;
    },
    bor(...other:number[]) {
        let result = other[0];
        for (let i = 1; i < other.length; i++) {
            result |= other[i];
        }
        return result;
    }
};

var string = {
    find() {},
    lower(t: string) { return t.toLowerCase() },
    sub(t: string, index: number, length?:number) { return t.substr(index, length) }
}

var table = {
    concat<T>(...t:LuaArray<T>[]):LuaArray<T> {
        const result: LuaArray<T> = {};
        for (const a of t) {
            for (const i in a) {
                result[i] = a[i];
            }
        }
        delete result.n;
        return result;
    },
    insert<T>(t:LuaArray<T>, value:T) {
        const l = lualength(t);
        t[l + 1] = value;
        t.n = l + 1;
    },
    sort<T>(t:LuaArray<T>) {
        let values:T[] = [];
        for (const key in t) {
            values.push(t[key])
        }
        wipe(t);
        values = values.sort();
        for (let i = 0; i < values.length; i++) {
            t[i + 1] = values[i];
        }
        t.n = values.length;
    }
}

function lualength<T>(array: LuaArray<T>):number {
    if (!array.n) {
        for (let i = 1; ; i++){
            if (!array[i]) {
                array.n = i;
                break;
            }
        }
    }
    return array.n;
}

function tonumber(a: any):number {
    return parseInt(a);
}

function type(a: any) {
    return typeof(a);
}

function wipe(x: any) {
    const keys = [];
    for (let i in x) {
        keys.push(i);
    }
    for (const k of keys) {
        delete x[k];
    }
}

function GetTime() {
    return 10;
}

function UnitAura() {
    return [];
}