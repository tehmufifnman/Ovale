local __addonName, __addon = ...
            __addon.require("./Lexer", { "./Queue" }, function(__exports, __Queue)
local _pairs = pairs
local _setmetatable = setmetatable
local _error = error
local _ipairs = ipairs
local _tonumber = tonumber
local _type = type
local wrap = coroutine.wrap
local strfind = string.find
local strsub = string.sub
local append = table.insert
local assert_arg = function(idx, val, tp)
    if _type(val) ~= tp then
        _error("argument " .. idx .. " must be " .. tp, 2)
    end
end

__exports.OvaleLexer = __addon.__class(nil, {
    constructor = function(self, name, stream, matches, filter)
        self.name = name
        self.typeQueue = __Queue.OvaleQueue("typeQueue")
        self.tokenQueue = __Queue.OvaleQueue("tokenQueue")
        self.endOfStream = nil
        self.iterator = self:scan(stream, matches, filter)
    end,
    scan = function(self, s, matches, filter)
        local me = self
        local lex = function()
            if s == "" then
                return 
            end
            local sz = #s
            local idx = 1
            while true do
                for _, m in _ipairs(matches) do
                    local pat = m[1]
                    local fun = m[2]
                    local i1, i2 = strfind(s, pat, idx)
                    if i1 then
                        local tok = strsub(s, i1, i2)
                        idx = i2 + 1
                        if  not filter or (fun ~= filter.comments and fun ~= filter.space) then
                            me.finished = idx > sz
                            local res1, res2 = fun(tok)
                            coroutine.yield(res1, res2)
                        end
                        break
                    end
                end
            end
        end

        return wrap(lex)
    end,
    Release = function(self)
        for key in _pairs(self) do
            self[key] = nil
        end
    end,
    Consume = function(self, index)
        index = index or 1
        local tokenType, token
        while index > 0 and self.typeQueue:Size() > 0 do
            tokenType = self.typeQueue:RemoveFront()
            token = self.tokenQueue:RemoveFront()
            if  not tokenType then
                break
            end
            index = index - 1
        end
        while index > 0 do
            tokenType, token = self.iterator()
            if  not tokenType then
                break
            end
            index = index - 1
        end
        return tokenType, token
    end,
    Peek = function(self, index)
        index = index or 1
        local tokenType, token
        while index > self.typeQueue:Size() do
            if self.endOfStream then
                break
            else
                tokenType, token = self.iterator()
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
    end,
})
end)
