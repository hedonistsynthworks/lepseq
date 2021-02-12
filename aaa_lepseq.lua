local BeatClock = require 'beatclock'
local MusicUtil = require "musicutil"

local clk = BeatClock.new()

g = grid.connect()
engine.name = "Passersby"
Passersby = include "passersby/lib/passersby_engine"

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
  steps = {1,1,1,1,1,1,1,1},
  position = 1,
  length = 8
}

gate_track = {
  steps = {false, false, false, false, false, false, false, false},
  position = 1,
  length = 8
}

function on_set_gate_step(position)
  gate_track.steps[position] = true
end

function on_set_note_step(position, value)
  note_track.steps[position] = value
end

function on_set_gate_multiplier(multiplier)
end

function on_set_length(track, length)
  track.length = length
end

function light_steps()
  for i, step in ipairs(gate_track.steps) do
    if step then g:led(i, 1, 11) end
  end

  for i, step in ipairs(note_track.steps) do
    for note = 1,step do
      g:led(i, 8 - note,5)      
    end
  end

  g:led(gate_track.length, 2, 15)
  g:led(note_track.length, 8, 15)
end

g.key = function(x,y,z)
  -- set step
  -- -- x: 1,8 y: 1
  if (1 <= x) and (x <= 8) and (y == 1) and (z == 0) then on_set_gate_step(x, 8-y) end
  
  -- set pitch
  -- -- x: 1,8 y: 3,7
  if (1 <= x) and (x <= 8) and (3 <= y) and (y <= 7) and (z == 0) then on_set_note_step(x, 8-y) end
  
  -- pattern length
  -- -- x: 1,8 y:2
  -- -- x: 1,8 y:8
  if (1 <= x) and (x <= 8) and y == 2 then on_set_length(gate_track, x) end
  if (1 <= x) and (x <= 8) and y == 8 then on_set_length(note_track, x) end
  
  -- clock multiplier for each sequencer
  -- -- x: 9,12 y:2
  -- -- x: 9,12 y8  
  
  -- reverse 
  -- -- x: 16 y: 2
  -- -- x: 16 y: 8
  
  -- triplet?
end

function play()
  engine.noteOn(1, MusicUtil.note_num_to_freq(note_track.steps[note_track.position]))
end

function step()
  gates = ""
  notes = ""
  for key, value in ipairs(gate_track.steps) do
    gates = gates..", "..tostring(value)
  end
  for key, value in ipairs(note_track.steps) do
    gates = gates..", "..tostring(value)
  end
  print(gates)
  note_track.position = (note_track.position % note_track.length) + 1
  gate_track.position = (gate_track.position % gate_track.length) + 1
  if gate_track.steps[gate_track.position] then play() end
  draw_grid()
end

function light_current_step()
  -- gate
  g:led(gate_track.position, 1, 15)
  -- note
  for note = 1, note_track.steps[note_track.position] do
    g:led(note_track.position, 8 - note,15)
  end
end

function draw_grid()
  reset_grid_before_draw()
  -- light steps first then highlight after
  light_steps()
  light_current_step()
  g:refresh()
end

function init()
  clk:add_clock_params()
  clk.on_step = step

  clk:start()
end