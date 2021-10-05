Conditions = {
    CoilfangInstanceIds = {
        545, -- Coilfang: The Steamvault
        546, -- Coilfang: The Underbog
        547, -- Coilfang: The Slave Pens
        548, -- Coilfang: Serpentshrine Cavern
    },
    TempestKeepInstanceIds = {
        550, -- Tempest Keep
        552, -- Tempest Keep: The Arcatraz
        553, -- Tempest Keep: The Botanica
        554, -- Tempest Keep: The Mechanar
    },
}

local function has_value(haystack, needle)
    for _, value in ipairs(haystack) do
        if value == needle then
            return true
        end
    end
    return false
end

function Conditions:InCoilfangReservoirInstance()
    local _, _, _, _, _, _, _, instanceId = GetInstanceInfo()
    return has_value(self.CoilfangInstanceIds, instanceId)
end

function Conditions:InTempestKeepInstance()
    local _, _, _, _, _, _, _, instanceId = GetInstanceInfo()
    return has_value(self.TempestKeepInstanceIds, instanceId)
end
