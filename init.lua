PaperWM = hs.loadSpoon("PaperWM")
PaperWM:bindHotkeys({
	-- switch to a new focused window in tiled grid
	focus_left = { { "alt", "cmd" }, "left" },
	focus_right = { { "alt", "cmd" }, "right" },

	-- resize window width with up/down arrows
	increase_width = { { "alt", "cmd" }, "up" }, -- wider
	decrease_width = { { "alt", "cmd" }, "down" }, -- narrower

	-- switch windows by cycling forward/backward
	-- (forward = down or right, backward = up or left)
	focus_prev = { { "alt", "cmd" }, "k" },
	focus_next = { { "alt", "cmd" }, "j" },

	-- move windows around in tiled grid
	swap_left = { { "alt", "cmd", "shift" }, "left" },
	swap_right = { { "alt", "cmd", "shift" }, "right" },
	swap_up = { { "alt", "cmd", "shift" }, "up" },
	swap_down = { { "alt", "cmd", "shift" }, "down" },

	-- position and resize focused window
	center_window = { { "alt", "cmd" }, "c" },
	full_width = { { "alt", "cmd" }, "f" },
	cycle_width = { { "alt", "cmd" }, "r" },
	reverse_cycle_width = { { "ctrl", "alt", "cmd" }, "r" },

	-- move focused window into / out of a column
	slurp_in = { { "alt", "cmd" }, "i" },
	barf_out = { { "alt", "cmd" }, "o" },

	-- move the focused window into / out of the tiling layer
	toggle_floating = { { "alt", "cmd", "shift" }, "escape" },
	-- raise all floating windows on top of tiled windows
	focus_floating = { { "alt", "cmd", "shift" }, "f" },

	-- switch to a new Mission Control space
	switch_space_l = { { "alt", "cmd" }, "," },
	switch_space_r = { { "alt", "cmd" }, "." },
	switch_space_1 = { { "alt", "cmd" }, "1" },
	switch_space_2 = { { "alt", "cmd" }, "2" },
	switch_space_3 = { { "alt", "cmd" }, "3" },
	switch_space_4 = { { "alt", "cmd" }, "4" },
	switch_space_5 = { { "alt", "cmd" }, "5" },
	switch_space_6 = { { "alt", "cmd" }, "6" },
	switch_space_7 = { { "alt", "cmd" }, "7" },
	switch_space_8 = { { "alt", "cmd" }, "8" },
	switch_space_9 = { { "alt", "cmd" }, "9" },

	-- move focused window to a new space and tile
	move_window_1 = { { "alt", "cmd", "shift" }, "1" },
	move_window_2 = { { "alt", "cmd", "shift" }, "2" },
	move_window_3 = { { "alt", "cmd", "shift" }, "3" },
	move_window_4 = { { "alt", "cmd", "shift" }, "4" },
	move_window_5 = { { "alt", "cmd", "shift" }, "5" },
	move_window_6 = { { "alt", "cmd", "shift" }, "6" },
	move_window_7 = { { "alt", "cmd", "shift" }, "7" },
	move_window_8 = { { "alt", "cmd", "shift" }, "8" },
	move_window_9 = { { "alt", "cmd", "shift" }, "9" },
})
PaperWM.swipe_fingers = 0 -- Disable built-in swipe (using Swipe.spoon instead)
PaperWM:start()

-- Use Swipe.spoon for smoother window switching with 2-finger horizontal swipe
local actions = PaperWM.actions.actions()
local current_id, threshold
Swipe = hs.loadSpoon("Swipe")
Swipe:start(3, function(direction, distance, id)
	if id == current_id then
		if distance > threshold then
			threshold = math.huge -- trigger once per swipe

			-- use "natural" scrolling direction
			if direction == "left" then
				actions.focus_right()
			elseif direction == "right" then
				actions.focus_left()
			end
		end
	else
		current_id = id
		threshold = 0.1 -- swipe distance > 10% of trackpad size
	end
end)

-- Focus border for active window
local focusBorder = nil
local fadeInTimer = nil
local inactivityTimer = nil
local borderWidth = 3
local borderAlpha = 0.5
local borderColor = { red = 0.4, green = 0.6, blue = 0.9 }
local fadeDuration = 0.1 -- 100ms
local fadeSteps = 10
local inactivityTimeout = 10 -- seconds before border fades out
local pendingDeletes = {} -- track borders being faded out

local function createBorder(win)
	local frame = win:frame()
	local border = hs.canvas.new(frame)
	border:appendElements({
		type = "rectangle",
		action = "stroke",
		strokeWidth = borderWidth,
		strokeColor = borderColor,
		roundedRectRadii = { xRadius = 8, yRadius = 8 },
	})
	border:level(hs.canvas.windowLevels.overlay)
	border:alpha(0)
	border:show()
	return border
end

local function fadeOutBorder(border)
	if not border then
		return
	end
	local step = 0
	local currentAlpha = border:alpha()
	local timer
	timer = hs.timer.doEvery(fadeDuration / fadeSteps, function()
		step = step + 1
		if step >= fadeSteps then
			timer:stop()
			pendingDeletes[border] = nil
			border:delete()
		else
			border:alpha(currentAlpha * (1 - step / fadeSteps))
		end
	end)
	pendingDeletes[border] = timer
end

local function fadeInBorder(border)
	if fadeInTimer then
		fadeInTimer:stop()
	end
	local step = 0
	fadeInTimer = hs.timer.doEvery(fadeDuration / fadeSteps, function()
		step = step + 1
		if step >= fadeSteps then
			fadeInTimer:stop()
			fadeInTimer = nil
			border:alpha(borderAlpha)
		else
			border:alpha((step / fadeSteps) * borderAlpha)
		end
	end)
end

local function hideBorderAfterInactivity()
	if focusBorder then
		fadeOutBorder(focusBorder)
		focusBorder = nil
	end
end

local function resetInactivityTimer()
	if inactivityTimer then
		inactivityTimer:stop()
	end
	inactivityTimer = hs.timer.doAfter(inactivityTimeout, hideBorderAfterInactivity)
end

local function onFocusChanged()
	local win = hs.window.focusedWindow()

	-- Fade out old border
	if focusBorder then
		fadeOutBorder(focusBorder)
		focusBorder = nil
	end

	-- Create and fade in new border
	if win then
		focusBorder = createBorder(win)
		fadeInBorder(focusBorder)
		resetInactivityTimer()
	end
end

local function onWindowMoved()
	local win = hs.window.focusedWindow()
	if not win or not focusBorder then
		return
	end
	focusBorder:frame(win:frame())
end

-- Update border on window focus change
focusWatcher = hs.window.filter.default
focusWatcher:subscribe(hs.window.filter.windowFocused, onFocusChanged)
focusWatcher:subscribe(hs.window.filter.windowMoved, onWindowMoved)
focusWatcher:subscribe(hs.window.filter.windowUnfocused, onFocusChanged)

-- Initial border
onFocusChanged()
