import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleTimeSpan = {  }
Ovale.OvaleTimeSpan = OvaleTimeSpan;
let _select = select;
let _setmetatable = setmetatable;
let format = string.format;
let tconcat = table.concat;
let tinsert = table.insert;
let tremove = table.remove;
let _type = type;
let _wipe = wipe;
let INFINITY = math.huge;
let self_pool = {  }
let self_poolSize = 0;
let self_poolUnused = 0;
let EMPTY_SET = _setmetatable({  }, OvaleTimeSpan);
let UNIVERSE = _setmetatable({ 1: 0, 2: INFINITY }, OvaleTimeSpan);
OvaleTimeSpan.__index = OvaleTimeSpan;
{
    _setmetatable(OvaleTimeSpan, { __call: function (self, ...__args) {
        return this.New(...__args);
    } });
}
OvaleTimeSpan.EMPTY_SET = EMPTY_SET;
OvaleTimeSpan.UNIVERSE = UNIVERSE;
const CompareIntervals = function(startA, endA, startB, endB) {
    if (startA == startB && endA == endB) {
        return 0;
    } else if (startA < startB && endA >= startB && endA <= endB) {
        return -1;
    } else if (startB < startA && endB >= startA && endB <= endA) {
        return 1;
    } else if ((startA == startB && endA > endB) || (startA < startB && endA == endB) || (startA < startB && endA > endB)) {
        return -2;
    } else if ((startB == startA && endB > endA) || (startB < startA && endB == endA) || (startB < startA && endB > endA)) {
        return 2;
    } else if (endA <= startB) {
        return -3;
    } else if (endB <= startA) {
        return 3;
    }
    return 99;
}
class OvaleTimeSpan {
    New(...__args) {
        let obj = tremove(self_pool);
        if (obj) {
            self_poolUnused = self_poolUnused - 1;
        } else {
            obj = {  }
            self_poolSize = self_poolSize + 1;
        }
        _setmetatable(obj, this);
        obj = OvaleTimeSpan.Copy(obj, ...__args);
        return obj;
    }
    Release(...__args) {
        let A = __args;
        if (A) {
            let argc = _select("#", ...__args);
            for (let i = 1; i <= argc; i += 1) {
                A = _select(i, ...__args);
                _wipe(A);
                tinsert(self_pool, A);
            }
            self_poolUnused = self_poolUnused + argc;
        } else {
            _wipe(this);
            tinsert(self_pool, this);
            self_poolUnused = self_poolUnused + 1;
        }
    }
    GetPoolInfo() {
        return [self_poolSize, self_poolUnused];
    }
    __tostring() {
        if (lualength(this) == 0) {
            return "empty set";
        } else {
            return format("(%s)", tconcat(this, ", "));
        }
    }
    Copy(...__args) {
        let A = __args;
        let count = 0;
        if (_type(A) == "table") {
            count = lualength(A);
            for (let i = 1; i <= count; i += 1) {
                this[i] = A[i];
            }
        } else {
            count = _select("#", ...__args);
            for (let i = 1; i <= count; i += 1) {
                this[i] = _select(i, ...__args);
            }
        }
        for (let i = count + 1; i <= lualength(this); i += 1) {
            this[i] = undefined;
        }
        return this;
    }
    IsEmpty() {
        return lualength(this) == 0;
    }
    IsUniverse() {
        return this[1] == 0 && this[2] == INFINITY;
    }
    Equals(B) {
        let A = this;
        let countA = lualength(A);
        let countB = B && lualength(B) || 0;
        if (countA != countB) {
            return false;
        }
        for (let k = 1; k <= countA; k += 1) {
            if (A[k] != B[k]) {
                return false;
            }
        }
        return true;
    }
    HasTime(atTime) {
        let A = this;
        for (let i = 1; i <= lualength(A); i += 2) {
            if (A[i] <= atTime && atTime <= A[i + 1]) {
                return true;
            }
        }
        return false;
    }
    NextTime(atTime) {
        let A = this;
        for (let i = 1; i <= lualength(A); i += 2) {
            if (atTime < A[i]) {
                return A[i];
            } else if (A[i] <= atTime && atTime <= A[i + 1]) {
                return atTime;
            }
        }
    }
    Measure() {
        let A = this;
        let measure = 0;
        for (let i = 1; i <= lualength(A); i += 2) {
            measure = measure + (A[i + 1] - A[i]);
        }
        return measure;
    }
    Complement(result) {
        let A = this;
        let countA = lualength(A);
        if (countA == 0) {
            if (result) {
                result.Copy(UNIVERSE);
            } else {
                result = OvaleTimeSpan.New(UNIVERSE);
            }
        } else {
            result = result || OvaleTimeSpan.New();
            let countResult = 0;
            let [i, k] = [1, 1];
            if (A[i] == 0) {
                i = i + 1;
            } else {
                result[k] = 0;
                countResult = k;
                k = k + 1;
            }
            while (i < countA) {
                result[k] = A[i];
                countResult = k;
                [i, k] = [i + 1, k + 1];
            }
            if (A[i] < INFINITY) {
                [result[k], result[k + 1]] = [A[i], INFINITY];
                countResult = k + 1;
            }
            for (let j = countResult + 1; j <= lualength(result); j += 1) {
                result[j] = undefined;
            }
        }
        return result;
    }
    IntersectInterval(startB, endB, result) {
        let A = this;
        let countA = lualength(A);
        result = result || OvaleTimeSpan.New();
        if (countA > 0 && startB && endB) {
            let countResult = 0;
            let [i, k] = [1, 1];
            while (true) {
                if (i > countA) {
                    break;
                }
                let [startA, endA] = [A[i], A[i + 1]];
                let compare = CompareIntervals(startA, endA, startB, endB);
                if (compare == 0) {
                    [result[k], result[k + 1]] = [startA, endA];
                    countResult = k + 1;
                    break;
                } else if (compare == -1) {
                    if (endA > startB) {
                        [result[k], result[k + 1]] = [startB, endA];
                        countResult = k + 1;
                        [i, k] = [i + 2, k + 2];
                    } else {
                        i = i + 2;
                    }
                } else if (compare == 1) {
                    if (endB > startA) {
                        [result[k], result[k + 1]] = [startA, endB];
                        countResult = k + 1;
                    }
                    break;
                } else if (compare == -2) {
                    [result[k], result[k + 1]] = [startB, endB];
                    countResult = k + 1;
                    break;
                } else if (compare == 2) {
                    [result[k], result[k + 1]] = [startA, endA];
                    countResult = k + 1;
                    [i, k] = [i + 2, k + 2];
                } else if (compare == -3) {
                    i = i + 2;
                } else if (compare == 3) {
                    break;
                }
            }
            for (let n = countResult + 1; n <= lualength(result); n += 1) {
                result[n] = undefined;
            }
        }
        return result;
    }
    Intersect(B, result) {
        let A = this;
        let countA = lualength(A);
        let countB = B && lualength(B) || 0;
        result = result || OvaleTimeSpan.New();
        let countResult = 0;
        if (countA > 0 && countB > 0) {
            let [i, j, k] = [1, 1, 1];
            while (true) {
                if (i > countA || j > countB) {
                    break;
                }
                let [startA, endA] = [A[i], A[i + 1]];
                let [startB, endB] = [B[j], B[j + 1]];
                let compare = CompareIntervals(startA, endA, startB, endB);
                if (compare == 0) {
                    [result[k], result[k + 1]] = [startA, endA];
                    countResult = k + 1;
                    [i, j, k] = [i + 2, j + 2, k + 2];
                } else if (compare == -1) {
                    if (endA > startB) {
                        [result[k], result[k + 1]] = [startB, endA];
                        countResult = k + 1;
                        [i, k] = [i + 2, k + 2];
                    } else {
                        i = i + 2;
                    }
                } else if (compare == 1) {
                    if (endB > startA) {
                        [result[k], result[k + 1]] = [startA, endB];
                        countResult = k + 1;
                        [j, k] = [j + 2, k + 2];
                    } else {
                        j = j + 2;
                    }
                } else if (compare == -2) {
                    [result[k], result[k + 1]] = [startB, endB];
                    countResult = k + 1;
                    [j, k] = [j + 2, k + 2];
                } else if (compare == 2) {
                    [result[k], result[k + 1]] = [startA, endA];
                    countResult = k + 1;
                    [i, k] = [i + 2, k + 2];
                } else if (compare == -3) {
                    i = i + 2;
                } else if (compare == 3) {
                    j = j + 2;
                } else {
                    i = i + 2;
                    j = j + 2;
                }
            }
        }
        for (let n = countResult + 1; n <= lualength(result); n += 1) {
            result[n] = undefined;
        }
        return result;
    }
    Union(B, result) {
        let A = this;
        let countA = lualength(A);
        let countB = B && lualength(B) || 0;
        if (countA == 0) {
            if (B) {
                if (result) {
                    result.Copy(B);
                } else {
                    result = OvaleTimeSpan.New(B);
                }
            }
        } else if (countB == 0) {
            if (result) {
                result.Copy(A);
            } else {
                result = OvaleTimeSpan.New(A);
            }
        } else {
            result = result || OvaleTimeSpan.New();
            let countResult = 0;
            let [i, j, k] = [1, 1, 1];
            let [startTemp, endTemp] = [A[i], A[i + 1]];
            let holdingA = true;
            let scanningA = false;
            while (true) {
                let [startA, endA, startB, endB];
                if (i > countA && j > countB) {
                    [result[k], result[k + 1]] = [startTemp, endTemp];
                    countResult = k + 1;
                    k = k + 2;
                    break;
                }
                if (scanningA && i > countA) {
                    holdingA = !holdingA;
                    scanningA = !scanningA;
                } else {
                    [startA, endA] = [A[i], A[i + 1]];
                }
                if (!scanningA && j > countB) {
                    holdingA = !holdingA;
                    scanningA = !scanningA;
                } else {
                    [startB, endB] = [B[j], B[j + 1]];
                }
                let startCurrent = scanningA && startA || startB;
                let endCurrent = scanningA && endA || endB;
                let compare = CompareIntervals(startTemp, endTemp, startCurrent, endCurrent);
                if (compare == 0) {
                    if (scanningA) {
                        i = i + 2;
                    } else {
                        j = j + 2;
                    }
                } else if (compare == -2) {
                    if (scanningA) {
                        i = i + 2;
                    } else {
                        j = j + 2;
                    }
                } else if (compare == -1) {
                    endTemp = endCurrent;
                    if (scanningA) {
                        i = i + 2;
                    } else {
                        j = j + 2;
                    }
                } else if (compare == 1) {
                    startTemp = startCurrent;
                    if (scanningA) {
                        i = i + 2;
                    } else {
                        j = j + 2;
                    }
                } else if (compare == 2) {
                    [startTemp, endTemp] = [startCurrent, endCurrent];
                    holdingA = !holdingA;
                    scanningA = !scanningA;
                    if (scanningA) {
                        i = i + 2;
                    } else {
                        j = j + 2;
                    }
                } else if (compare == -3) {
                    if (holdingA == scanningA) {
                        [result[k], result[k + 1]] = [startTemp, endTemp];
                        countResult = k + 1;
                        [startTemp, endTemp] = [startCurrent, endCurrent];
                        scanningA = !scanningA;
                        k = k + 2;
                    } else {
                        scanningA = !scanningA;
                        if (scanningA) {
                            i = i + 2;
                        } else {
                            j = j + 2;
                        }
                    }
                } else if (compare == 3) {
                    [startTemp, endTemp] = [startCurrent, endCurrent];
                    holdingA = !holdingA;
                    scanningA = !scanningA;
                } else {
                    i = i + 2;
                    j = j + 2;
                }
            }
            for (let n = countResult + 1; n <= lualength(result); n += 1) {
                result[n] = undefined;
            }
        }
        return result;
    }
}
