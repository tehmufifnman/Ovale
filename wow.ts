// Utility interfaces
interface LuaArray<T> {
    [key:number]:T;
    n?:number;
}

interface LuaObj<T> {
    [key: string]:T;
}

// Global lua functions
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

function tonumber(a: any):number {
    return parseInt(a);
}

function tostring(s: any): string {
    return s.toString();
}

function type(a: any) : "table" {
    return "table";
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

function assert(condition: boolean) {

}

function unpack() {

}

function tostringall(...text: object[]){
    return text.map(x => x.toString());
}

function select<T>(index: number, t: LuaArray<T>): T{

}

function strjoin(separator: string, ...text:string[]) {
    return text.join(separator);
}

function rawset(table: any, key, value){}
function setmetatable(table: any, metatable: any){}

// Global lua objects
var math = {
    floor: Math.floor,
    huge: Number.MAX_VALUE
};

var coroutine = {
    yield(key, value?){}
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
    find(t: string, pattern: string) { return t.indexOf(pattern)},
    lower(t: string) { return t.toLowerCase() },
    sub(t: string, index: number, length?:number) { return t.substr(index, length) },
    len(t: string) { return t.length},
    format(format: string, ...values) { return format; },
    gmatch(text: string, pattern: string) { return text.match(pattern); },
    gsub(text: string, pattern: string, substitue: string) {
        return text.replace(pattern, substitue);
    },
    match(text: string, pattern: string) { return text.match(pattern); },
    upper(text: string) { return text.toUpperCase()},
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

    insert<T>(t:LuaArray<T>, indexOrValue:number|T, value?: T) {
        // const l = lualength(t);
        // t[l + 1] = value;
        // t.n = l + 1;
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
    },
    remove():void {},
}

// Utility functions
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

// WoW Class 
interface UIFrame {
    AddMessage(message:string);
    SetLabel(label: string);
    SetValue(value: string);
    SetUserData(key: string, value: string);
    SetCallback(event: string, callback: (widget: UIFrame) => void);
    SetList(list: LuaArray<any>):void;
}

// WOW global functions
function GetTime() {
    return 10;
}

function UnitAura() {
    return [];
}

function GetSpellInfo() {
    return [];
}

function GetItemInfo(itemId: string) {

}

function UnitCanAttack(unit:string, target: string) {
    return false;
}

function UnitClass(unit:string) {
    return ["Warrior", "WARRIOR"];
}

function UnitExists(unit:string) {
    return false;
}

function UnitGUID(unit:string) {
    return "aaaa";
}

function UnitHasVehicleUI(unit: string) {
    return false;
}

function UnitIsDead(unit: string) {
    return false;
}

function InterfaceOptionsFrame_OpenToCategory(frameName:string) {

}

function debugprofilestop() {
    return 10;
}

function GetActionInfo(slot: string) {
    return ["a", "b", "c"];
}

function GetActionText(slot: string) {
    return "ActioNText";
}

function GetBindingKey(key:string){
    return "a";
}

function GetBonusBarIndex(){

}

function GetMacroItem(spellId: number){
    return [];
}

function GetMacroSpell(spellId: number){
    return []
}

var Bartender4;

// WoW global variables
var DEFAULT_CHAT_FRAME:UIFrame = undefined;

var _G: any;