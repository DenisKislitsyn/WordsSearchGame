local M = {}

local levels_data = require 'configs.levels'
local save_data = require 'common.save_data'
local russian_nouns = json.decode(sys.load_resource('/configs/russian_nouns.json'))

local congrats = {'Отлично!', 'Молодец!', 'Так держать!', 'Супер!', 'Великолепно!'}
local congrats_index = math.random(1, #congrats)

-- рандомный цвет для каждого нового слова, чтобы не сливалось
local random_color = function() return vmath.vector3(math.random(100)/255,math.random(100)/255,math.random(100)/255) end
local PICKED_COLOR = random_color()
local NORMAL_COLOR = vmath.vector3(128/255)

-- создание нового поля
function M.new(self, level, draw_fn)
    -- базовые параметры
    M.level = level or save_data.load('level')
    M.chain = {}
    M.word = ''
    M.bonus_words_count = save_data.load('bonus_words_count')
    M.data = levels_data[M.level]

    -- загружаем стейт, если есть
    local save_state = save_data.load('state')
    M.state = {
        found_words_chains = save_state.found_words_chains,
        bonus_words = save_state.bonus_words
    }

    -- рисуем борду
    if draw_fn then
        draw_fn(self)
    end

    -- если уже есть открытие слова - заполняем их
    if #M.state.found_words_chains > 0 then
        for _, chain in ipairs(M.state.found_words_chains) do
            for _, letter_index in ipairs(chain) do
                self.board[letter_index].answer = true
                gui.set_color(self.board[letter_index].node, PICKED_COLOR)
            end

            PICKED_COLOR = random_color()
        end
    end

end

-- победа
function M.win()
    local next_level = M.level >= #levels_data and 1 or (M.level + 1)
    save_data.save('level', next_level)

    M.state = {
        found_words_chains = {},
        bonus_words = {}
    }
    save_data.save('state', M.state)
end

-- сбрасываем бонусные слова
function M.reset_bonus_words()
    M.bonus_words_count = 0
    save_data.save('bonus_words_count', M.bonus_words_count)
    M.state.bonus_words = {}
end

-- проверка на нахождение бонусного слова
local function check_bonus_word(word)
    local added_yet
    for _, bonus_word in ipairs(M.state.bonus_words) do
        if word == bonus_word then
            added_yet = true
            break
        end
    end
    if added_yet then return end

    for _, bonus_word in ipairs(russian_nouns) do
        if word == bonus_word then
            table.insert(M.state.bonus_words, word)
            save_data.save('state', M.state)

            M.bonus_words_count = M.bonus_words_count + 1
            save_data.save('bonus_words_count', M.bonus_words_count)

            msg.post('game:/go#screen', 'show_hint', {text = 'Вы нашли бонусное слово!'})
            break
        end
    end
end

-- проверка слова
local function check_word(self, word, chain)
    local is_answer = false
    for _, w_data in ipairs(M.data.words) do
        if word == w_data.w then
            is_answer = true

            -- проверяем та ли цепочка
            local is_right_chain = true

            for index, letter_index in ipairs(M.chain) do
                if w_data.chain[index] ~= letter_index then
                    is_right_chain = false
                    break
                end
            end

            if is_right_chain then
                for _, letter_index in ipairs(chain) do
                    self.board[letter_index].answer = true
                end

                PICKED_COLOR = random_color()

                table.insert(M.state.found_words_chains, chain)
                save_data.save('state', M.state)

                msg.post('game:/go#screen', 'show_hint', {text = congrats[congrats_index]})
                congrats_index = congrats_index == #congrats and 1 or (congrats_index + 1)

                if #M.state.found_words_chains >= #M.data.words then
                    msg.post('game:/go#screen', 'win')
                end
            else
                msg.post('game:/go#screen', 'show_hint', {text = 'Попробуйте собрать это слово по другому'})
            end

            break
        end
    end

    if not is_answer then
        check_bonus_word(word)
    end
end


-- INPUT
local current_index
local function on_input_released(self)
    check_word(self, M.word, M.chain)
    M.chain = {}
    M.word = ''

    for _, data in ipairs(self.board) do
        if not data.answer then
            gui.set_color(data.node, NORMAL_COLOR)
        end
    end
end

local function set_word(self)
    M.word = ''
    for _, added_index in ipairs(M.chain) do
        M.word = M.word .. self.board[added_index].letter
    end
end

local function input_processor(self, action_id, action)
    for _, data in ipairs(self.board) do
        if gui.pick_node(data.node, action.x, action.y) and (current_index == nil or current_index ~= data.index) then
            -- перешли на новую ячейку - меняем
            current_index = data.index
            -- если уже открыта - ничего не делаем
            if data.answer == true then
                return
            end

            -- если вернулись на предыдущую ячейку - отменяем выбор
            if next(M.chain) ~= nil and #M.chain > 1 and M.chain[#M.chain-1] == current_index then
                gui.set_color(self.board[M.chain[#M.chain]].node, NORMAL_COLOR)
                table.remove(M.chain, #M.chain)
                set_word(self)

            -- если цепочка пуста или новый индекс - проверяем можно ли добавить
            elseif next(M.chain) == nil or M.chain[#M.chain] ~= current_index then
                -- проверяем добавили ли уже
                local added_yet = false
                for _, added_index in ipairs(M.chain) do
                    if current_index == added_index then
                        added_yet = true
                        break
                    end
                end

                -- проверяем сосед ли
                local last_index = M.chain[#M.chain]
                local is_neighbour = false
                if current_index % M.data.width ~= 0 and (current_index+1 == last_index) or
                        current_index % M.data.width ~= 1 and (current_index-1 == last_index) or
                        current_index <= #self.board - M.data.width and (current_index+M.data.width == last_index) or
                        current_index > M.data.width and (current_index-M.data.width == last_index) then
                    is_neighbour = true
                end

                -- если еще не добавлено и сосед - добавляем в цепочку
                if not added_yet and (is_neighbour or next(M.chain) == nil) then
                    table.insert(M.chain, current_index)
                    gui.set_color(data.node, PICKED_COLOR)
                    set_word(self)
                end
            end
            break
        end
    end
end

function M.on_input(self, action_id, action)
    if action_id == hash('touch') then
        if action.released then
            on_input_released(self)
            return
        elseif action.pressed then
            current_index = nil
        end

        input_processor(self, action_id, action)
    end
end

-- FINAL
function M.final(self)
    save_data.save('state', M.state)
end

return M