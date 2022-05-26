sounds = {}

function sounds:init()
    sounds.synth = playdate.sound.synth.new(playdate.sound.kWaveSquare)
end

function sounds:death()
    local synth = sounds.synth:copy()
    synth:playNote("B2", 0.5, 1)
end
