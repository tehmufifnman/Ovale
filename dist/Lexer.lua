local OVALE, Ovale = ...
require(OVALE, Ovale, "Lexer", { "./OvaleQueue" }, function(__exports, __OvaleQueue)
local OvaleLexer = {}
Ovale.OvaleLexer = OvaleLexer
local _pairs = pairs
local _setmetatable = setmetatable
local _error = error
local _ipairs = ipairs
local _tonumber = tonumber
local _type = type
local yield, wrap = coroutine.yield, coroutine.wrap
local strfind = string.find
local strsub = string.sub
local append = table.insert
local assert_arg = function(idx, val, tp)
    if _type(val) ~= tp then
        _error("argument " + idx + " must be " + tp, 2)
    end
end
local lexer = {}
local NUMBER1 = "^[%+%-]?%d+%.?%d*[eE][%+%-]?%d+"
local NUMBER2 = "^[%+%-]?%d+%.?%d*"
local NUMBER3 = "^0x[%da-fA-F]+"
local NUMBER4 = "^%d+%.?%d*[eE][%+%-]?%d+"
local NUMBER5 = "^%d+%.?%d*"
local IDEN = "^[%a_][%w_]*"
local WSPACE = "^%s+"
local STRING0 = [[^(['"]).-\%1]]
local STRING1 = [[^(['"]).-[^]%1]]
local STRING3 = "^((['"])%2)"
local PREPRO = "^#.-[^\]\n"
local plain_matches, lua_matches, cpp_matches, lua_keyword, cpp_keyword
local tdump = function(tok)
    return yield(tok, tok)
end
local ndump = function(tok, options)
    if options and options.number then
        tok = _tonumber(tok)
    end
    return yield("number", tok)
end
local sdump = function(tok, options)
    if options and options.string then
        tok = tok:sub(2, -2)
    end
    return yield("string", tok)
end
local sdump_l = function(tok, options, findres)
    if options and options.string then
        local quotelen = 3
        if findres[3] then
            quotelen = quotelen + findres[3]:len()
        end
        tok = tok:sub(quotelen, -1 * quotelen)
    end
    return yield("string", tok)
end
local chdump = function(tok, options)
    if options and options.string then
        tok = tok:sub(2, -2)
    end
    return yield("char", tok)
end
local cdump = function(tok)
    return yield("comment", tok)
end
local wsdump = function(tok)
    return yield("space", tok)
end
local pdump = function(tok)
    return yield("prepro", tok)
end
local plain_vdump = function(tok)
    return yield("iden", tok)
end
local lua_vdump = function(tok)
    if lua_keyword[tok] then
        return yield("keyword", tok)
    else
        return yield("iden", tok)
    end
end
local cpp_vdump = function(tok)
    if cpp_keyword[tok] then
        return yield("keyword", tok)
    else
        return yield("iden", tok)
    end
end
local lexer = __class()
function lexer:scan(s, matches, filter, options)
    local file = _type(s) ~= "string" and s
    filter = filter or {
        space = true
    }
    options = options or {
        number = true,
        string = true
    }
    if filter then
        if filter.space then
            filter[wsdump] = true
        end
        if filter.comments then
            filter[cdump] = true
        end
    end
    if  not matches then
        if  not plain_matches then
            plain_matches = {
                1 = {
                    1 = WSPACE,
                    2 = wsdump
                },
                2 = {
                    1 = NUMBER3,
                    2 = ndump
                },
                3 = {
                    1 = IDEN,
                    2 = plain_vdump
                },
                4 = {
                    1 = NUMBER1,
                    2 = ndump
                },
                5 = {
                    1 = NUMBER2,
                    2 = ndump
                },
                6 = {
                    1 = STRING3,
                    2 = sdump
                },
                7 = {
                    1 = STRING0,
                    2 = sdump
                },
                8 = {
                    1 = STRING1,
                    2 = sdump
                },
                9 = {
                    1 = "^.",
                    2 = tdump
                }
            }
        end
        matches = plain_matches
    end
    local lex = function()
        if _type(s) == "string" and s == "" then
            break
        end
        local findres, i1, i2, idx, res1, res2, tok, pat, fun, capt
        local line = 1
        if file then
            s = file:read() + "\n"
        end
        local sz = #s
        local idx = 1
        while truedo
            for _, m in _ipairs(matches) do
                pat = m[1]
                fun = m[2]
                findres = {
                    1 = strfind(s, pat, idx)
                }
                i1 = findres[1]
                i2 = findres[2]
                if i1 then
                    tok = strsub(s, i1, i2)
                    idx = i2 + 1
                    if  not (filter and filter[fun]) then
                        lexer.finished = idx > sz
                        res1, res2 = fun(tok, options, findres)
                    end
                    if res1 then
                        local tp = _type(res1)
                        if tp == "table" then
                            yield("", "")
                            for _, t in _ipairs(res1) do
                                yield(t[1], t[2])
                            end
                        elseif tp == "string" then
                            i1, i2 = strfind(s, res1, idx)
                            if i1 then
                                tok = strsub(s, i1, i2)
                                idx = i2 + 1
                                yield("", tok)
                            else
                                yield("", "")
                                idx = sz + 1
                            end
                        else
                            yield(line, idx)
                        end
                    end
                    if idx > sz then
                        if file then
                            line = line + 1
                            s = file:read()
                            if  not s then
                                break
                            end
                            s = s + "\n"
                            idx, sz = 1, #s
                            break
                        else
                            break
                        end
                    else
                        break
                    end
                end
            end
end
    end
    return wrap(lex)
end
local isstring = function(s)
    return _type(s) == "string"
end
local lexer = __class()
function lexer:insert(tok, a1, a2)
    if  not a1 then
        break
    end
    local ts
    if isstring(a1) and isstring(a2) then
        ts = {
            1 = {
                1 = a1,
                2 = a2
            }
        }
    elseif _type(a1) == "function" then
        ts = {}
        for t, v in a1() do
            append(ts, {
                1 = t,
                2 = v
            })
        end
    else
        ts = a1
    end
    tok(ts)
end
function lexer:getline(tok)
    local t, v = tok(".-\n")
    return v
end
function lexer:lineno(tok)
    return tok(0)
end
function lexer:getrest(tok)
    local t, v = tok(".+")
    return v
end
function lexer:get_keywords()
    if  not lua_keyword then
        lua_keyword = {
            ["and"] = true,
            ["break"] = true,
            ["do"] = true,
            ["else"] = true,
            ["elseif"] = true,
            ["end"] = true,
            ["false"] = true,
            ["for"] = true,
            ["function"] = true,
            ["if"] = true,
            ["in"] = true,
            ["local"] = true,
            ["nil"] = true,
            ["not"] = true,
            ["or"] = true,
            ["repeat"] = true,
            ["return"] = true,
            ["then"] = true,
            ["true"] = true,
            ["until"] = true,
            ["while"] = true
        }
    end
    return lua_keyword
end
function lexer:lua(s, filter, options)
    filter = filter or {
        space = true,
        comments = true
    }
    lexer:get_keywords()
    if  not lua_matches then
        lua_matches = {
            1 = {
                1 = WSPACE,
                2 = wsdump
            },
            2 = {
                1 = NUMBER3,
                2 = ndump
            },
            3 = {
                1 = IDEN,
                2 = lua_vdump
            },
            4 = {
                1 = NUMBER4,
                2 = ndump
            },
            5 = {
                1 = NUMBER5,
                2 = ndump
            },
            6 = {
                1 = STRING3,
                2 = sdump
            },
            7 = {
                1 = STRING0,
                2 = sdump
            },
            8 = {
                1 = STRING1,
                2 = sdump
            },
            9 = {
                1 = "^%-%-%[(=*)%[.-%]%1%]",
                2 = cdump
            },
            10 = {
                1 = "^%-%-.-\n",
                2 = cdump
            },
            11 = {
                1 = "^%[(=*)%[.-%]%1%]",
                2 = sdump_l
            },
            12 = {
                1 = "^==",
                2 = tdump
            },
            13 = {
                1 = "^~=",
                2 = tdump
            },
            14 = {
                1 = "^<=",
                2 = tdump
            },
            15 = {
                1 = "^>=",
                2 = tdump
            },
            16 = {
                1 = "^%.%.%.",
                2 = tdump
            },
            17 = {
                1 = "^%.%.",
                2 = tdump
            },
            18 = {
                1 = "^.",
                2 = tdump
            }
        }
    end
    return lexer:scan(s, lua_matches, filter, options)
end
function lexer:cpp(s, filter, options)
    filter = filter or {
        comments = true
    }
    if  not cpp_keyword then
        cpp_keyword = {
            ["class"] = true,
            ["break"] = true,
            ["do"] = true,
            ["sizeof"] = true,
            ["else"] = true,
            ["continue"] = true,
            ["struct"] = true,
            ["false"] = true,
            ["for"] = true,
            ["public"] = true,
            ["void"] = true,
            ["private"] = true,
            ["protected"] = true,
            ["goto"] = true,
            ["if"] = true,
            ["static"] = true,
            ["const"] = true,
            ["typedef"] = true,
            ["enum"] = true,
            ["char"] = true,
            ["int"] = true,
            ["bool"] = true,
            ["long"] = true,
            ["float"] = true,
            ["true"] = true,
            ["delete"] = true,
            ["double"] = true,
            ["while"] = true,
            ["new"] = true,
            ["namespace"] = true,
            ["try"] = true,
            ["catch"] = true,
            ["switch"] = true,
            ["case"] = true,
            ["extern"] = true,
            ["return"] = true,
            ["default"] = true,
            ["unsigned"] = true,
            ["signed"] = true,
            ["union"] = true,
            ["volatile"] = true,
            ["register"] = true,
            ["short"] = true
        }
    end
    if  not cpp_matches then
        cpp_matches = {
            1 = {
                1 = WSPACE,
                2 = wsdump
            },
            2 = {
                1 = PREPRO,
                2 = pdump
            },
            3 = {
                1 = NUMBER3,
                2 = ndump
            },
            4 = {
                1 = IDEN,
                2 = cpp_vdump
            },
            5 = {
                1 = NUMBER4,
                2 = ndump
            },
            6 = {
                1 = NUMBER5,
                2 = ndump
            },
            7 = {
                1 = STRING3,
                2 = sdump
            },
            8 = {
                1 = STRING1,
                2 = chdump
            },
            9 = {
                1 = "^//.-\n",
                2 = cdump
            },
            10 = {
                1 = "^/%*.-%*/",
                2 = cdump
            },
            11 = {
                1 = "^==",
                2 = tdump
            },
            12 = {
                1 = "^!=",
                2 = tdump
            },
            13 = {
                1 = "^<=",
                2 = tdump
            },
            14 = {
                1 = "^>=",
                2 = tdump
            },
            15 = {
                1 = "^->",
                2 = tdump
            },
            16 = {
                1 = "^&&",
                2 = tdump
            },
            17 = {
                1 = "^||",
                2 = tdump
            },
            18 = {
                1 = "^%+%+",
                2 = tdump
            },
            19 = {
                1 = "^%-%-",
                2 = tdump
            },
            20 = {
                1 = "^%+=",
                2 = tdump
            },
            21 = {
                1 = "^%-=",
                2 = tdump
            },
            22 = {
                1 = "^%*=",
                2 = tdump
            },
            23 = {
                1 = "^/=",
                2 = tdump
            },
            24 = {
                1 = "^|=",
                2 = tdump
            },
            25 = {
                1 = "^%^=",
                2 = tdump
            },
            26 = {
                1 = "^::",
                2 = tdump
            },
            27 = {
                1 = "^.",
                2 = tdump
            }
        }
    end
    return lexer:scan(s, cpp_matches, filter, options)
end
function lexer:get_separated_list(tok, endtoken, delim)
    endtoken = endtoken or ")"
    delim = delim or ","
    local parm_values = {}
    local level = 1
    local tl = {}
    local tappend = function(tl, t, val)
        val = val or t
        append(tl, {
            1 = t,
            2 = val
        })
    end
    local is_end
    if endtoken == "\n" then
        is_end = function(t, val)
            return t == "space" and val.find
            "\n"
        end
    else
        is_end = function(t)
            return t == endtoken
        end
    end
    local token, value
    while truedo
        token, value = tok()
        if  not token then
            return nil, "EOS"
        end
        if is_end(token, value) and level == 1 then
            append(parm_values, tl)
            break
        elseif token == "(" then
            level = level + 1
            tappend(tl, "(")
        elseif token == ")" then
            level = level - 1
            if level == 0 then
                append(parm_values, tl)
                break
            else
                tappend(tl, ")")
            end
        elseif token == delim and level == 1 then
            append(parm_values, tl)
            tl = {}
        else
            tappend(tl, token, value)
        end
end
    return parm_values, {
        1 = token,
        2 = value
    }
end
function lexer:skipws(tok)
    local t, v = tok()
    while t == "space"do
        t, v = tok()
end
    return t, v
end
local skipws = lexer.skipws
local lexer = __class()
function lexer:expecting(tok, expected_type, no_skip_ws)
    assert_arg(1, tok, "function")
    assert_arg(2, expected_type, "string")
    local t, v
    if no_skip_ws then
        t, v = tok()
    else
        t, v = skipws(tok)
    end
    if t ~= expected_type then
        _error("expecting " + expected_type, 2)
    end
    return v
end
OvaleLexer.typeQueue = nil
OvaleLexer.tokenQueue = nil
OvaleLexer.iterator = nil
OvaleLexer.endOfStream = nil
OvaleLexer.scan = lexer.scan
OvaleLexer.__index = OvaleLexer
do
    _setmetatable(OvaleLexer, {
        __call = function(self, ...)
            return self:New(...)
        end
    })
end
local OvaleLexer = __class()
function OvaleLexer:New(name, iterator)
    local obj = {
        typeQueue = __OvaleQueue.OvaleQueue:NewDeque(name + "_typeQueue"),
        tokenQueue = __OvaleQueue.OvaleQueue:NewDeque(name + "_tokenQueue"),
        iterator = iterator
    }
    return _setmetatable(obj, self)
end
function OvaleLexer:Release()
    for key in _pairs(self) do
        self[key] = nil
    end
end
function OvaleLexer:Consume(index)
    index = index or 1
    local tokenType, token
    while index > 0 and self.typeQueue:Size() > 0do
        tokenType = self.typeQueue:RemoveFront()
        token = self.tokenQueue:RemoveFront()
        if  not tokenType then
            break
        end
        index = index - 1
end
    while index > 0do
        tokenType, token = self:iterator()
        if  not tokenType then
            break
        end
        index = index - 1
end
    return tokenType, token
end
function OvaleLexer:Peek(index)
    index = index or 1
    local tokenType, token
    while index > self.typeQueue:Size()do
        if self.endOfStream then
            break
        else
            tokenType, token = self:iterator()
            if  not tokenType then
                self.endOfStream = true
                break
            end
            self.typeQueue:InsertBack(tokenType)
            self.tokenQueue:InsertBack(token)
        end
end
    if index <= self.typeQueue:Size() then
        tokenType = self.typeQueue:At(index)
        token = self.tokenQueue:At(index)
    end
    return tokenType, token
end
end))
