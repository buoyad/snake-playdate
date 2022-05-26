sounds = {}

function sounds:init()
    sounds.synth = playdate.sound.synth.new(playdate.sound.kWaveTriangle)
end

function sounds:death()
    local synth = sounds.synth:copy()
    synth:playNote("A2", 0.5, 1)
end
