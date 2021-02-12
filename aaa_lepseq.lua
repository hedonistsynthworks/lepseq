local BeatClock = require 'beatclock'

local clk = BeatClock.new()

g = grid.connect()


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

notes_track = {
  steps = {1,1,1,1,1,1,1,1},
  position = 1,
  length = 8
}

gate_track = {
  steps = {false, false, false, false, false, false, false, false},
  position = 1,
  length = 8
}

g.key = function(x,y,z)
  -- set step
  -- -- x: 1,8 y: 1
  -- set pitch
  -- -- x: 1,8 y: 3,7
  -- pattern length
  -- -- x: 1,8 y:2
  -- -- x: 1,8 y:8
  -- clock multiplier for each sequencer
  -- -- x: 9,12 y:2
  -- -- x: 9,12 y8
  -- reverse 
  -- -- x: 16 y: 2
  -- -- x: 16 y: 8
  -- triplet?
end

function step()
  -- print("notes "..tostring(notes_track.position).." "..tostring(notes_track.steps[notes_track.position]))
  -- print("gates "..tostring(gate_track.position).." "..tostring(gate_track.steps[gate_track.position]))
  notes_track.position = (notes_track.position % notes_track.length) + 1
  gate_track.position = (gate_track.position % gate_track.length) + 1

  draw_grid()
end


function draw_grid()
  reset_grid_before_draw()
  -- gate
  g:led(gate_track.position, 1, 15)
  -- note
  for note = 1, notes_track.steps[notes_track.position] do
    print("drawing"..tostring(notes_track.position).." "..tostring(16-note))
    g:led(notes_track.position, 8 - note,15)
  end
  g:refresh()
end

function init()
  clk:add_clock_params()
  clk.on_step = step

  clk:start()
end