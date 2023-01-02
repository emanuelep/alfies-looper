-- alfie's looper
--
-- 3 stereo voices
-- asynchronous looping
--
-- @emanuelep

include "supercut/lib/supercut"

function init()
  for i=1,3,1 do
    supercut.init(i,"stereo")       -- initialise supervoices
    supercut.pre_level(i,1)         -- initialise pre level to 1 so that full overdub possible
    supercut.rate_slew_time(i, 0)   -- just 0
    supercut.phase_quant(i, 0.01)   -- 10 ms
    --supercut.level_slew_time(i, 0)  -- just 0
    supercut.fade_time(i, 0.01)     -- 10 ms
    supercut.rec(i,1)
    supercut.play(i,1)
    supercut.rec_level(i,0)
  end
  recflag= {0,0,0}                  -- initialise recflag array
  overdubbing= {0,0,0}              -- initialise overdub flag array
  stoppedoverdubbing= {1,1,1}       -- initialise stop overdub flag array
  pitchrate= {1,1,1}                -- initialise pitch rate array
  level= {1,1,1}                    -- initialise level array
  supercut.poll_start_phase()       -- initialise polling phase
  ch_selector=1;                    -- initialise channel selector to first channel
  counter=0;                        -- initialise "hold to clear" counter (in seconds)
  recording={0,0,0}                 -- initialise recording flag (for screen gui)
  playing={0,0,0}                   -- initialise playing flag (for screen gui)
  fadetime=0.01                     -- fade time for each action
  redraw()                          -- draw screen
end

-- draw screen
function redraw()
  screen.clear()                          -- clear screen
  screen.level(15)                        -- screen level
  screen.font_face(15)                    -- select font
  
  -- voice selection
  screen.font_size(10)                    
  screen.move(0,35)
  screen.text("VOICE: " .. ch_selector ) 
  screen.move(0,64)
  
  -- buttons bottom row
  screen.font_size(7)                   
  screen.text("DUB     VOICE#")
  screen.move(68,64)
  screen.text("PITCH")
  screen.move(73,58)
  --screen.text(math.floor(pitchrate[ch_selector]*100)/100)
  screen.text(pitchrate[ch_selector])
  screen.move(103,64)
  screen.text("LEVEL")
  screen.move(108,58)
  screen.text(math.floor(level[ch_selector]*100)/100)
  
  -- hold to clear
  screen.move(65,10)
  screen.text("HOLD TO CLEAR")
  
  -- dub / play / void message
  screen.move(60,35)
  screen.font_size(10)
  if recording[ch_selector] == 1 then
    screen.text("// DUBBING")
  elseif playing[ch_selector] == 1 then
    screen.text("// PLAYING")
  else
    screen.text("// VOID")
  end
  
  screen.update()     -- screen update
end


function key(n,z)
  
    -- key 2, dub/play/overdub
    if n == 2 then
      if z == 1 then
        if overdubbing[ch_selector] == 0 then         -- previous state is void, record a loop
          if recflag[ch_selector] == 0 then           -- previous state is void, record a loop
            --print("recording")
            recflag[ch_selector]=1                    -- set recflag to 1 to know button been pressed once
            recording[ch_selector]=1                  -- set rec screen flag to one to show on screen that we dubbing
            playing[ch_selector]=0                    -- set play screen flag to zero since we are not playing but dubbing
            t1=util.time()                            -- save record start time
            supercut.loop_start(ch_selector,0)        -- looping starting position to zero
            supercut.loop_position(ch_selector,0)     -- set loop position to zero
            supercut.recpre_slew_time(ch_selector, fadetime)  -- rec fade in time
            supercut.rec_level(ch_selector, 1)                -- turn rec level up
            --supercut.fade_time(ch_selector, fadetime) -- fade rec in // kinda not working
            --supercut.rec(ch_selector,1)               -- start recording // should not be done
            supercut.loop_length(ch_selector,116)     -- to max time temporarily
            redraw()                                  -- draw changes on screen
          elseif recflag[ch_selector] == 1 then       -- we have been recording (button has been pressed once) so now go into stop-recording mode
            -- print("stopped recording")
            recflag[ch_selector]=0                    -- set recflag to 0 to know button been pressed twice and goes back to initial state 
            recording[ch_selector]=0                  -- set rec screen flag to zero to show on screen we not dubbing
            playing[ch_selector]=1                    -- set play screen flag to one to show on screen we are playing loop and not dubbing
            t2=util.time()                            -- save recording stop time
            thetime=t2-t1;                            -- calculate loop length in s
            supercut.loop_length(ch_selector,thetime) -- set loop length to calculated length
            supercut.recpre_slew_time(ch_selector, fadetime)  -- rec fade out time
            supercut.rec_level(ch_selector, 0)                -- turn rec level down
            --supercut.fade_time(ch_selector, fadetime) -- fade rec out, not working since fadeout is post roll https://llllllll.co/t/norns-2-0-softcut/20550/113
            --supercut.play(ch_selector,1)              -- play loop
            --supercut.rec(ch_selector,0)               -- stop recording
            overdubbing[ch_selector]=1;               -- from now on we can overdub if desired
            redraw()                                  -- draw changes on screen
          end
        elseif overdubbing[ch_selector] == 1 and stoppedoverdubbing[ch_selector] == 1 then -- overdubbing
          -- print("overdubbing")
          recording[ch_selector]=1                    -- set rec screen flag to one to show on screen that we dubbing 
          playing[ch_selector]=0                      -- set play screen flag to zero since we are not playing but dubbing
          -- important line for overdubbing, somehow supercut structure needs for loop_position to be told that we want to do stuff in loop_position(channelID) taken from its current position, works only this way
          supercut.loop_position(ch_selector,supercut.loop_position(ch_selector))
          supercut.recpre_slew_time(ch_selector, fadetime)  -- rec fade in time
          supercut.rec_level(ch_selector, 1)                -- turn rec level back up
          --supercut.rec(ch_selector,1)                 -- start recording // should not be done
          --supercut.fade_time(ch_selector, 0.01)
          stoppedoverdubbing[ch_selector]=0;          -- set this to zero since we ARE overdubbing (to be later set to 1 when we stop overdubbing, also initiated to 1 by default since it is needed to enter overdubbing mode)
          redraw()                                    -- draw changes on screen
        elseif overdubbing[ch_selector] == 1 and stoppedoverdubbing[ch_selector] == 0 then -- stop overdubbing
          --print("stopped overdubbing")
          recording[ch_selector]=0                    -- set rec screen flag to zero to show on screen we not dubbing
          playing[ch_selector]=1                      -- set play screen flag to one to show on screen we are playing loop and not dubbing
          supercut.recpre_slew_time(ch_selector, fadetime)  -- rec fadeout time
          supercut.rec_level(ch_selector, 0)                -- turn rec level back down
          --supercut.rec(ch_selector,0)                 -- stop recording // should not be done
          --supercut.fade_time(ch_selector, fadetime)
          stoppedoverdubbing[ch_selector]=1;          -- set stop overdubbing flag to true to know we are done with overdubbing (1 also means we are NOT overdubbing, reason why it is initiated to 1 by default)
          redraw()                                    -- draw changes on screen
        end
      end
    end
    
    -- key 3, change voice selector
    if n == 3 then
      if z == 1 then
        if ch_selector < 3 then                       -- increase voice index unless we are at voice 3
          ch_selector=ch_selector+1;
        elseif ch_selector == 3 then                  -- if we are at voice 3 start back to voice 1
          ch_selector=1;
        end
        redraw()                                      -- draw changes on screen
        --print("currently selected channel:" .. ch_selector)
      end
    end
    
    -- key 1, clear loop voices
    if n == 1 then
      if z == 1 then
        countdown=metro.init(countfunc,1,2)           -- initiate metro function with step 1 second, counting up to 2 seconds
        countdown:start()                             -- start metro function
      end
    end
    
end

-- timed function to clear buffer
function countfunc()
  counter=counter+1                                   -- increase global counter
  --print("counting" .. counter)
  if counter == 2 then                                -- if we reached 2 seconds clear loop
    --supercut.fade_time(ch_selector, fadetime)
    --supercut.rec(ch_selector,0)                       -- stop recording // should not be done
    --supercut.play(ch_selector,0)                      -- stop playing // should not be done
    -- important line, this is the only way to clear a voice and not the whole buffer, this one is for stereo clearing, for mono clearing use softcut.buffer_clear_region_channel, note this is softcut. not supercut. second to last parameter should be a fade (to avoid clicking?) but it does not seem to make a difference on clicking when clearing a loop that is still playing sounds
    softcut.buffer_clear_region(supercut.region_start(ch_selector),supercut.region_length(ch_selector),0,0)
    supercut.fade_time(ch_selector, fadetime)
    recflag[ch_selector]=0                            -- set recflag to 0 to know button can be pressed for the first time again after this
    overdubbing[ch_selector]=0                        -- set overdub flag to 0 to know we are not overdubbing
    stoppedoverdubbing[ch_selector]=1                 -- set stopoverdub flag to 1 to know we are not overdubbing
    --pitchrate[ch_selector]=1    glitches
    --level[ch_selector]=1        glitches
    recording[ch_selector]=0                          -- set rec screen flag to zero to show on screen we not dubbing
    playing[ch_selector]=0                            -- set play screen flag to zero to show on screen we not playing
    --print("buffer cleared")
    metro.free_all()                                  -- free all metro counter so that they can be reallocated (there are only 30)
    counter=0;                                        -- reset clearcounter 
    redraw()                                          -- draw changes on screen
  end
end

-- encoder 2, pitch
function enc(n,d)
  if n == 2 then
      pitchrate[ch_selector] = util.clamp(pitchrate[ch_selector] + d/100,0.01,10) -- produce steps between 0.01 and 10 from encoder increases/decreases
      --print("pitch rate:" .. pitchrate[ch_selector])
      --print("d/100:" .. d/100)
      supercut.rate(ch_selector,pitchrate[ch_selector])                           -- set pitch rate of current supervoice
      redraw()                                                                    -- draw changes on screen
  end
  if n == 3 then
      level[ch_selector] = util.clamp(level[ch_selector] + d/100,0,1)             -- produce steps between 0 and 1 from encoder increases/decreases
      supercut.level(ch_selector,level[ch_selector])                              -- set level of current supervoice
      redraw()                                                                    -- draw changes on screen
  end
end
