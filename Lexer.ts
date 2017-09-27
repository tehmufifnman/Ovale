import __addon from "addon";
let [OVALE, Ovale] = __addon;
let OvaleLexer = {
}
Ovale.OvaleLexer = OvaleLexer;
import { OvaleQueue } from "./OvaleQueue";
let _pairs = pairs;
let _setmetatable = setmetatable;
let _error = error;
let _ipairs = ipairs;
let _tonumber = tonumber;
let _type = type;
let [yield, wrap] = [coroutine.yield, coroutine.wrap];
let strfind = string.find;
let strsub = string.sub;
let append = table.insert;
const assert_arg = function(idx, val, tp) {
    if (_type(val) != tp) {
        _error("argument " + idx + " must be " + tp, 2);
    }
}
let lexer = {
}
let NUMBER1 = '^[%+%-]?%d+%.?%d*[eE][%+%-]?%d+';
let NUMBER2 = '^[%+%-]?%d+%.?%d*';
let NUMBER3 = '^0x[%da-fA-F]+';
let NUMBER4 = '^%d+%.?%d*[eE][%+%-]?%d+';
let NUMBER5 = '^%d+%.?%d*';
let IDEN = '^[%a_][%w_]*';
let WSPACE = '^%s+';
let STRING0 = `^(['\"]).-\\%1`;
let STRING1 = `^(['\"]).-[^\]%1`;
let STRING3 = "^((['\"])%2)";
let PREPRO = '^#.-[^\\]\n';
let [plain_matches, lua_matches, cpp_matches, lua_keyword, cpp_keyword];
const tdump = function(tok) {
    return yield(tok, tok);
}
const ndump = function(tok, options) {
    if (options && options.number) {
        tok = _tonumber(tok);
    }
    return yield("number", tok);
}
const sdump = function(tok, options) {
    if (options && options.string) {
        tok = tok.sub(2, -2);
    }
    return yield("string", tok);
}
const sdump_l = function(tok, options, findres) {
    if (options && options.string) {
        let quotelen = 3;
        if (findres[3]) {
            quotelen = quotelen + findres[3].len();
        }
        tok = tok.sub(quotelen, -1 * quotelen);
    }
    return yield("string", tok);
}
const chdump = function(tok, options) {
    if (options && options.string) {
        tok = tok.sub(2, -2);
    }
    return yield("char", tok);
}
const cdump = function(tok) {
    return yield('comment', tok);
}
const wsdump = function(tok) {
    return yield("space", tok);
}
const pdump = function(tok) {
    return yield('prepro', tok);
}
const plain_vdump = function(tok) {
    return yield("iden", tok);
}
const lua_vdump = function(tok) {
    if (lua_keyword[tok]) {
        return yield("keyword", tok);
    } else {
        return yield("iden", tok);
    }
}
const cpp_vdump = function(tok) {
    if (cpp_keyword[tok]) {
        return yield("keyword", tok);
    } else {
        return yield("iden", tok);
    }
}
class lexer {
    scan(s, matches, filter, options) {
        let file = _type(s) != 'string' && s;
        filter = filter || {
            space: true
        }
        options = options || {
            number: true,
            string: true
        }
        if (filter) {
            if (filter.space) {
                filter[wsdump] = true;
            }
            if (filter.comments) {
                filter[cdump] = true;
            }
        }
        if (!matches) {
            if (!plain_matches) {
                plain_matches = {
                    1: {
                        1: WSPACE,
                        2: wsdump
                    },
                    2: {
                        1: NUMBER3,
                        2: ndump
                    },
                    3: {
                        1: IDEN,
                        2: plain_vdump
                    },
                    4: {
                        1: NUMBER1,
                        2: ndump
                    },
                    5: {
                        1: NUMBER2,
                        2: ndump
                    },
                    6: {
                        1: STRING3,
                        2: sdump
                    },
                    7: {
                        1: STRING0,
                        2: sdump
                    },
                    8: {
                        1: STRING1,
                        2: sdump
                    },
                    9: {
                        1: '^.',
                        2: tdump
                    }
                }
            }
            matches = plain_matches;
        }
        const lex = function() {
            if (_type(s) == 'string' && s == '') {
                break;
            }
            let [findres, i1, i2, idx, res1, res2, tok, pat, fun, capt];
            let line = 1;
            if (file) {
                s = file.read() + '\n';
            }
            let sz = lualength(s);
            let idx = 1;
            while (true) {
                for (const [_, m] of _ipairs(matches)) {
                    pat = m[1];
                    fun = m[2];
                    findres = {
                        1: strfind(s, pat, idx)
                    }
                    i1 = findres[1];
                    i2 = findres[2];
                    if (i1) {
                        tok = strsub(s, i1, i2);
                        idx = i2 + 1;
                        if (!(filter && filter[fun])) {
                            lexer.finished = idx > sz;
                            [res1, res2] = fun(tok, options, findres);
                        }
                        if (res1) {
                            let tp = _type(res1);
                            if (tp == 'table') {
                                yield('', '');
                                for (const [_, t] of _ipairs(res1)) {
                                    yield(t[1], t[2]);
                                }
                            } else if (tp == 'string') {
                                [i1, i2] = strfind(s, res1, idx);
                                if (i1) {
                                    tok = strsub(s, i1, i2);
                                    idx = i2 + 1;
                                    yield('', tok);
                                } else {
                                    yield('', '');
                                    idx = sz + 1;
                                }
                            } else {
                                yield(line, idx);
                            }
                        }
                        if (idx > sz) {
                            if (file) {
                                line = line + 1;
                                s = file.read();
                                if (!s) {
                                    break;
                                }
                                s = s + '\n';
                                [idx, sz] = [1, lualength(s)];
                                break;
                            } else {
                                break;
                            }
                        } else {
                            break;
                        }
                    }
                }
            }
        }
        return wrap(lex);
    }
}
const isstring = function(s) {
    return _type(s) == 'string';
}
class lexer {
    insert(tok, a1, a2) {
        if (!a1) {
            break;
        }
        let ts;
        if (isstring(a1) && isstring(a2)) {
            ts = {
                1: {
                    1: a1,
                    2: a2
                }
            }
        } else if (_type(a1) == 'function') {
            ts = {
            }
            for (const [t, v] of a1()) {
                append(ts, {
                    1: t,
                    2: v
                });
            }
        } else {
            ts = a1;
        }
        tok(ts);
    }
    getline(tok) {
        let [t, v] = tok('.-\n');
        return v;
    }
    lineno(tok) {
        return tok(0);
    }
    getrest(tok) {
        let [t, v] = tok('.+');
        return v;
    }
    get_keywords() {
        if (!lua_keyword) {
            lua_keyword = {
                ["and"]: true,
                ["break"]: true,
                ["do"]: true,
                ["else"]: true,
                ["elseif"]: true,
                ["end"]: true,
                ["false"]: true,
                ["for"]: true,
                ["function"]: true,
                ["if"]: true,
                ["in"]: true,
                ["local"]: true,
                ["nil"]: true,
                ["not"]: true,
                ["or"]: true,
                ["repeat"]: true,
                ["return"]: true,
                ["then"]: true,
                ["true"]: true,
                ["until"]: true,
                ["while"]: true
            }
        }
        return lua_keyword;
    }
    lua(s, filter, options) {
        filter = filter || {
            space: true,
            comments: true
        }
        lexer.get_keywords();
        if (!lua_matches) {
            lua_matches = {
                1: {
                    1: WSPACE,
                    2: wsdump
                },
                2: {
                    1: NUMBER3,
                    2: ndump
                },
                3: {
                    1: IDEN,
                    2: lua_vdump
                },
                4: {
                    1: NUMBER4,
                    2: ndump
                },
                5: {
                    1: NUMBER5,
                    2: ndump
                },
                6: {
                    1: STRING3,
                    2: sdump
                },
                7: {
                    1: STRING0,
                    2: sdump
                },
                8: {
                    1: STRING1,
                    2: sdump
                },
                9: {
                    1: '^%-%-%[(=*)%[.-%]%1%]',
                    2: cdump
                },
                10: {
                    1: '^%-%-.-\n',
                    2: cdump
                },
                11: {
                    1: '^%[(=*)%[.-%]%1%]',
                    2: sdump_l
                },
                12: {
                    1: '^==',
                    2: tdump
                },
                13: {
                    1: '^~=',
                    2: tdump
                },
                14: {
                    1: '^<=',
                    2: tdump
                },
                15: {
                    1: '^>=',
                    2: tdump
                },
                16: {
                    1: '^%.%.%.',
                    2: tdump
                },
                17: {
                    1: '^%.%.',
                    2: tdump
                },
                18: {
                    1: '^.',
                    2: tdump
                }
            }
        }
        return lexer.scan(s, lua_matches, filter, options);
    }
    cpp(s, filter, options) {
        filter = filter || {
            comments: true
        }
        if (!cpp_keyword) {
            cpp_keyword = {
                ["class"]: true,
                ["break"]: true,
                ["do"]: true,
                ["sizeof"]: true,
                ["else"]: true,
                ["continue"]: true,
                ["struct"]: true,
                ["false"]: true,
                ["for"]: true,
                ["public"]: true,
                ["void"]: true,
                ["private"]: true,
                ["protected"]: true,
                ["goto"]: true,
                ["if"]: true,
                ["static"]: true,
                ["const"]: true,
                ["typedef"]: true,
                ["enum"]: true,
                ["char"]: true,
                ["int"]: true,
                ["bool"]: true,
                ["long"]: true,
                ["float"]: true,
                ["true"]: true,
                ["delete"]: true,
                ["double"]: true,
                ["while"]: true,
                ["new"]: true,
                ["namespace"]: true,
                ["try"]: true,
                ["catch"]: true,
                ["switch"]: true,
                ["case"]: true,
                ["extern"]: true,
                ["return"]: true,
                ["default"]: true,
                ['unsigned']: true,
                ['signed']: true,
                ["union"]: true,
                ["volatile"]: true,
                ["register"]: true,
                ["short"]: true
            }
        }
        if (!cpp_matches) {
            cpp_matches = {
                1: {
                    1: WSPACE,
                    2: wsdump
                },
                2: {
                    1: PREPRO,
                    2: pdump
                },
                3: {
                    1: NUMBER3,
                    2: ndump
                },
                4: {
                    1: IDEN,
                    2: cpp_vdump
                },
                5: {
                    1: NUMBER4,
                    2: ndump
                },
                6: {
                    1: NUMBER5,
                    2: ndump
                },
                7: {
                    1: STRING3,
                    2: sdump
                },
                8: {
                    1: STRING1,
                    2: chdump
                },
                9: {
                    1: '^//.-\n',
                    2: cdump
                },
                10: {
                    1: '^/%*.-%*/',
                    2: cdump
                },
                11: {
                    1: '^==',
                    2: tdump
                },
                12: {
                    1: '^!=',
                    2: tdump
                },
                13: {
                    1: '^<=',
                    2: tdump
                },
                14: {
                    1: '^>=',
                    2: tdump
                },
                15: {
                    1: '^->',
                    2: tdump
                },
                16: {
                    1: '^&&',
                    2: tdump
                },
                17: {
                    1: '^||',
                    2: tdump
                },
                18: {
                    1: '^%+%+',
                    2: tdump
                },
                19: {
                    1: '^%-%-',
                    2: tdump
                },
                20: {
                    1: '^%+=',
                    2: tdump
                },
                21: {
                    1: '^%-=',
                    2: tdump
                },
                22: {
                    1: '^%*=',
                    2: tdump
                },
                23: {
                    1: '^/=',
                    2: tdump
                },
                24: {
                    1: '^|=',
                    2: tdump
                },
                25: {
                    1: '^%^=',
                    2: tdump
                },
                26: {
                    1: '^::',
                    2: tdump
                },
                27: {
                    1: '^.',
                    2: tdump
                }
            }
        }
        return lexer.scan(s, cpp_matches, filter, options);
    }
    get_separated_list(tok, endtoken, delim) {
        endtoken = endtoken || ')';
        delim = delim || ',';
        let parm_values = {
        }
        let level = 1;
        let tl = {
        }
        const tappend = function(tl, t, val) {
            val = val || t;
            append(tl, {
                1: t,
                2: val
            });
        }
        let is_end;
        if (endtoken == '\n') {
            is_end = function (t, val) {
                return t == 'space' && val.find'\n';
            }
        } else {
            is_end = function (t) {
                return t == endtoken;
            }
        }
        let [token, value];
        while (true) {
            [token, value] = tok();
            if (!token) {
                return [undefined, 'EOS'];
            }
            if (is_end(token, value) && level == 1) {
                append(parm_values, tl);
                break;
            } else if (token == '(') {
                level = level + 1;
                tappend(tl, '(');
            } else if (token == ')') {
                level = level - 1;
                if (level == 0) {
                    append(parm_values, tl);
                    break;
                } else {
                    tappend(tl, ')');
                }
            } else if (token == delim && level == 1) {
                append(parm_values, tl);
                tl = {
                }
            } else {
                tappend(tl, token, value);
            }
        }
        return [parm_values, {
            1: token,
            2: value
        }];
    }
    skipws(tok) {
        let [t, v] = tok();
        while (t == 'space') {
            [t, v] = tok();
        }
        return [t, v];
    }
}
let skipws = lexer.skipws;
class lexer {
    expecting(tok, expected_type, no_skip_ws) {
        assert_arg(1, tok, 'function');
        assert_arg(2, expected_type, 'string');
        let [t, v];
        if (no_skip_ws) {
            [t, v] = tok();
        } else {
            [t, v] = skipws(tok);
        }
        if (t != expected_type) {
            _error("expecting " + expected_type, 2);
        }
        return v;
    }
}
OvaleLexer.typeQueue = undefined;
OvaleLexer.tokenQueue = undefined;
OvaleLexer.iterator = undefined;
OvaleLexer.endOfStream = undefined;
OvaleLexer.scan = lexer.scan;
OvaleLexer.__index = OvaleLexer;
{
    _setmetatable(OvaleLexer, {
        __call: function (self, ...__args) {
            return this.New(...__args);
        }
    });
}
class OvaleLexer {
    New(name, iterator) {
        let obj = {
            typeQueue: OvaleQueue.NewDeque(name + "_typeQueue"),
            tokenQueue: OvaleQueue.NewDeque(name + "_tokenQueue"),
            iterator: iterator
        }
        return _setmetatable(obj, this);
    }
    Release() {
        for (const [key] of _pairs(this)) {
            this[key] = undefined;
        }
    }
    Consume(index) {
        index = index || 1;
        let [tokenType, token];
        while (index > 0 && this.typeQueue.Size() > 0) {
            tokenType = this.typeQueue.RemoveFront();
            token = this.tokenQueue.RemoveFront();
            if (!tokenType) {
                break;
            }
            index = index - 1;
        }
        while (index > 0) {
            [tokenType, token] = this.iterator();
            if (!tokenType) {
                break;
            }
            index = index - 1;
        }
        return [tokenType, token];
    }
    Peek(index) {
        index = index || 1;
        let [tokenType, token];
        while (index > this.typeQueue.Size()) {
            if (this.endOfStream) {
                break;
            } else {
                [tokenType, token] = this.iterator();
                if (!tokenType) {
                    this.endOfStream = true;
                    break;
                }
                this.typeQueue.InsertBack(tokenType);
                this.tokenQueue.InsertBack(token);
            }
        }
        if (index <= this.typeQueue.Size()) {
            tokenType = this.typeQueue.At(index);
            token = this.tokenQueue.At(index);
        }
        return [tokenType, token];
    }
}
