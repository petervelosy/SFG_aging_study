function expopt = experimentParamsElderly()

figureCoh = 11;
toneCompHigh = 20-figureCoh;
toneCompLow = toneCompHigh+5;


expopt = struct( ...
    'figureCoh', figureCoh, ...
    'toneCompHigh', toneCompHigh, ...
    'toneCompLow', toneCompLow, ...
    'stepSizeMin', 1, ...
    'stepSizeMax', 10, ...
    'stepSizeStep', 1, ...
    'initialStepSize', 60, ...
    'staircaseHitThreshold', 3, ...
    'staircaseMissThreshold', 1, ...
    'minTrialCountPerBlock', 100, ...
    'minReversalCountPerBlock', 9);
        
end
        