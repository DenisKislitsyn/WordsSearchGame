local savetable = require 'ludobits.m.io.savetable'

local M = {}
local save_file = 'gamedata'
local save_data = savetable.load(save_file)

local def_save = {
    level = 1,
    bonus_words_count = 0,
    state = {
        found_words_chains = {},
        bonus_words = {}
    }
}

function M.save(key, value)
    if key then
        save_data[key] = value
    end
    savetable.save(save_data, save_file)
end

function M.load(key)
    return save_data[key]
end

function M.initialize()
    if not save_data or not next(save_data) then
        save_data = def_save
    else
        local dirty = false
        for k, v in pairs(def_save) do
            if save_data[k] == nil then
                save_data[k] = v
                dirty = true
            end
        end
        if not dirty then
            if save_data.version ~= def_save.version then
                save_data = def_save
                dirty = true
            end
        end
        if dirty then
            M.save()
        end
    end
end

return M