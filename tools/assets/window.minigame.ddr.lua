--- @section MinigameDDRWindow

---@class MinigameDDRState
---@field special_mode string
---@field bar_fill number
---@field max_fill number
---@field fill_per_hit number
---@field miss_penalty number
---@field bar_x number
---@field bar_y number
---@field bar_width number
---@field bar_height number
---@field arrow_size number
---@field arrow_spawn_timer number
---@field arrow_spawn_interval number
---@field arrow_fall_speed number
---@field arrows table
---@field target_y number
---@field target_arrows table
---@field hit_threshold number
---@field button_pressed_timers table
---@field button_press_duration number
---@field input_cooldowns table
---@field input_cooldown_duration number
---@field frame_counter number
---@field current_song table?
---@field pattern_index number
---@field use_pattern boolean
---@field generated_length number
---@field return_window string?
---@field win_timer number
---@field on_win fun(ctx: MinigameDDRState)|nil
---@field total_misses number
---@field total_hits number
---@field special_mode_condition boolean
---@field special_mode_counter number
---@field debug_song_key string|nil
---@field debug_status string|nil

--- Background drawing for DDR minigame.
--- @within MinigameDDRWindow
function MinigameDDRWindow.draw_background()
  local img_values = {1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1}
  local img_runs = {809,40,5,26,178,42,4,7,30,10,127,103,11,1,116,124,116,124,115,18,60,47,115,10,105,10,115,9,108,9,114,9,108,9,114,9,108,9,114,9,33,31,44,9,114,9,34,28,46,9,114,9,108,9,114,9,108,9,114,9,108,9,114,9,108,9,114,9,109,8,114,9,109,8,114,9,109,9,112,10,105,1,3,9,111,11,104,2,3,9,111,11,101,5,3,9,111,11,101,5,3,9,111,9,103,5,3,9,111,9,99,1,2,6,3,9,111,9,99,1,2,8,1,9,111,9,3,1,88,1,3,1,2,11,1,9,111,9,3,1,88,1,3,14,1,9,111,9,3,1,88,1,3,1,2,11,1,9,111,9,3,1,88,1,5,12,1,9,111,9,3,1,88,1,3,14,1,9,111,9,3,1,88,3,1,1,2,11,1,9,111,9,3,1,88,3,1,14,1,9,111,9,3,1,88,3,2,13,2,8,111,9,3,1,88,3,3,12,3,8,110,9,3,1,88,3,3,12,3,9,109,9,3,1,88,3,1,14,3,9,109,9,3,1,90,1,1,7,3,4,3,9,109,9,3,1,90,1,1,5,6,3,3,9,108,10,3,1,44,1,4,1,40,1,1,5,7,2,3,9,108,10,3,1,44,1,4,1,38,3,1,5,7,3,2,9,108,10,3,1,48,1,39,3,1,5,7,2,3,9,108,10,3,1,88,3,1,5,6,3,3,9,108,10,3,1,32,5,4,4,3,2,38,3,1,15,2,9,108,10,3,1,41,5,2,2,2,4,32,3,1,15,2,9,108,10,2,2,41,9,2,5,3,1,3,1,23,3,1,9,1,5,2,9,108,10,2,2,41,12,35,3,1,7,4,4,2,9,108,10,2,2,32,26,30,3,1,5,7,3,2,9,108,10,2,2,36,21,31,9,7,3,2,9,108,10,2,2,35,23,30,10,6,3,2,9,108,10,2,2,35,23,30,11,4,4,2,9,108,10,2,2,34,24,30,19,2,9,108,10,2,2,33,25,30,19,2,9,108,10,2,2,32,28,28,19,2,9,108,10,2,2,32,30,26,19,2,9,108,10,2,2,33,31,24,19,2,9,108,10,2,4,37,17,32,19,2,10,107,10,2,5,85,19,2,10,107,10,2,109,2,10,107,12,1,107,3,10,107,133,107,133,107,133,107,133,107,133,107,133,107,133,118,111,129,6,63,3,28,10,121,13,98,6,142,7,76,6,129,10,13,5,77,15,109,4,31,4,78,4,24,7,75,173,66,176,64,177,62,178,62,178,62,56,31,2,7,2,2,3,2,1,2,1,61,8,62,56,114,8,62,56,114,8,62,56,114,8,62,56,114,8,62,9,8,39,114,9,61,8,9,39,114,9,61,8,9,39,114,9,61,8,9,39,114,9,61,8,9,39,114,9,61,8,9,39,114,9,61,8,9,39,115,8,61,8,8,40,115,8,61,56,115,8,61,13,2,1,1,1,1,16,1,1,2,17,115,8,61,13,2,1,1,1,2,1,1,10,2,1,1,1,2,1,2,7,1,6,115,8,60,14,2,1,1,1,5,9,2,1,1,1,2,1,2,6,2,6,115,8,59,15,2,1,1,1,5,9,2,1,1,1,2,1,2,6,2,6,115,8,59,15,2,1,1,1,6,8,2,1,1,1,2,1,2,14,115,8,59,6,1,11,1,1,7,10,1,1,2,1,2,14,115,8,59,6,1,11,1,1,7,10,1,1,2,1,2,1,1,12,115,9,58,6,1,1,2,10,9,8,1,1,2,1,2,1,1,12,115,9,58,6,1,1,2,8,1,1,9,8,1,1,2,1,2,1,1,11,116,9,58,6,1,1,2,1,2,7,9,8,1,1,2,1,2,1,1,11,116,9,58,6,1,1,2,1,2,7,9,10,2,1,2,1,1,11,116,9,58,57,116,9,58,58,115,9,102,13,116,9,58,48,2,10,1,3,22,84,5,7,58,158,7,5,6,6,75,3,7,2,7,1,7,2,6,1,6,2,6,2,4,4,6,2,6,1,6,2,6,3,6,1,6,5,7,8,7,9,11,1,9,2,50,1,22,1,14,5,3,5,3,4,3,6,3,5,2,16,2,5,3,14,2,6,2,6,5,5,11,4,30,1,50,1,37,6,3,5,3,5,2,6,3,5,3,6,1,7,2,6,2,15,2,6,2,5,6,5,12,1,15,1,106,93,2,8,10,5,2,6,2,5,4,4,100,7,3,13,2,65,3,8,3,5,2,5,4,4,3,5,4,4,100,94,2,5,3,5,4,4,6,5,2,5,105,86,2,13,3,5,4,4,6,5,2,1,1,3,102,4,2,24,2,62,1,1,2,7,3,5,4,5,4,5,2,8,4,2,92,5,2,24,2,61,5,5,7,2,5,6,3,4,3,7,102,88,6,7,12,8,6,1,3,7,103,87,6,7,11,9,6,1,3,7,110,1,9,9,5,1,2,1,3,47,162,1,10,6,27,34,162,1,10,6,27,34,97,3,57,14,2,7,26,66,9,33,5,2,17,223,17,223,18,222,47,193,53,1,3,163,19,1,85,109,14,29,36,151,784}
  -- pal = {220,220,220,90,90,90}
  -- pal = dcdcdc5a5a5a
  RLE.draw(img_values, img_runs)
end

--- Gets initial DDR minigame configuration.
--- @within MinigameDDRWindow
---@return MinigameDDRState
function MinigameDDRWindow.init_context()
  local arrow_size = 12
  local arrow_spacing = 30
  local total_width = (4 * arrow_size) + (3 * arrow_spacing)
  local start_x = (Config.screen.width - total_width) / 2
  return {
    special_mode = "normal", -- "normal", "only_special", "only_left", "only_nothing"
    bar_fill = 0,
    max_fill = 100,
    fill_per_hit = 10,
    miss_penalty = 5,
    bar_x = 20,
    bar_y = 10,
    bar_width = 200,
    bar_height = 12,
    arrow_size = arrow_size,
    arrow_spawn_timer = 0,
    arrow_spawn_interval = 45,
    arrow_fall_speed = 1.5,
    arrows = {},
    target_y = 120,
    target_arrows = {
      { dir = "left", x = start_x },
      { dir = "down", x = start_x + arrow_size + arrow_spacing },
      { dir = "up", x = start_x + (arrow_size + arrow_spacing) * 2 },
      { dir = "right", x = start_x + (arrow_size + arrow_spacing) * 3 }
    },
    hit_threshold = 8,
    button_pressed_timers = {},
    button_press_duration = 8,
    input_cooldowns = { left = 0, down = 0, up = 0, right = 0 },
    input_cooldown_duration = 10,
    frame_counter = 0,
    current_song = nil,
    pattern_index = 1,
    use_pattern = false,
    generated_length = 30,
    return_window = nil,
    win_timer = 0,
    on_win = nil,
    total_misses = 0,
    total_hits = 0,
    special_mode_condition = true,
    special_mode_counter = 0
  }
end

--- Builds song data (and optional generated pattern) for the minigame.
--- @within MinigameDDRWindow
function MinigameDDRWindow.prepareSong(song, generated_length, special_mode)
  local current_song = Util.deepcopy(song)

  if current_song.generated then
    local pattern = musicator_generate_pattern(generated_length, current_song.bpm, current_song.spd * 4)
    current_song.pattern = pattern
    current_song.end_frame = pattern[#pattern].frame

    if special_mode == "only_special" then
      for i, _ in ipairs(current_song.pattern) do
        current_song.pattern[i].special = (i % 5 == 0)
      end
    end
  end

  return current_song
end

--- Handles hit feedback and special-mode scoring for one arrow.
--- @within MinigameDDRWindow
---@param game_context MinigameDDRState
function MinigameDDRWindow.on_arrow_hit_special(arrow, game_context)
  local special_mode = game_context.special_mode

  if special_mode == "normal" then
    Audio.sfx_arrowhit(arrow.note)
  elseif special_mode == "only_special" then
    if arrow.special then
      Audio.sfx_arrowhit(arrow.note)
      game_context.special_mode_counter = game_context.special_mode_counter + 1
    else
      game_context.total_misses = game_context.total_misses + 1
      if game_context.special_mode_condition then Audio.sfx_bloop() end
      game_context.special_mode_condition = false
    end
  elseif special_mode == "only_left" then
    if arrow.dir == "left" then
      Audio.sfx_arrowhit(arrow.note)
      game_context.special_mode_counter = game_context.special_mode_counter + 1
      if game_context.max_fill <= game_context.bar_fill + game_context.fill_per_hit then
        game_context.bar_fill = game_context.bar_fill - game_context.fill_per_hit
      end
    else
      game_context.total_misses = game_context.total_misses + 1
      if game_context.special_mode_condition then Audio.sfx_bloop() end
      game_context.special_mode_condition = false
    end
  elseif special_mode == "only_nothing" then
    game_context.total_misses = game_context.total_misses + 1
    if game_context.special_mode_condition then Audio.sfx_bloop() end
    game_context.special_mode_condition = false
  end
end

--- Ends the minigame: win timer, sfx, and special-mode pass/fail bookkeeping.
--- @within MinigameDDRWindow
function MinigameDDRWindow.on_end(game_context)
  Audio.sfx_select()

  game_context.win_timer = Config.timing.minigame_win_duration

  local num_special = 0
  for _, v in ipairs(game_context.current_song.pattern) do
    if game_context.special_mode == "only_left" then
      num_special = num_special + ((v.dir == "left" and 1) or 0)
    else
      num_special = num_special + ((v.special and 1) or 0)
    end
  end

  local sm = game_context.special_mode
  local was_ok = true
  if sm == "normal" or sm == "only_special" or sm == "only_left" then
    was_ok = game_context.special_mode_counter == num_special
  end

  game_context.special_mode_condition = game_context.special_mode_condition and was_ok
  if game_context.special_mode_condition and sm ~= "normal" then
    game_context.bar_fill = game_context.max_fill
  end
end

--- Initializes DDR minigame state.
--- @within MinigameDDRWindow
--- @param params table Optional parameters for configuration.<br/>
function MinigameDDRWindow.init(params)
  local defaults = MinigameDDRWindow.init_context()
  if params then
    for k, v in pairs(params) do
      defaults[k] = v
    end
  end
  Context.minigame_ddr = defaults
end

--- Starts the DDR minigame.
--- @within MinigameDDRWindow
--- @param return_window string The window ID to return to after the minigame.</br>
--- @param[opt] song_key string The key of the song to play.</br>
--- @param[opt] params table Optional parameters for minigame configuration.</br>
function MinigameDDRWindow.start(return_window, song_key, params)
  MinigameDDRWindow.init(params)

  Audio.music_play_activity_work()

  Context.minigame_ddr.return_window = return_window or "game"
  Context.minigame_ddr.debug_song_key = song_key
  if song_key and Songs and Songs[song_key] then
    Context.minigame_ddr.use_pattern = true
    Context.minigame_ddr.pattern_index = 1
    Context.minigame_ddr.debug_status = "Pattern loaded: " .. song_key

    Context.minigame_ddr.current_song = MinigameDDRWindow.prepareSong(
      Songs[song_key],
      Context.minigame_ddr.generated_length,
      Context.minigame_ddr.special_mode
    )

  else
    Context.minigame_ddr.use_pattern = false
    if song_key then
      Context.minigame_ddr.debug_status = "Song not found: " .. tostring(song_key)
    else
      Context.minigame_ddr.debug_status = "Random mode"
    end
  end

  if not Context.test_mode then
    Context.minigame_ddr.debug_status = ""
  end

  Window.set_current("minigame_ddr")
end

--- Spawns a random arrow.
--- @within MinigameDDRWindow
local function spawn_arrow()
  trace("random arrow")

  ---@type MinigameDDRState
  local mg = Context.minigame_ddr
  local y0 = mg.bar_y + mg.bar_height + 10
  local target = mg.target_arrows[math.random(1, 4)]
  table.insert(mg.arrows, {
    dir = target.dir,
    x = target.x,
    y = y0
  })
end

--- Spawns an arrow in a specific direction.
--- @within MinigameDDRWindow
--- @param direction string The direction of the arrow ("left", "down", "up", "right").
local function spawn_arrow_dir(direction, note, special)
  ---@type MinigameDDRState
  local mg = Context.minigame_ddr
  local y0 = mg.bar_y + mg.bar_height + 10
  for _, target in ipairs(mg.target_arrows) do
    if target.dir == direction then
      table.insert(mg.arrows, {
        dir = direction,
        x = target.x,
        y = y0,
        note = note,
        special = special
      })
      break
    end
  end
end

--- Checks if an arrow is hit.
--- @within MinigameDDRWindow
--- @param arrow table The arrow data.
--- @return boolean True if the arrow is hit, false otherwise.
local function check_hit(arrow)
  ---@type MinigameDDRState
  local mg = Context.minigame_ddr
  local distance = math.abs(arrow.y - mg.target_y)
  return distance <= mg.hit_threshold
end

--- Checks if an arrow is missed.
--- @within MinigameDDRWindow
--- @param arrow table The arrow data.
--- @return boolean True if the arrow is missed, false otherwise.
local function check_miss(arrow)
  ---@type MinigameDDRState
  local mg = Context.minigame_ddr
  return arrow.y > mg.target_y + mg.hit_threshold
end

--- Rotates a point (px, py) around (cx, cy) by a number of 90-degree CW steps.
--- @within MinigameDDRWindow
local function rotate(px, py, cx, cy, steps)
  local dx, dy = px - cx, py - cy
  for _ = 1, steps % 4 do
    dx, dy = dy, -dx
  end
  return cx + dx, cy + dy
end

local arrow_rotations = { down = 0, right = 1, up = 2, left = 3 }

--- Draws an arrow by rotating the "down" arrow shape.
--- @within MinigameDDRWindow
--- @param x number The x-coordinate.
--- @param y number The y-coordinate.
--- @param direction string The direction of the arrow.
--- @param color number The color of the arrow.
local function draw_arrow(x, y, direction, color)
  local size = 14
  local half = size / 2
  local pivot_x, pivot_y = x + half, y + half
  local steps = arrow_rotations[direction] or 0

  local head_left_x, head_left_y = rotate(x, y + half, pivot_x, pivot_y, steps)
  local head_tip_x, head_tip_y = rotate(x + half, y + size, pivot_x, pivot_y, steps)
  local head_right_x, head_right_y = rotate(x + size, y + half, pivot_x, pivot_y, steps)

  tri(head_left_x, head_left_y,
      head_tip_x, head_tip_y,
      head_right_x, head_right_y, color)

  local stem_top_x, stem_top_y = rotate(x + half - 3, y, pivot_x, pivot_y, steps)
  local stem_bot_x, stem_bot_y = rotate(x + half + 3, y + half, pivot_x, pivot_y, steps)
  local stem_x = math.min(stem_top_x, stem_bot_x)
  local stem_y = math.min(stem_top_y, stem_bot_y)
  local stem_w = math.abs(stem_bot_x - stem_top_x)
  local stem_h = math.abs(stem_bot_y - stem_top_y)
  rectb(stem_x, stem_y, stem_w, stem_h, color)
end


--- Updates DDR minigame logic.
--- @within MinigameDDRWindow
function MinigameDDRWindow.update()
  local mg = Context.minigame_ddr

  if mg.win_timer > 0 then
    mg.win_timer = mg.win_timer - 1
    if mg.win_timer == 0 then
      Audio.music_stop()
      Meter.apply_ddr_reward(mg.total_misses)
      if not Context.game_in_progress then return end
      if mg.on_win then
        mg.on_win(mg)
      else
        Meter.show()
        Window.set_current(mg.return_window)
      end
    end
    return
  end

  if mg.bar_fill >= mg.max_fill then
    MinigameDDRWindow.on_end(mg)
    return
  end

  mg.frame_counter = mg.frame_counter + 1

  if mg.use_pattern and mg.current_song and mg.current_song.end_frame then
    if mg.frame_counter > mg.current_song.end_frame and #mg.arrows == 0 then
      MinigameDDRWindow.on_end(mg)
      return
    end
  end

  if mg.use_pattern and mg.current_song and mg.current_song.pattern then
    local pattern = mg.current_song.pattern
    while mg.pattern_index <= #pattern do
      local spawn_entry = pattern[mg.pattern_index]

      if mg.frame_counter >= spawn_entry.frame then
        spawn_arrow_dir(spawn_entry.dir, spawn_entry.note, spawn_entry.special)
        mg.pattern_index = mg.pattern_index + 1
      else
        break
      end
    end
  else
    mg.arrow_spawn_timer = mg.arrow_spawn_timer + 1
    if mg.arrow_spawn_timer >= mg.arrow_spawn_interval then
      spawn_arrow()
      mg.arrow_spawn_timer = 0
    end
  end

  -- move arrow downwards
  local arrows_to_remove = {}
  for i, arrow in ipairs(mg.arrows) do
    arrow.y = arrow.y + mg.arrow_fall_speed
    if check_miss(arrow) then
      table.insert(arrows_to_remove, i)
      mg.bar_fill = math.max(0, mg.bar_fill - mg.miss_penalty)
      mg.total_misses = mg.total_misses + 1
    end
  end

  -- iterate backwards to avoid index shift issues
  for i = #arrows_to_remove, 1, -1 do
    table.remove(mg.arrows, arrows_to_remove[i])
  end

  for dir, _ in pairs(mg.input_cooldowns) do
    if mg.input_cooldowns[dir] > 0 then
      mg.input_cooldowns[dir] = mg.input_cooldowns[dir] - 1
    end
  end

  for dir, _ in pairs(mg.button_pressed_timers) do
    if mg.button_pressed_timers[dir] > 0 then
      mg.button_pressed_timers[dir] = mg.button_pressed_timers[dir] - 1
    end
  end

  local input_map = {
    left = Input.left(),
    down = Input.down(),
    up = Input.up(),
    right = Input.right()
  }

  for _, target in ipairs(mg.target_arrows) do
    if Mouse.zone({ x = target.x, y = mg.target_y, w = mg.arrow_size, h = mg.arrow_size }) then
      input_map[target.dir] = true
    end
  end

  for dir, pressed in pairs(input_map) do
    if pressed and mg.input_cooldowns[dir] == 0 then
      mg.input_cooldowns[dir] = mg.input_cooldown_duration
      mg.button_pressed_timers[dir] = mg.button_press_duration
      local hit = false
      for i, arrow in ipairs(mg.arrows) do
        if arrow.dir == dir and check_hit(arrow) then
          MinigameDDRWindow.on_arrow_hit_special(arrow, mg)

          mg.bar_fill = math.min(mg.max_fill, mg.bar_fill + mg.fill_per_hit)
          table.remove(mg.arrows, i)
          hit = true
          break
        end
      end
      if not hit then
        mg.bar_fill = math.max(0, mg.bar_fill - 2)
        mg.total_misses = mg.total_misses + 1
      end
    end
  end
end

--- Draws DDR minigame.
--- @within MinigameDDRWindow
function MinigameDDRWindow.draw()
  ---@type MinigameDDRState|nil
  local mg = Context.minigame_ddr
  if not mg then
    cls(0)
    print("DDR ERROR: Context not initialized", 10, 10, 12)
    print("Press Z to return", 10, 20, 12)
    if Input.select() then
      Window.set_current("game")
    end
    return
  end
  -- if mg.return_window == "game" then
  --   GameWindow.draw()
  -- end
  rect(0, 0, Config.screen.width, Config.screen.height, Config.colors.black)
  rect(mg.bar_x - 2, mg.bar_y - 2, mg.bar_width + 4, mg.bar_height + 4, Config.colors.light_grey)
  rectb(mg.bar_x - 2, mg.bar_y - 2, mg.bar_width + 4, mg.bar_height + 4, Config.colors.dark_grey)
  local fill_width = (mg.bar_fill / mg.max_fill) * mg.bar_width
  MinigameDDRWindow.draw_background()
  if fill_width > 0 then
    local bar_color = Config.colors.light_blue
    if mg.bar_fill > 66 then
      bar_color = Config.colors.item
    elseif mg.bar_fill > 33 then
      bar_color = Config.colors.blue
    end
    rect(mg.bar_x, mg.bar_y, fill_width, mg.bar_height, bar_color)
  end
  if mg.target_arrows then
    for _, target in ipairs(mg.target_arrows) do
      local is_pressed = mg.button_pressed_timers[target.dir] and mg.button_pressed_timers[target.dir] > 0
      local color = is_pressed and Config.colors.light_blue or Config.colors.light_grey
      draw_arrow(target.x, mg.target_y, target.dir, color)
    end
  end
  if mg.arrows then
    for _, arrow in ipairs(mg.arrows) do
      local arrow_color = arrow.special and Config.colors.white or Config.colors.blue
      draw_arrow(arrow.x, arrow.y, arrow.dir, arrow_color)
    end
  end
  Print.text_center_contour("Hit the arrows!", Config.screen.width / 2, mg.bar_y + mg.bar_height + 10, Config.colors.light_blue)
  local debug_y = 60
  if mg.debug_status then
    Print.text_center(mg.debug_status, Config.screen.width / 2, debug_y, Config.colors.item)
    debug_y = debug_y + 10
  end
  if mg.use_pattern and Context.test_mode then
    Print.text_center(
      "PATTERN MODE - Frame:" .. mg.frame_counter,
      Config.screen.width / 2,
      debug_y,
      Config.colors.light_blue
    )
    if mg.current_song and mg.current_song.pattern then
      Print.text_center(
        "Pattern Len:" .. #mg.current_song.pattern .. " Index:" .. mg.pattern_index,
        Config.screen.width / 2,
        debug_y + 10,
        Config.colors.light_blue
      )
    end
  elseif Context.test_mode then
    Print.text_center("RANDOM MODE", Config.screen.width / 2, debug_y, Config.colors.blue)
  end

  if mg.win_timer > 0 then
    if mg.special_mode_condition then
      Minigame.draw_win_overlay("SUCCESS...?")
    elseif mg.total_hits < 10 then
      Minigame.draw_win_overlay("MEH...")
    else
      Minigame.draw_win_overlay()
    end
  end
end
