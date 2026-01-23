local Mana = {}

--- Calculates and creates the Mana fragment data based on Void percentage.
--- @param data table The configuration data.
---   - current: number (optional, defaults to max)
---   - max: number (optional, overrides void-based calculation if provided)
---   - regenRate: number (optional, base regen rate)
--- @param voidValue number The creature's Void percentage (0-100).
--- @return table The Mana fragment data.
function Mana.new(data, voidValue)
    data = data or {}
    voidValue = voidValue or 0

    -- 1% void = 2 mana capacity
    local maxMana = data.max or (voidValue * 2)

    -- Starting at 50% void, 1 mana per second for each % above
    local baseRegen = data.regenRate or 0
    local voidRegen = 0
    if voidValue > 50 then
        voidRegen = (voidValue - 50) / 2
    end

    local totalRegen = baseRegen + voidRegen

    return {
        current = data.current or maxMana,
        max = maxMana,
        regenRate = totalRegen,
    }
end

function Mana.duplicate(mana)
    if not mana then return nil end
    return {
        current = mana.current,
        max = mana.max,
        regenRate = mana.regenRate,
    }
end

return Mana
