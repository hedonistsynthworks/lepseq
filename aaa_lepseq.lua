local BeatClock = require 'beatclock'
local MusicUtil = require "musicutil"

local clk = BeatClock.new()

g = grid.connect()
engine.name = 'KarplusRings'

function reset_grid_before_draw()
  g:all(0)

  for i = 1,8 do
    g:led(i, 1, 2)
  end
  
  for i = 1,8 do
    for j = 3,7 do
      g:led(i, j, 2)
    end
  end  
end

reset_grid_before_draw()

g:refresh()

-- temporarily init to a scale
notes = {72, 75, 79, 82} -- c eb g bb

note_track = {
  steps = {1,0,0,0,0,0,0,0},
  position = 1,
  length = 8,
  counter = 1, -- is there something in beatclock i could use for divisors?
  divisor = 1
}

gate_track = {
  steps = {false, false, false, false, false, false, false, false},
  position = 1,
  length = 8,
  counter = 1, -- is there something in beatclock i could use for divisors?
  divisor = 1
}

function on_set_gate_step(position)
  -- print("on_set_gate_step "..tostring(position))
  gate_track.steps[position] = true
end

function on_set_note_step(position, value)
  -- print("on_set_note_step "..tostring(position).." "..tostring(value))
  note_track.steps[position] = value
  notes = ""
  for key, value in ipairs(note_track.steps) do
    notes = notes..", "..tostring(value)
  end
  -- print(notes)
end

function on_set_divisor(track, divisor)
  track.divisor = divisor
  --print("on_set_divisor "..tostring(divisor))
end

function on_set_length(track, length)
  track.length = length
end

function on_unset_note(position)
  note_track.steps[position] = 0
end

function light_steps()
  for i, step in ipairs(gate_track.steps) do
    if step then g:led(i, 1, 11) end
  end

  for i, step in ipairs(note_track.steps) do
    for note = 1,step do
      if step > 0 then g:led(i, 8 - note,5) end
    end
  end

  g:led(gate_track.length, 2, 15)
  g:led(note_track.length, 8, 15)
end

function light_last_valid_note()
  -- keep the note column lit through empty
end

g.key = function(x,y,z)
  -- set step
  -- -- x: 1,8 y: 1
  if (1 <= x) and (x <= 8) and (y == 1) and (z == 0) then on_set_gate_step(x, 8-y) end
  
  -- set pitch
  -- -- x: 1,8 y: 3,7
  if (1 <= x) and (x <= 8) and (3 <= y) and (y <= 7) and (z == 0) then on_set_note_step(x, 8-y) end

  -- unset pitch
  -- 
  
  -- pattern length
  -- -- x: 1,8 y:2
  -- -- x: 1,8 y:8
  if (1 <= x) and (x <= 8) and y == 2 then on_set_length(gate_track, x) end
  if (1 <= x) and (x <= 8) and y == 8 then on_set_length(note_track, x) end
  
  -- clock divisor for each sequencer
  -- -- x: 9,12 y:2
  -- -- x: 9,12 y8 
  if (9 <= x) and (x <= 12) and y == 2 then on_set_divisor(gate_track, x - 8) end
  if (9 <= x) and (x <= 12) and y == 8 then on_set_divisor(note_track, x - 8) end

  
  -- reverse 
  -- -- x: 16 y: 2
  -- -- x: 16 y: 8
  
  -- triplet?
end

function play()
  engine.hz(MusicUtil.note_num_to_freq(note_track.steps[note_track.position]))
end

function step()
  gates = ""
  notes = ""
  for key, value in ipairs(gate_track.steps) do
    gates = gates..", "..tostring(value)
  end
  for key, value in ipairs(note_track.steps) do
    notes = notes..", "..tostring(value)
  end
  -- print(notes)
  note_track.counter = note_track.counter + 1
  gate_track.counter = gate_track.counter + 1

  if note_track.counter % note_track.divisor == 0 then
    note_track.position = (note_track.position % note_track.length) + 1
  end
  if gate_track.counter % gate_track.divisor == 0 then
    gate_track.position = (gate_track.position % gate_track.length) + 1
  end
  if gate_track.steps[gate_track.position] then play() end
  draw_grid()
end

function light_current_step()
  -- gate
  g:led(gate_track.position, 1, 15)
  -- note
  if note_track.steps[note_track.position] > 0 then
    for note = 1, note_track.steps[note_track.position] do
      g:led(note_track.position, 8 - note,15)
    end
  else
    g:led(note_track.position, 7, 15)
  end
end

function light_utils()
  g:led(note_track.divisor + 8, 8, 15)
  g:led(gate_track.divisor + 8, 2, 15)
end

function draw_grid()
  reset_grid_before_draw()
  -- light steps first then highlight after
  light_steps()
  light_last_valid_note()
  light_current_step()
  light_utils()
  g:refresh()
end

function init()
  clk:add_clock_params()
  clk.on_step = step

  clk:start()
end