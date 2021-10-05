local Spoon = LibStub("AceAddon-3.0"):NewAddon("Spoon", "AceConsole-3.0", "AceEvent-3.0")

local options = {
    type = "group",
    args = {
        show = {
            name = "Show",
            desc = "Shows a consumable group.",
            type = "input",
            set = function(_, arg)
                Spoon:Show(arg)
            end,
        },
        create = {
            name = "create",
            desc = "Creates a consumable group.",
            type = "input",
            set = function(_, arg)
                Spoon:Create(arg)
            end
        },
        delete = {
            name = "delete",
            desc = "Deletes a consumable group.",
            type = "input",
            set = function(_, arg)
                Spoon:Delete(arg)
            end
        },
        add = {
            name = "add",
            desc = "Adds a consumable to a group.",
            type = "input",
            set = function(_, arg)
                local group, item = strsplit(" ", arg, 2)
                Spoon:Add(group, item)
            end,
        },
        remove = {
            name = "remove",
            desc = "Removes a consumable from a group.",
            type = "input",
            set = function(_, arg)
                local group, item = strsplit(" ", arg, 2)
                Spoon:Remove(group, item)
            end,
        },
    },
}

local defaults = {
    profile = {
        groups = {}
    }
}

--local CONFIG = {
--    mp = {
--        32903, -- Cenarion Mana Salve
--        32902, -- Bottled Nethergon Energy
--        33093, -- Mana Potion Injector
--        22832, -- Super Mana Potion
--    },
--    hp = {
--        32904, -- Cenarion Healing Salve
--        32905, -- Bottled Nethergon Vapor
--        33092, -- Healing Potion Injector
--        22829, -- Super Healing Potion
--    },
--    food = {
--        34062, -- Conjured Manna Biscuit
--        22019, -- Conjured Croissant
--        29451, -- Clefthoof Ribs
--        29448, -- Mag'har Mild Cheese
--        29450, -- Telaari Grapes
--    },
--    water = {
--        34062, -- Conjured Manna Biscuit
--        22018, -- Conjured Glacier Water
--        27860, -- Purified Draenic Water
--    },
--}

local CONDITIONS = {
    [32903] = {  -- Cenarion Mana Salve
        function()
            return Conditions:InCoilfangReservoirInstance()
        end,
    },
    [32904] = {  -- Cenarion Healing Salve
        function()
            return Conditions:InCoilfangReservoirInstance()
        end,
    },
    [32902] = {  -- Bottled Nethergon Energy
        function()
            return Conditions:InTempestKeepInstance()
        end,
    },
    [32905] = {  -- Bottled Nethergon Vapor
        function()
            return Conditions:InTempestKeepInstance()
        end,
    },
}
local DEFAULT_CONDITIONS = {
    function()
        return true
    end,
}
setmetatable(CONDITIONS, {
    __index = function()
        return DEFAULT_CONDITIONS
    end,
})

function Spoon:OnInitialize()
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Spoon", options, { "spoon" })
    self.db = LibStub("AceDB-3.0"):New("SpoonDB", defaults, true)
end

function Spoon:OnEnable()
    self:RegisterEvent("BAG_UPDATE_DELAYED")     -- bag contents changed
    self:RegisterEvent("PLAYER_REGEN_ENABLED")   -- leaving combat
    self:RegisterEvent("ZONE_CHANGED")           -- zone changed
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")  -- sub-zone changed
end

function Spoon:BAG_UPDATE_DELAYED()
    self:Scan()
end

function Spoon:PLAYER_REGEN_ENABLED()
    self:Scan()
end

function Spoon:ZONE_CHANGED()
    self:Scan()
end

function Spoon:ZONE_CHANGED_NEW_AREA()
    self:Scan()
end

function Spoon:Scan()
    if InCombatLockdown() then
        return
    end
    for group, itemIds in pairs(self.db.profile.groups) do
        self:ScanOne(group, itemIds)
    end
end

function Spoon:ScanOne(group, itemIds)
    for _, itemId in ipairs(itemIds) do
        if self:Accept(itemId) then
            self:EditMacro(group, itemId)
            return
        end
    end
    self:EditMacro(group, 6948)  -- default to Hearthstone
end

function Spoon:Accept(itemId)
    count = GetItemCount(itemId, false, false)
    if count <= 0 then
        return false
    end
    for _, predicate in ipairs(CONDITIONS[itemId]) do
        if not predicate() then
            return false
        end
    end
    return true
end

function Spoon:EditMacro(group, itemId)
    local macroName = "Spoon_" .. group
    local body = "#showtooltip\n/use item:" .. itemId
    local macroId = GetMacroIndexByName(macroName)
    if macroId > 0 then
        EditMacro(macroId, nil, nil, body, 1)
    else
        CreateMacro(macroName, "INV_MISC_QUESTIONMARK", body, 1)
    end
end

local function has_key(haystack, needle)
    for key, _ in pairs(haystack) do
        if key == needle then
            return true
        end
    end
    return false
end

local function has_value(haystack, needle)
    for _, value in ipairs(haystack) do
        if value == needle then
            return true
        end
    end
    return false
end

local function remove_key(tbl, target)
    for i, key in pairs(tbl) do
        if key == target then
            table.remove(tbl, i)
            return
        end
    end
end

local function get_item_link(item)
    local _, itemLink = GetItemInfo(item)
    if itemLink ~= nil then
        return itemLink
    end
    local itemId = GetItemInfoInstant(item)
    return "item:" .. itemId
end

function Spoon:GroupCreate(group)
    self.db.profile.groups[group] = {}
end

function Spoon:GroupDelete(group)
    newGroups = {}
    for key, value in pairs(self.db.profile.groups) do
        if key ~= group then
            newGroups[key] = value
        end
    end
    self.db.profile.groups = newGroups
end

function Spoon:GroupExists(group)
    return has_key(self.db.profile.groups, group)
end

function Spoon:GroupHasItem(group, item)
    local itemId = GetItemInfoInstant(item)
    return has_value(self.db.profile.groups[group], itemId)
end

function Spoon:GroupAddItem(group, item)
    local itemId = GetItemInfoInstant(item)
    table.insert(self.db.profile.groups[group], itemId)
end

function Spoon:GroupRemoveItem(group, item)
    local itemId = GetItemInfoInstant(item)
    remove_key(self.db.profile.groups[group], itemId)
end

function Spoon:Show(group)
    if group == nil or group == "" then
        self:ShowAll()
        return
    end
    if not self:GroupExists(group) then
        self:Printf("Group named \"%s\" does not exist!", group)
        return
    end
    self:ShowOne(group, self.db.profile.groups[group])
end

function Spoon:ShowAll()
    for group, itemIds in pairs(self.db.profile.groups) do
        self:ShowOne(group, itemIds)
    end
end

function Spoon:ShowOne(group, itemIds)
    self:Printf("%s", group)
    for i, itemId in ipairs(itemIds) do
        local itemLink = get_item_link(itemId)
        self:Printf("  %d: %s", i, itemLink)
    end
end

function Spoon:Create(group)
    if self:GroupExists(group) then
        self:Printf("Group named \"%s\" already exists!", group)
        return
    end

    self:GroupCreate(group)
    self:Printf("Created new group \"%s\".", group)
    self:Scan()
end

function Spoon:Delete(group)
    if not self:GroupExists(group) then
        self:Printf("Group named \"%s\" does not exist!", group)
        return
    end

    self:GroupDelete(group)
    self:Printf("Deleted group \"%s\".", group)
    self:Scan()
end

function Spoon:Add(group, item)
    if not self:GroupExists(group) then
        self:Printf("Group named \"%s\" does not exist!", group)
        return
    end

    local itemLink = get_item_link(item)
    if Spoon:GroupHasItem(group, item) then
        self:Printf("Group \"%s\" already contains item %s!", group, itemLink)
        return
    end
    self:GroupAddItem(group, item)
    self:Printf("Added %s to group \"%s\".", itemLink, group)
    self:Scan()
end

function Spoon:Remove(group, item)
    if not self:GroupExists(group) then
        self:Printf("Group named \"%s\" does not exist!", group)
        return
    end

    local itemLink = get_item_link(item)
    if not Spoon:GroupHasItem(group, item) then
        self:Printf("Group \"%s\" does not contain item %s!", group, itemLink)
        return
    end
    self:GroupRemoveItem(group, item)
    self:Printf("Removed %s from group \"%s\".", itemLink, group)
    self:Scan()
end
