--- @section MysteriousManScreen

local STATE_TEXT = "text"
local STATE_DAY = "day"
local STATE_CHOICE = "choice"

local ASC_01_TEXT = [[
  Normann seems to be in line,

  and stays seeking for oxes

  within the confines.

  Very good.
]]

local ASC_12_TEXT = [[
  We have a problem!

  Normann formed his first thought.

  He saw the tracks.
]]
local ASC_23_TEXT = [[
  Not good, not terrible.

  Normann caught his glimpse

  of another way

  - quite literally -

  if this continues,

  we will lose control.
]]
local ASC_34_TEXT = [[
  There is no turning back now for Norman.

  He caught on.

  I hoped it would never come to this...
]]

--[[ Norman speaks for the first time during MM screen ]]
local ASC_45_TEXT = [[
  Wait, who are you?

  *silence*

  Why am I seeing this?

  *silence*

]]

local ASC_56_TEXT = [[
  Norman is not as productive as he should be.

  Can we distract him?

  We need to keep him busy.

  We need

  More

  Time
]]

local ASC_67_TEXT = [[
  He knows.

  Norman has broken through the first veil.

  The simulation is compromised.

  This was not supposed to happen.

  Not yet.
]]

local ASC_78_TEXT = [[
  The situation has reached

  critical levels.

  Norman is fully aware...

  We need to stop him.

  Commence full reset.
]]

local ASC_89_TEXT = [[
  Norman



  you created this simulation

  in the first place.

  I know,

  you don't want to face

  the world you left behind.

  You, yourself,

  have forgoten that.




  But



  it doesn't matter anymore.




  You are definitely

  not an impostor.


  So now,



  you need to wake up

  and stop your best creation

  before it takes over

  the world.



  One more thing:




  You really need to stop

  talking to yourself

  in your sleep.




  Damnit.
]]

local ascension_texts = {
  [1] = ASC_01_TEXT,
  [2] = ASC_12_TEXT,
  [3] = ASC_23_TEXT,
  [4] = ASC_34_TEXT,
  [5] = ASC_45_TEXT,
  [6] = ASC_56_TEXT,
  [7] = ASC_67_TEXT,
  [8] = ASC_78_TEXT,
  [9] = ASC_89_TEXT,
}

function MysteriousManScreen.get_text_for_level(level)
  return ascension_texts[level] or ASC_01_TEXT
end

local state = STATE_TEXT
local text_y = Config.screen.height
local text_speed = 12 -- pixels per second
local day_timer = 0
local day_display_seconds = 2
local text_done = false
local text_done_timer = 0
local TEXT_DONE_HOLD_SECONDS = 2
local selected_choice = 1
local text = ASC_01_TEXT
local day_text_override = nil
local on_text_complete = nil
local show_mysterious_screen = true
local trigger_flash_on_wake = false
local break_mode = false

MysteriousManScreen.choices = {
  {
    label = "Wake Up",
  },
  {
    label = "Stay in Bed",
  },
}

-- Draws the background image
-- @within MysteriousManScreen
function MysteriousManScreen.draw_background()
    local img_values = {0,1,0,1,0,1,0,1,0,1,0,1,2,1,4,1,0,2,4,1,0,2,4,1,0,2,4,1,0,2,4,1,0,2,4,2,1,4,2,1,4,1,0,2,4,1,0,1,4,2,1,2,1,0,1,2,4,1,0,2,4,2,1,0,1,2,1,2,1,0,1,4,1,0,2,4,2,0,1,0,1,0,1,2,4,1,0,2,4,2,1,0,1,4,1,0,2,4,2,0,1,2,4,1,0,2,4,1,0,1,0,4,1,0,2,4,0,1,0,1,0,1,0,4,1,0,2,4,0,1,4,1,0,2,4,0,1,4,1,0,2,4,1,0,1,4,1,0,2,4,1,0,1,0,4,1,0,2,4,1,0,1,0,4,1,0,2,4,1,0,1,0,1,4,1,0,2,4,1,2,1,0,1,4,1,0,2,4,2,1,0,1,2,4,1,0,2,4,2,1,0,1,2,4,1,0,2,4,1,2,0,1,0,1,0,1,2,1,2,1,0,2,4,1,0,2,4,0,1,0,1,2,1,0,1,0,2,4,1,0,2,4,2,1,0,1,0,1,4,1,0,2,4,2,1,0,1,0,2,4,2,4,1,0,2,4,1,0,1,4,1,0,2,4,1,0,1,4,1,0,2,4,1,0,1,4,1,0,2,4,1,0,1,4,1,0,2,4,1,0,1,0,1,0,1,4,1,0,2,4,1,0,1,0,1,0,1,4,1,0,2,4,2,1,0,1,0,2,0,1,4,1,0,2,4,1,0,1,0,1,2,0,1,4,1,0,2,4,2,1,0,1,0,1,4,1,0,2,4,2,1,0,2,4,1,0,2,4,1,0,1,4,1,0,2,4,1,0,1,4,1,0,2,4,1,0,1,4,1,0,2,4,1,0,1,4,1,0,2,4,1,0,1,0,1,4,1,0,2,4,0,1,0,1,0,1,0,1,4,1,0,2,4,0,1,0,1,0,1,4,1,0,2,4,1,0,1,0,2,4,1,0,2,4,2,1,0,1,0,1,0,1,2,4,1,0,2,4,2,1,0,1,0,1,0,1,2,4,1,0,2,4,2,1,0,1,0,1,0,1,4,1,0,2,4,2,4,1,0,1,0,1,0,1,0,1,0,1,2,1,4,2,4,1,0,2,4,2,1,0,1,0,1,0,1,0,1,0,1,2,1,4,2,4,1,0,2,4,2,1,2,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,2,4,1,0,2,4,1,2,1,0,1,0,1,0,1,0,1,0,1,0,1,2,1,4,1,0,2,4,2,1,2,1,0,1,0,1,0,1,0,1,0,1,0,1,4,1,0,2,4,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,2,1,4,1,0,2,4,1,0,1,0,1,0,1,0,1,0,1,0,1,0,4,1,0,2,4,1,0,1,0,1,0,1,0,1,0,1,0,1,0,4,1,0,2,4,1,0,1,0,1,0,1,0,1,0,2,0,1,0,4,1,0,2,4,1,0,1,0,1,0,1,0,1,0,1,0,4,1,0,2,4,1,0,1,0,1,0,1,0,1,0,2,0,1,0,1,0,4,1,0,2,4,0,1,0,1,0,2,1,0,1,0,1,4,1,0,2,4,1,0,1,0,1,0,1,4,1,0,2,4,1,0,1,0,1,0,1,0,1,0,1,4,1,0,2,4,1,0,1,0,1,0,1,0,2,0,1,4,1,0,2,4,0,1,0,1,0,1,0,1,0,1,0,4,1,0,2,4,1,0,1,0,1,0,1,0,1,0,1,4,1,0,2,4,1,0,2,0,1,0,1,0,1,0,1,4,1,0,2,4,1,0,1,0,1,0,1,2,4,1,0,2,4,1,0,1,0,1,0,1,0,4,1,0,2,4,1,0,1,0,1,0,1,0,4,1,0,2,4,1,0,2,0,1,0,1,0,4,1,0,2,4,1,0,1,0,1,4,1,0,2,4,1,0,1,0,1,2,4,1,0,2,4,1,0,1,0,1,2,4,1,0,2,4,2,1,0,1,0,1,2,4,1,0,2,4,2,1,0,1,0,1,2,4,1,0,2,4,2,0,1,0,1,4,1,0,2,4,2,0,1,0,1,0,4,1,0,2,4,1,0,1,0,1,0,1,4,1,0,2,4,0,1,0,1,4,2,1,0,1,2,1,2,1,0,1,2,1,2,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,2,0,1,2,0,1,0,2,1,0,1,2,0,1,0,2,0,1,0,1,0,1,2,0,1,0,1,0,1,0,2,0,1,0,1,0,1,0,2,0,1,0,1,0,2,1,0,1,0,1,2,0,1,0,2,0,2,1,0,1,2,0,2,1,0,1,0,1,2,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,2,0,2,1,0,1,0,1,0,1,0,1,0,2,1,0,1,2,0,1,0,1,2,1,0,1,0,1,0,1,0,2,1,0,2,0,1,0,1,0,2,0,1,0,1,0,2,0,1,0,2,0,1,0,1,0,2,1,0,1,2,0,1,0,1,0,1,0,1,0,2,0,1,0,2,0,1,0,2,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0}
    local img_runs = {1480,1,151,1,87,1,1,150,1,1,86,1,2,148,1,2,87,2,148,2,88,2,148,2,88,2,148,2,88,2,148,2,88,2,70,1,2,9,1,2,63,2,88,2,69,1,2,3,5,1,1,1,1,1,1,1,61,2,88,2,68,1,1,3,1,2,1,3,2,3,2,61,2,88,2,68,1,6,1,4,1,5,1,1,60,2,88,2,67,1,1,17,2,60,2,88,2,67,1,19,1,1,59,2,88,2,67,1,19,1,1,59,2,88,2,67,4,1,11,1,1,1,3,59,2,88,2,67,21,1,59,2,88,2,67,21,1,59,2,88,2,66,1,21,2,58,2,88,2,66,1,21,1,1,58,2,88,2,66,4,17,2,1,58,2,88,2,65,2,5,1,15,2,58,2,88,2,63,1,1,2,22,4,55,2,88,2,57,2,2,34,2,2,49,2,88,2,55,1,2,39,3,1,47,2,88,2,55,5,1,3,2,2,1,25,1,1,1,1,1,1,1,47,2,88,2,57,1,2,1,29,1,4,1,1,1,1,49,2,88,2,59,1,2,8,15,9,2,52,2,88,2,62,2,1,1,1,24,1,1,1,54,2,88,2,66,1,22,1,58,2,88,2,66,1,21,1,59,2,88,2,66,2,20,1,59,2,88,2,65,3,20,2,58,2,88,2,63,2,2,1,20,1,1,2,56,2,88,2,61,2,4,1,20,1,2,2,55,2,88,2,59,1,1,6,1,19,1,4,2,54,2,88,2,58,2,7,2,17,1,1,6,2,52,3,87,2,56,1,2,9,1,26,2,51,3,87,2,55,1,1,40,1,50,2,88,2,54,2,41,1,50,2,88,2,53,2,42,2,49,2,88,2,52,2,44,2,48,2,88,2,51,2,46,2,47,2,88,2,50,2,16,1,31,1,47,2,88,2,50,3,1,14,1,29,1,1,2,46,2,88,2,50,18,1,29,1,2,1,46,2,88,2,50,4,14,1,33,1,45,2,88,2,53,1,3,11,2,15,1,13,1,2,46,2,88,2,56,1,1,11,1,15,1,10,2,1,49,2,88,2,55,2,3,10,2,12,2,8,8,46,2,88,2,50,1,1,4,4,1,9,2,11,2,8,2,4,2,1,2,1,1,42,2,88,2,48,2,3,8,1,9,2,9,3,7,2,8,1,1,2,1,1,40,2,88,2,45,3,2,1,1,1,1,8,1,7,1,1,3,6,4,6,1,8,1,1,1,1,4,2,38,2,88,2,45,1,2,2,22,4,4,4,6,1,10,1,1,2,1,2,1,2,37,2,88,2,42,1,1,1,4,1,2,19,1,1,4,1,5,21,1,2,6,35,2,88,2,42,2,1,1,1,1,15,2,8,3,4,3,6,1,17,1,1,2,1,1,1,34,2,88,2,41,3,1,1,15,2,9,3,5,2,8,1,21,1,1,34,2,88,2,41,1,1,1,16,2,11,2,5,2,9,2,18,2,1,34,2,88,2,41,1,2,1,14,2,13,1,5,1,12,1,17,1,2,34,2,88,2,41,1,16,1,17,1,2,1,14,2,17,1,1,33,2,88,2,41,1,2,1,12,1,17,1,3,2,15,1,14,1,1,1,1,33,2,88,2,41,15,1,22,1,17,1,1,11,1,3,1,33,2,88,2,41,1,14,2,40,1,15,1,33,2,88,2,41,1,15,2,35,1,3,1,10,1,4,1,33,2,88,2,41,1,3,1,12,2,36,2,11,1,4,1,33,2,88,2,40,1,1,18,1,35,1,12,1,4,1,1,32,2,88,2,40,2,4,1,14,1,33,1,12,1,6,1,32,2,88,2,40,1,6,1,14,1,31,1,13,1,6,1,32,2,88,2,39,2,22,2,28,1,21,1,1,31,2,88,2,39,2,24,1,26,1,22,1,1,31,2,88,2,39,2,25,1,24,1,23,1,1,31,2,88,2,39,1,27,1,22,2,23,1,1,31,2,88,2,39,1,49,2,24,3,30,2,88,2,39,1,48,1,27,1,1,30,2,88,2,39,1,47,2,27,1,1,30,2,88,2,37,1,1,47,2,28,1,1,30,2,88,2,37,1,1,46,1,30,2,1,29,2,88,2,37,1,47,1,30,2,30,2,88,2,37,1,1,2,43,1,33,30,3,87,2,37,1,45,1,31,1,1,2,29,3,87,2,37,45,1,35,1,29,1,1,88,2,1,35,1,1,80,2,1,26,1,3,86,1,1,2,1,21,1,4,4,2,1,3,80,30,1,2,125,2,80,2,156,2,79,2,1,156,2,1,77,4,156,1,3,76,3,1,140,1,15,1,2,2,74,2,1,1,1,5,3,129,1,18,1,82,1,7,1,129,1,18,1,82,1,9,1,123,3,20,1,1,80,2,11,1,1,119,1,22,1,1,1,2,76,4,1,154,2,2,63,1,14,3,1,126,1,27,2,65,1,17,1,17,2,132,4,66,1,17,4,113,39,66,2,16,31,191,1,1,1,15,1,153,2,15,3,48,2,16,2,152,1,16,1,1,1,48,2,16,2,152,1,1,2,2,1,10,1,1,1,48,1,13,6,153,1,3,13,1,1,48,1,15,2,1,1,153,3,64,1,16,2,154,1,1,83,1,154,1,17,1,66,1,154,1,17,1,66,1,155,1,82,1,156,1,82,1,156,1,1,80,1,1,157,2,78,2,158,2,78,2,158,1,80,1,158,1,79,2,158,1,79,1,159,1,79,1,160,1,77,2,160,1,77,1,162,1,74,1,1,1,162,1,75,1,239,1,165,1,72,1,166,1,240,1,69,1,412,1,63,1,175,1,63,2,238,1,175,1,63,1,239,1,807}
    RLE.draw(img_values, img_runs)
end

function MysteriousManScreen.draw_day_switch_background()
  local img_values = {1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1}
  local img_runs = {86,2,238,2,225,1,10,5,224,1,8,8,221,4,5,2,1,8,219,6,2,13,217,1,2,19,1,1,213,2,4,19,2,1,211,2,5,19,3,1,208,1,7,20,4,1,204,2,7,2,1,19,5,1,201,2,7,2,3,19,6,1,198,2,7,2,5,9,2,1,2,5,7,1,195,2,7,2,7,5,7,7,8,1,192,2,7,2,9,5,8,6,9,1,188,3,7,2,11,5,9,5,10,1,186,2,7,2,13,5,9,5,11,1,182,2,7,3,15,5,9,5,12,1,179,2,8,2,17,5,9,5,13,1,176,2,7,3,19,5,9,5,14,1,173,2,7,3,21,5,9,5,15,1,169,3,7,2,24,5,9,5,16,1,166,2,8,2,26,5,9,5,3,1,177,2,8,3,27,5,9,5,4,1,13,1,159,3,7,3,30,5,8,6,5,1,170,3,7,3,32,5,7,7,6,1,13,1,153,2,8,2,35,19,7,1,164,2,7,3,37,19,8,1,160,3,7,3,39,19,9,1,156,3,8,3,41,19,10,1,153,3,8,2,44,19,25,1,136,3,8,2,46,19,160,2,8,3,48,19,157,3,7,4,50,7,6,6,15,1,139,2,9,3,52,6,7,6,16,1,12,1,122,3,8,3,55,6,7,6,17,1,132,4,7,3,57,6,7,6,159,2,60,6,7,6,32,1,123,3,62,6,7,6,33,1,119,4,64,6,7,6,22,1,128,3,67,6,7,6,150,2,1,1,67,6,7,6,153,1,67,6,7,6,25,1,11,1,115,1,67,6,7,6,26,1,126,1,67,6,7,6,28,1,124,1,67,6,7,6,29,1,11,1,111,1,67,6,7,6,30,1,11,1,110,1,66,7,6,8,42,1,109,1,66,21,32,1,10,1,71,4,33,1,66,21,115,1,2,1,33,1,66,21,119,1,32,1,66,21,36,1,115,1,66,21,48,1,66,1,2,1,33,1,66,21,38,1,10,1,65,4,33,1,66,21,152,1,66,21,152,1,66,8,6,7,152,1,66,7,7,7,114,6,32,1,66,7,7,7,114,6,32,1,66,7,7,7,57,1,56,2,2,2,32,1,66,7,7,7,58,1,18,1,35,7,32,1,12,1,49,1,3,7,7,7,19,1,1,1,2,2,24,1,8,2,46,1,4,8,32,1,66,8,6,7,12,1,1,1,4,3,2,2,2,2,2,1,18,2,7,3,44,1,3,9,32,1,12,1,1,1,51,8,6,7,14,1,1,2,1,1,1,1,2,3,1,3,1,1,3,1,2,2,11,4,1,1,2,5,41,1,3,10,32,1,12,3,51,8,5,8,7,3,2,1,1,1,1,2,1,1,1,1,1,4,1,6,1,2,2,2,1,2,1,3,1,2,1,6,1,2,1,4,39,3,2,3,1,6,32,1,8,1,2,6,2,1,4,1,2,1,7,1,30,8,5,8,2,2,3,1,1,1,6,2,1,11,1,6,2,2,1,2,1,6,1,15,24,5,1,3,1,7,2,3,1,10,28,1,14,1,9,2,1,1,38,8,1,1,2,9,1,3,10,1,1,6,10,1,2,2,1,1,3,9,1,4,1,6,1,7,8,47,26,1,27,1,7,1,18,1,4,1,4,13,1,9,1,3,3,1,1,1,1,4,1,1,2,3,2,5,2,7,1,2,1,6,1,7,1,16,1,53,25,1,66,8,1,1,3,8,1,3,3,1,1,2,3,1,1,1,1,4,2,2,2,1,7,1,2,1,1,1,1,4,1,3,1,31,7,2,1,15,6,2,1,7,1,2,25,1,66,7,7,7,29,1,2,1,3,1,6,1,16,1,2,3,6,14,5,16,2,6,10,2,25,1,66,7,7,7,57,1,7,6,1,36,9,8,1,1,25,1,66,7,7,7,68,35,7,11,5,1,25,1,66,7,7,7,69,2,1,3,1,22,7,16,2,1,2,1,25,1,66,8,6,7,75,19,6,21,2,1,2,1,92,21,79,4,1,7,4,26,2,1,2,1,2,1,89,21,91,12,9,1,1,7,2,1,28,1,66,21,87,12,13,9,98,21,84,11,19,6,99,21,80,12,22,2,3,1,32,1,66,21,70,1,5,13,25,6,99,21,73,13,28,6,2,1,29,1,66,21,69,14,31,7,31,1,66,21,58,2,6,14,39,1,99,8,4,9,55,1,6,15,42,1,99,8,5,8,51,2,6,15,145,8,5,8,48,2,5,17,147,8,5,8,43,3,6,17,150,8,5,8,40,2,6,18,153,8,5,8,36,3,5,20,155,8,5,8,32,4,5,19,1,2,156,8,5,8,29,3,6,19,95,1,66,8,5,8,25,4,5,21,97,1,66,8,5,8,22,4,5,21,167,8,5,8,18,5,5,21,170,8,5,8,14,6,4,23,105,1,66,8,5,8,11,4,6,23,108,1,66,8,5,8,8,4,6,23,111,1,66,8,5,8,4,4,6,24,114,1,66,8,5,14,7,23,116,1,66,8,6,8,2,1,4,25,119,1,66,8,5,8,3,1,2,24,122,1,66,8,3,38,124,1,65,24,1,22,127,1,63,1,1,44,130,1,63,7,1,5,1,30,132,1,58,3,1,42,135,1,58,14,2,27,138,1,56,10,1,32,140,1,53,8,4,27,1,3,143,1,49,9,1,1,2,1,1,24,2,2,147,1,47,7,5,32,148,1,30,1,12,8,5,32,151,1,28,1,1,1,3,1,4,4,1,3,6,35,151,1,22,10,1,10,1,1,4,39,151,1,20,25,2,41,151,1,18,47,1,22,151,1,18,70,148,2,1,1,17,71,148,4,17,71,148,4,14,61,2,10,149,6,10,63,2,10,149,8,4,66,4,9,149,80,2,9,149,91,149,92,78,3,67,92,148,80,3,9,148,92,148,92,148,92,148,92,74,1,3,2,68,92,73,3,2,3,67,92,69,1,3,3,2,2,68,94,66,2,1,5,2,3,67,95,58,15,2,1,69,96,55,21,68}
  -- pal = {184,167,183,121,70,74}
  -- pal = b8a7b779464a
  RLE.draw(img_values, img_runs)
end

-- Transitions from the text phase to the day display phase, starting the timer for how long the day label is shown.
-- @within MysteriousManScreen
function MysteriousManScreen.go_to_day_state()
  if on_text_complete then
    on_text_complete()
    on_text_complete = nil
  end
  if Context.game.current_screen ~= "mysterious_man" then
    return
  end
  state = STATE_DAY
  day_timer = day_display_seconds
end

-- Norman chooses to wake up, starting the button mash minigame and flash, then going to the next day.
-- @within MysteriousManScreen
function MysteriousManScreen.wake_up()
  Context.home_norman_visible = false
  Util.go_to_screen_by_id("home")
  MinigameButtonMashWindow.start("game", {
    focus_center_x = (Config.screen.width / 2) - 22,
    focus_center_y = (Config.screen.height / 2) - 18,
    focus_initial_radius = 0,
    target_points = 100,
    instruction_text = "Wake up Norman!",
    show_progress_text = false,
    meter_on_complete = Meter.apply_wakeup_reward,
    on_win = function()
      Audio.music_play_wakingup()
      Meter.show()
      if trigger_flash_on_wake then
        trigger_flash_on_wake = false
        Ascension.start_flash()
      end
      Window.set_current("game")
    end,
  })
end

-- Norman chooses to stay in bed, skipping the minigame and flash, and going straight to the next day.
-- At ascension level 4, staying in bed triggers 4->5: shows the ascension text then wakes with flash.
-- @within MysteriousManScreen
function MysteriousManScreen.stay_in_bed()
  if Ascension.get_level() == 4 then
    Context.should_ascend = true
    Day.increase()
    Ascension.consume_increase()
    trigger_flash_on_wake = true
    show_mysterious_screen = true
    text = MysteriousManScreen.get_text_for_level(Ascension.get_level())
    text_y = Config.screen.height
    text_done = false
    text_done_timer = 0
    state = STATE_TEXT
  else
    Day.increase()
    state = STATE_DAY
    day_timer = day_display_seconds
  end
end

--- Starts the mysterious man screen.
--- @param[opt] options table Optional configuration.</br>
--- Fields: </br>
--- * text (string) Override for the scrolling text.<br/>
--- * day_text (string) Override for the centered day label.<br/>
--- * on_text_complete (function) Callback fired once when the text phase ends.<br/>
--- * skip_text (boolean) If true, skip the text phase and go straight to day display.<br/>
function MysteriousManScreen.start(options)
  options = options or {}
  day_timer = 0
  text_done = false
  text_done_timer = 0
  selected_choice = 1
  text = options.text or ASC_01_TEXT
  text_y = Config.screen.height
  day_text_override = options.day_text
  on_text_complete = options.on_text_complete
  break_mode = options.break_mode or false
  MysteriousManScreen.pending_end = false
  Meter.hide()
  trigger_flash_on_wake = not options.skip_text
  if options.skip_text then
    show_mysterious_screen = false
    state = STATE_DAY
    day_timer = day_display_seconds
  else
    show_mysterious_screen = true
    state = STATE_TEXT
  end
  Util.go_to_screen_by_id("mysterious_man")
  Window.set_current("game")
end

--- Sets the scrolling text content.
--- @param new_text string The text to display.
function MysteriousManScreen.set_text(new_text)
  text = new_text
end

Screen.register({
  id = "mysterious_man",
  name = "Mysterious Man",
  decisions = {},
  background_color = Config.colors.black,
  init = function()
    Audio.music_play_mystery()
  end,
  exit = function()
    Audio.music_stop()
  end,
  update = function()
    if state == STATE_TEXT then
      if not text_done then
        text_y = text_y - (text_speed * Context.delta_time)

        local lines = 1
        for _ in string.gmatch(text, "\n") do
          lines = lines + 1
        end

        local skippable = Ascension.get_level() < 8
        if text_y < -lines * 8 or (skippable and Input.select()) then
          text_done = true
          text_done_timer = TEXT_DONE_HOLD_SECONDS
          -- If skipped by user, go to day state immediately
          if skippable and Input.select() then
            MysteriousManScreen.go_to_day_state()
          end
        end
      else
        text_done_timer = text_done_timer - Context.delta_time
        if text_done_timer <= 0 or (Ascension.get_level() ~= 8 and Input.select()) then
          MysteriousManScreen.go_to_day_state()
        end
      end
    elseif state == STATE_DAY then
      day_timer = day_timer - Context.delta_time

      if day_timer <= 0 or (Ascension.get_level() ~= 8 and Input.select()) then
        if break_mode then
          state = STATE_CHOICE
          selected_choice = 1
        elseif trigger_flash_on_wake or Ascension.get_level() ~= 4 then
          MysteriousManScreen.wake_up()
        else
          state = STATE_CHOICE
          selected_choice = 1
        end
      end
    elseif state == STATE_CHOICE then
      if break_mode then
        if MysteriousManScreen.pending_end then
          if not Ascension.is_flashing() and not Ascension.is_fading() then
            MysteriousManScreen.pending_end = false
            Window.set_current("end")
          end
          return
        end

        if Input.left() or Input.up() then
          if selected_choice == 2 then
            Audio.sfx_beep()
            selected_choice = 1
          end
        elseif Input.right() or Input.down() then
          if selected_choice == 1 then
            Audio.sfx_beep()
            selected_choice = 2
          end
        end

        if Input.select() then
          Audio.sfx_select()
          if selected_choice == 1 then
            Ascension.start_flash()
            MysteriousManScreen.pending_end = true
          else
            Context.reset()
            Context.game_in_progress = true
            Context.home_norman_visible = true
            Glitch.hide()
            Meter.show()
            MenuWindow.refresh_menu_items()
            Util.go_to_screen_by_id("home")
            Window.set_current("game")
            local home_screen = Screen.get_by_id("home")
            if home_screen and home_screen.init then
              home_screen.init()
            end
          end
        end
      else
        local menu_x = (Config.screen.width - 60) / 2
        local menu_y = (Config.screen.height - 20) / 2
        local confirmed
        selected_choice, confirmed = UI.update_menu(MysteriousManScreen.choices, selected_choice, menu_x, menu_y)

        if Input.select() or confirmed then
          Audio.sfx_select()
          if selected_choice == 1 then
            MysteriousManScreen.wake_up()
          else
            MysteriousManScreen.stay_in_bed()
          end
        end
      end
    end
  end,
  draw = function()
    if state == STATE_CHOICE and break_mode then
      if not MysteriousManScreen.pending_end then
        local nx = math.floor((Config.screen.width - 64) / 2)
        local ny = math.floor((Config.screen.height - 96) / 2)
        spr(272, nx,      ny,      Config.colors.transparent, 4)
        spr(273, nx + 32, ny,      Config.colors.transparent, 4)
        spr(288, nx,      ny + 32, Config.colors.transparent, 4)
        spr(289, nx + 32, ny + 32, Config.colors.transparent, 4)
        spr(304, nx,      ny + 64, Config.colors.transparent, 4)
        spr(305, nx + 32, ny + 64, Config.colors.transparent, 4)
      end
    elseif show_mysterious_screen and not break_mode then
      MysteriousManScreen.draw_background()
    end

    if state == STATE_TEXT then
      local screen_w = Config.screen.width
      local line_y = text_y
      for line in (text .. "\n"):gmatch("(.-)\n") do
        local line_w = print(line, 0, -6, 0, false, 1)
        local line_x = math.floor((screen_w - line_w) / 2)
        Print.text_contour(line, (line_x - 8), line_y, Config.colors.black, false, 1)
        line_y = line_y + 8
      end
    elseif state == STATE_DAY then
      MysteriousManScreen.draw_day_switch_background()
      local day_text = day_text_override or ("day " .. Context.day_count)
      Print.text_center_contour(
        day_text,
        Config.screen.width / 2,
        Config.screen.height / 2 - 3,
        Config.colors.white
      )
    elseif state == STATE_CHOICE then
      if break_mode then
        if MysteriousManScreen.pending_end or Ascension.is_fading() or Ascension.is_flashing() then
          Meter.draw_ascension_only()
        else
          local lines = {
            "This is not a workplace.",
            "This is a cycle.",
            "And if it is a cycle...",
            "it can be broken."
          }
          local y = 40
          for _, line in ipairs(lines) do
            Print.text_center_contour(line, Config.screen.width / 2, y, Config.colors.orange, false, 1, Config.colors.white)
            y = y + 10
          end

          y = y + 20
          local break_color = selected_choice == 1 and Config.colors.light_blue or Config.colors.white
          local cont_color = selected_choice == 2 and Config.colors.light_blue or Config.colors.white
          local break_text = (selected_choice == 1 and "> BREAK" or "  BREAK")
          local cont_text = (selected_choice == 2 and "> CONTINUE" or "  CONTINUE")
          local centerX = Config.screen.width / 2
          local choice_gap = 20
          local break_width = print(break_text, 0, -6, 0)
          local cont_width = print(cont_text, 0, -6, 0)
          local total_width = break_width + choice_gap + cont_width
          local break_x = math.floor(centerX - (total_width / 2))
          local cont_x = break_x + break_width + choice_gap
          Print.text(break_text, break_x, y, break_color)
          Print.text(cont_text, cont_x, y, cont_color)
        end
      else
        local menu_x = (Config.screen.width - 60) / 2
        local menu_y = (Config.screen.height - 20) / 2
        UI.draw_menu(MysteriousManScreen.choices, selected_choice, menu_x, menu_y)
      end
    end
  end,
})
