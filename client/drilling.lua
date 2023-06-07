local ShouldDrawScaleform, Scaleform, SetSpeed, SetDepth, SetTemp, CurrentDepth, PinsBroken, Result = nil, nil, 0.0, 0.0, 0.0, 0.1, 1, false
local TempF9, TempF10, TempF12 = 0.0, 0.0, 0.0

local Pins = { { depth = 0.325 }, { depth = 0.475 }, { depth = 0.625 }, { depth = 0.775 } }
local function CheckPins()
    local NeededDepth = Pins[PinsBroken]?.depth or 1.0
    if CurrentDepth >= NeededDepth then
        PinsBroken = PinsBroken + 1
        local SoundID = GetSoundId()
        PlaySoundFrontend(SoundID, 'Drill_Pin_Break', 'DLC_HEIST_FLEECA_SOUNDSET', true)
        ReleaseSoundId(SoundID)
        TempF10 = TempF10 + 2.0
        SetTemp = SetTemp + 0.7
    elseif PinsBroken == 5 then
        Result = true
        ShouldDrawScaleform = false
    end
end

-- Idk what R* is doing for temperature but it's weird. Have fun recreating it yourself or make a better solution.
-- Why does R* even rely on frametime for 'random' calculations? What if someone has a potato PC? :(
local function TemperatureControl()
    TempF10 = (TempF10 - ((0.4 + (0.2 * (1.0 - SetSpeed))) * Timestep()))
    if TempF10 < 0.0 then TempF10 = 0.0 end
    TempF9 = (SetSpeed * (1.0 + (TempF10 * 0.5)))
    if TempF9 > 1.0 then TempF9 = 1.0 end
    TempF12 = 0.25 - (0.25 - 0.15) * TempF9
    local Var0 = (1.0 - CurrentDepth) * 0.25
    TempF12 = TempF12 + Var0
    TempF12 = (TempF12 / (1.0 + (TempF10 * 6.0)))
    local TempF14 = CurrentDepth + TempF12
    if SetSpeed > TempF14 then
        SetTemp = (SetTemp + ((0.35 + (SetSpeed * 0.2)) * Timestep()))
    end
    if TempF9 > 0.0 then
        SetTemp = SetTemp - (0.08 * Timestep())
    else
        SetTemp = SetTemp - ((0.08 * 1.25) * Timestep())
    end
    if SetTemp < 0.0 then SetTemp = 0.0 end
    if SetTemp > 1.0 then ShouldDrawScaleform = false end
end

local function CheckControls()
    if IsControlJustReleased(0, 172) then
        if SetSpeed < 0.4 and (CurrentDepth - SetDepth) == 0 then return end
        SetDepth = SetDepth + 0.02
        if SetDepth >= 1.0 then SetDepth = 1.0 end
        if SetDepth >= CurrentDepth then CurrentDepth = SetDepth end
    end
    if IsControlJustReleased(0, 173) then
        SetDepth = SetDepth - 0.02
        if SetDepth <= 0.0 then SetDepth = 0.0 end
    end
    if IsControlJustReleased(0, 174) then
        SetSpeed = SetSpeed - 0.1
        if SetSpeed <= 0.0 then SetSpeed = 0.0 end
    end
    if IsControlJustReleased(0, 175) then
        SetSpeed = SetSpeed + 0.1
        if SetSpeed >= 1.0 then SetSpeed = 1.0 end
    end
    if IsControlJustReleased(0, 202) then
        ShouldDrawScaleform = false
    end
end

function StartDrillingMinigame()
    ShouldDrawScaleform, Scaleform, SetSpeed, SetDepth, SetTemp, CurrentDepth, PinsBroken, Result = true, nil, 0.0, 0.0, 0.0, 0.1, 1, false
    TempF9, TempF10, TempF12 = 0.0, 0.0, 0.0
    Scaleform = RequestScaleformMovie('DRILLING')
    while not HasScaleformMovieLoaded(Scaleform) do Wait(0) end
    SetScriptGfxDrawOrder(4)
    while ShouldDrawScaleform do
        CheckControls()
        TemperatureControl()
        CheckPins()
        CallScaleformMovieMethodWithNumber(Scaleform, 'SET_SPEED', SetSpeed, -1.0, -1.0, -1.0, -1.0)
        CallScaleformMovieMethodWithNumber(Scaleform, 'SET_DRILL_POSITION', SetDepth, -1.0, -1.0, -1.0, -1.0)
        CallScaleformMovieMethodWithNumber(Scaleform, 'SET_TEMPERATURE', SetTemp, -1.0, -1.0, -1.0, -1.0)
        DrawScaleformMovieFullscreen(Scaleform, 255, 255, 255, 255, 0)
        Wait(0)
    end
    CallScaleformMovieMethodWithNumber(Scaleform, 'SET_HOLE_DEPTH', 0.0, -1.0, -1.0, -1.0, -1.0)
    return Result
end
