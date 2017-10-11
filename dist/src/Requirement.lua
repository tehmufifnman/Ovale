local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./src/Requirement", { "./src/GUID", "./src/Ovale", "./src/State" }, function(__exports, __GUID, __Ovale, __State)
__exports.self_requirement = {}
__exports.RegisterRequirement = function(name, method, arg)
    __exports.self_requirement[name] = {
        [1] = method,
        [2] = arg
    }
end
__exports.UnregisterRequirement = function(name)
    __exports.self_requirement[name] = nil
end
__exports.CheckRequirements = function(spellId, atTime, tokens, index, targetGUID)
    targetGUID = targetGUID or __GUID.OvaleGUID:UnitGUID(__State.baseState.defaultTarget or "target")
    local name = tokens[index]
    index = index + 1
    if name then
        local verified = true
        local requirement = name
        while verified and name do
            local handler = __exports.self_requirement[name]
            if handler then
                local method = handler[1]
                local arg = handler[2]
                verified, requirement, index = arg[method](arg, spellId, atTime, name, tokens, index, targetGUID)
                name = tokens[index]
                index = index + 1
            else
                __Ovale.Ovale:OneTimeMessage("Warning: requirement '%s' has no registered handler; FAILING requirement.", name)
                verified = false
            end
        end
        return verified, requirement, index
    end
    return true, nil, nil
end
end)
