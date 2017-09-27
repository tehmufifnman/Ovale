import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleQueue = {
}
Ovale.OvaleQueue = OvaleQueue;
let _setmetatable = setmetatable;
OvaleQueue.name = "OvaleQueue";
OvaleQueue.first = 1;
OvaleQueue.last = 0;
OvaleQueue.__index = OvaleQueue;
const BackToFrontIterator = function(invariant, control) {
    control = control - 1;
    let element = invariant[control];
    if (element) {
        return [control, element];
    }
}
const FrontToBackIterator = function(invariant, control) {
    control = control + 1;
    let element = invariant[control];
    if (element) {
        return [control, element];
    }
}
class OvaleQueue {
    NewDeque(name) {
        return _setmetatable({
            name: name,
            first: 0,
            last: -1
        }, OvaleQueue);
    }
    InsertFront(element) {
        let first = this.first - 1;
        this.first = first;
        this[first] = element;
    }
    InsertBack(element) {
        let last = this.last + 1;
        this.last = last;
        this[last] = element;
    }
    RemoveFront() {
        let first = this.first;
        let element = this[first];
        if (element) {
            this[first] = undefined;
            this.first = first + 1;
        }
        return element;
    }
    RemoveBack() {
        let last = this.last;
        let element = this[last];
        if (element) {
            this[last] = undefined;
            this.last = last - 1;
        }
        return element;
    }
    At(index) {
        if (index > this.Size()) {
            break;
        }
        return this[this.first + index - 1];
    }
    Front() {
        return this[this.first];
    }
    Back() {
        return this[this.last];
    }
    BackToFrontIterator() {
        return [BackToFrontIterator, this, this.last + 1];
    }
    FrontToBackIterator() {
        return [FrontToBackIterator, this, this.first - 1];
    }
    Reset() {
        for (const [i] of this.BackToFrontIterator()) {
            this[i] = undefined;
        }
        this.first = 0;
        this.last = -1;
    }
    Size() {
        return this.last - this.first + 1;
    }
    DebuggingInfo() {
        Ovale.Print("Queue %s has %d item(s), first=%d, last=%d.", this.name, this.Size(), this.first, this.last);
    }
}
OvaleQueue.NewQueue = OvaleQueue.NewDeque;
OvaleQueue.Insert = OvaleQueue.InsertBack;
OvaleQueue.Remove = OvaleQueue.RemoveFront;
OvaleQueue.Iterator = OvaleQueue.FrontToBackIterator;
OvaleQueue.NewStack = OvaleQueue.NewDeque;
OvaleQueue.Push = OvaleQueue.InsertBack;
OvaleQueue.Pop = OvaleQueue.RemoveBack;
OvaleQueue.Top = OvaleQueue.Back;
