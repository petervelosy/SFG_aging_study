function [pahandle, screenNumber, KbIdxSub, KbIdxExp] = initPTB(fs, devMode)
    %% Psychtoolbox initialization
    
    disp([newline, 'Initializing Psychtoolbox, PsychPortAudio...']);
        
    if ~exist('devMode', 'var')
        devMode = false;
    end
    
    if devMode
        Screen('Preference', 'SkipSyncTests', 1);
    end
    
    [pahandle] = initPTBAudio(fs);

    % General init (AssertOpenGL, 'UnifyKeyNames')
    PsychDefaultSetup(1);

    % init PsychPortAudio with pushing for lowest possible latency
    InitializePsychSound(1);

    % Keyboard params - names
    KbNameSub = 'Logitech USB Keyboard'; % TODO move to params
    KbNameExp = 'CASUE USB KB';
    % detect attached devices
    [keyboardIndices, productNames, ~] = GetKeyboardIndices;
    % define subject's and experimenter keyboards
    KbIdxSub = keyboardIndices(ismember(productNames, KbNameSub));
    KbIdxExp = keyboardIndices(ismember(productNames, KbNameExp));
    
    % Force costly mex functions into memory to avoid latency later on
    GetSecs; WaitSecs(0.1); KbCheck();

    % screen params, screen selection
    screens=Screen('Screens');
    screenNumber=max(screens);  % look into XOrgConfCreator and XOrgConfSelector 
end