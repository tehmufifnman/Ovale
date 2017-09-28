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

function type(a: any) : "table" | "number" | "string" | "function" {
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

function assert(condition) {

}

function unpack(t) {

}

function tostringall(...text: object[]){
    return text.map(x => x.toString());
}

function select<T>(index: number, t: LuaArray<T>): T{
    return t[index];
}

function strjoin(separator: string, ...text:string[]) {
    return text.join(separator);
}

function hooksecurefunc(table, methodName, hook) {

}
function rawset(table: any, key, value){}
function setmetatable(table: any, metatable: any){}
function loadstring(t: string):() => void { return undefined; }
// Global lua objects
var math = {
    floor: Math.floor,
    huge: Number.MAX_VALUE,
    abs: Math.abs
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
    concat<T>(t:LuaArray<T>, seperator: string):string {
        const result: string[] = [];
        for (let i = 1; t[i] !== undefined; i++) {
            result.push(t[i].toString());
        }

        return result.join(seperator);
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
    remove<T>(t: LuaArray<T>, index?: number):T { return t[t.n] },
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

function GetSpellInfo(spellId: number) {
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

function UnitName(unitId: string) {
    return "Esside";
}

function GetActionCooldown(action: string):[number, number, boolean] {
    return undefined;    
}

function GetActionTexture(action: string){

}

function GetItemIcon(itemId: number){

}

function GetItemCooldown(itemId: number): [number, number, boolean]{
    return undefined;
}

function GetItemSpell(itemId: number){

}

function GetSpellTexture(spellId: number){

}

function IsActionInRange(action: string, target: string){

}

function IsCurrentAction(action: string){

}

function IsItemInRange(itemId: number, target: string){

}

function IsUsableAction(action: string): boolean{
    return false;
}

function IsUsableItem(itemId: number){

}

function GetNumGroupMembers(filter: number) {
    return 0;
}

function UnitPower(unit: string) { return 0;}

function IsInGroup(filter: number){ return false}
function IsInInstance(){return false}
function IsInRaid(filter: number){return false}
function UnitLevel(target:string){ return 0;}
var BigWigsLoader;

var Bartender4;

// WoW global variables
var MAX_COMBO_POINTS = 5;
var UNKNOWN = -1;
var DEFAULT_CHAT_FRAME:UIFrame = undefined;
var SCHOOL_MASK_ARCANE = 1;
var SCHOOL_MASK_FIRE = 2;
var SCHOOL_MASK_FROST = 4;
var SCHOOL_MASK_HOLY = 8;
var SCHOOL_MASK_NATURE = 16;
var SCHOOL_MASK_SHADOW = 32;

var LE_PARTY_CATEGORY_INSTANCE = 1;
var LE_PARTY_CATEGORY_HOME = 2;
var _G: any;
var DBM;