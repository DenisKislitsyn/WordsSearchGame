-- Module for base constants and parameters
local TYPE_TABLE = 'table'

-- переменные размеров экрана (инициализируются при старте)
SCREEN_WIDTH = 0
SCREEN_HEIGHT = 0
WINDOW_WIDTH = 0
WINDOW_HEIGHT = 0

CAMERA_OFFSET_X = 0
CAMERA_OFFSET_Y = 0

function table.deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == TYPE_TABLE then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
		end
	else
		copy = orig
	end
	return copy
end

function table.shuffle(t)
	local size = #t
	for i = size, 1, -1 do
		local rand = math.random(size)
		t[i], t[rand] = t[rand], t[i]
	end
	return t
end

function updateProgressBar(node, width, height, progress_count, overall_count, duration, delay, min_width)
	-- вообще ничего нет - скрыть наш бегунок
	if progress_count == 0 then
		gui.set_enabled(node, false)
		gui.set_size(node, vmath.vector3(min_width or height, height, 0))
	else
		gui.set_enabled(node, true)
	end

	local current_weight = math.ceil((width) * progress_count / overall_count)

	-- ужиматься не может
	if min_width then
		if current_weight < min_width then
			current_weight = min_width
		end
	else
		if current_weight < height then
			current_weight = height
		end
	end

	-- быть больше не может
	if current_weight > width then
		current_weight = width
	end

	duration = duration == nil and 0 or duration
	delay = delay == nil and 0 or delay

	gui.animate(node, "size", vmath.vector3(current_weight, height, 0), gui.EASING_INOUTSINE, duration, delay)
end

function set_nodes_to_center(l_node, is_l_node_text, r_node, is_r_node_text, delta)
	if delta == nil then delta = 0 end

	local l_size_x = (is_l_node_text and gui.get_text_metrics_from_node(l_node).width or gui.get_size(l_node).x) * gui.get_scale(l_node).x
	local r_size_x = (is_r_node_text and gui.get_text_metrics_from_node(r_node).width or gui.get_size(r_node).x) * gui.get_scale(r_node).x
	local l_pivot = gui.get_pivot(l_node)
	local r_pivot = gui.get_pivot(r_node)
	local l_pos = gui.get_position(l_node)
	local r_pos = gui.get_position(r_node)

	local text_length = l_size_x + r_size_x + delta
	local l_dx = (text_length / 2) - l_size_x
	local r_dx = (text_length / 2) - r_size_x

	l_pos.x = -l_dx
	if l_pivot == gui.PIVOT_W or l_pivot == gui.PIVOT_NW or l_pivot == gui.PIVOT_SW then
		l_pos.x = l_pos.x - l_size_x
	elseif l_pivot == gui.PIVOT_CENTER then
		l_pos.x = l_pos.x - l_size_x / 2
	end
	r_pos.x = r_dx
	if r_pivot == gui.PIVOT_E or r_pivot == gui.PIVOT_NE or r_pivot == gui.PIVOT_SE then
		r_pos.x = r_pos.x + r_size_x
	elseif r_pivot == gui.PIVOT_CENTER then
		r_pos.x = r_pos.x + r_size_x / 2
	end

	gui.set_position(l_node, l_pos)
	gui.set_position(r_node, r_pos)
end

