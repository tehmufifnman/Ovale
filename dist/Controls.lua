local __addonName, __addon = ...
__addon.require(__addonName, __addon, "./Controls", {}, function(__exports)
local _wipe = wipe
__exports.checkBoxes = {}
__exports.lists = {}
__exports.ResetControls = function()
    _wipe(__exports.checkBoxes)
    _wipe(__exports.lists)
end
end)
