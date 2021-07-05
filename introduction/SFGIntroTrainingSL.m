function SFGIntroTrainingSL(subNum, devMode, stimopt, loudnessEq)
%% Function to familiarize subjects with SFG stimuli
%
% USAGE: SFGintro(subNum, stimopt=SFGparamsIntro, loudnessEq=true)
%
% Gives control to the subject to request stimuli either without figure or
% with an easily recognizable figure. Two connected displays are assumed,
% one for experimenter/control, one for the subject with simple
% instructions.
%
% Mandatory input:
% subNum        - Numerical value. Subject number, one of 1:999.
%
% Optional inputs:
% devMode       - Development mode
% stimopt       - Struct. Its fields contain the parameters for SFG 
%               stimulus. Passed to createSingleSFGstim for generating 
%               stimuli. See SFGparamsIntro for details. Defaults to
%               calling SFGparamsIntro.
% loudnessEq    - Logical value. Flag for correcting for the perceived
%               loudness of different frequency components (see equal
%               loudness curves). Defaults to true. Gets passed on to 
%               createSingleSFGstim. 
%               If "true", the necessary gains for the frequencies specified
%               in "stimopt" are derived from the outputs of the iso226.m 
%               and are applied to the pure sine components.
%


%% Input checks

if ~ismembertol(nargin, 1:3)
    error(['Function SFGintro requires input arg "subNum" while input ',...
        'args "stimopt" and "loudnessEq" are optional!']);
end
if nargin == 1
    devMode = false;
    stimopt = SFGparamsIntro;
    loudnessEq = true;
elseif nargin == 2
    stimopt = SFGparamsIntro;
    loudnessEq = true;
elseif nargin == 3
    loudnessEq = true;
end
if ~ismembertol(subNum, 1:999)
    error('Input arg "subNum" should be between 1 - 999!');
end
if ~isstruct(stimopt)
    error('Input arg "stimopt" is expected to be a struct!');
end
if ~islogical(loudnessEq) || numel(loudnessEq)~=1
    error('Input arg "loudnessEq" should be a logical value!');
end

% Workaround for a command window text display bug - too much printing to
% command window results in garbled text, see e.g.
% https://www.mathworks.com/matlabcentral/answers/325214-garbled-output-on-linux
% Calling "clc" from time to time prevents the bug from making everything
% unreadable
clc;

disp([newline, 'Called function SFGintro with inputs: ',...
     newline, 'subject number: ', num2str(subNum),...
     newline, 'loudness correction flag is set to: ', num2str(loudnessEq),...
     newline, 'stimulus options: ']);
disp(stimopt);


%% stimopt versions for the recognizable-figure stimulus and the no-figure stimulus

% user message
disp([newline, 'Preparing stimulus parameters for figure/no-figure stimuli']);

% if there is a 'seed' field in stimopt, set the random num gen
if isfield(stimopt, 'randomSeed') && ~isempty(stimopt.randomSeed)
    rng(stimopt.randomSeed);
end

% easily recognizable version 
stimoptFigure = stimopt;
stimoptFigure.figureCoh = 14;

% ask user to verify coherence level of figure / provide a different
% value
cohFlag = 0;
while ~cohFlag  
    % verify current coherence level
    inputRes = input([newline, 'Coherence level for the figure is currently set at ',... 
        num2str(stimoptFigure.figureCoh), '. If that is fine, type "y", otherwise type "n": ',...
        newline], 's');
    % check value, set flag if default coherence value is okay
    if strcmp(inputRes, 'y')
        cohFlag = 1;
        disp([newline, 'Great, coherence level is kept at ', num2str(stimoptFigure.figureCoh), newline]);
    % ask for new value if default value was rejected
    elseif strcmp(inputRes, 'n')
        % inner input while loop
        newCohFlag = 0;
        while ~newCohFlag
            % get new coherence value
            inputRes = input([newline, 'Please provide a new value for coherence level (between 1-20): ', newline]);
            % check value
            if ismember(inputRes, 1:20)
                stimoptFigure.figureCoh = inputRes;
                newCohFlag = 1; cohFlag = 1;
                disp([newline, 'Coherence level is set to ', num2str(inputRes), newline]);
            else
                disp([newline, 'Wrong value, try again', newline]);
            end
        end
    else
        disp([newline, 'Wrong value, try again', newline]);
    end
end

stimoptFigureAsc = stimoptFigure;
stimoptFigureDesc = stimoptFigure;
stimoptFigureDesc.figureStepS = stimoptFigureDesc.figureStepS * -1;
        
% user message
disp([newline, 'Stimulus settings for easily-recognizable ascending figure version: ']);
disp(stimoptFigureAsc);

disp([newline, 'Stimulus settings for easily-recognizable descending figure version: ']);
disp(stimoptFigureDesc);

% stimulus with no figure
stimoptNoFigure = stimopt;
stimoptNoFigure.figureCoh = 0;
disp([newline, 'Stimulus settings for no-figure version: ']);
disp(stimoptNoFigure);

% user message
disp([newline, 'Prepared stimulus parameters']);

%% Basic settings for Psychtoolbox & PsychPortAudio

% user message
disp([newline, 'Initializing Psychtoolbox, PsychPortAudio...']);

fs = stimopt.sampleFreq;
[pahandle, screenNumber, KbIdxSub, KbIdxExp] = initPTB(fs);
    
% Define the specific keys we use
keys.abort = KbName('ESCAPE');
keys.go = KbName('SPACE');
% counterbalancing response side across subjects, based on subject number
if mod(subNum, 2) == 0
	keys.figAsc = KbName('l');
	keys.figDesc = KbName('s');
else
    keys.figAsc = KbName('s');
    keys.figDesc = KbName('l');
end

if ~devMode
    setUpKeyRestrictions(keys);
end

% Set up display params:
backGroundColor = [0 0 0];
textColor = [255 255 255];

smallScreen = false;
[win, rect, ~] = setUpAndOpenPTBScreen(screenNumber, backGroundColor, smallScreen);

[xCenter, yCenter] = RectCenter(rect);

fixCrossWin = createFixationCrossOffscreenWindow(win, backGroundColor, textColor, rect);
qMarkWin = createQuestionMarkOffscreenWindow(win, backGroundColor, textColor, rect);

okRespWin = createTextFeedbackOffscreenWindow('Jó válasz', win, backGroundColor, rect, xCenter, yCenter, textColor);
badRespWin = createTextFeedbackOffscreenWindow('Rossz válasz', win, backGroundColor, rect, xCenter, yCenter, textColor);

% set flag for aborting experiment
abortFlag = 0;

% init flag for reqested trial type
nextTrial = [];

if ~devMode
    % hide mouse
    HideCursor(screenNumber);
    % suppress keyboard input to command window
    ListenChar(-1);
    % realtime priority
    Priority(1);
end

% user message
disp([newline, 'Initialized psychtoolbox basics, opened window, ',...
    'started PsychPortAudio device']);


%% Start stimulus introduction

% instructions for subject
introText = double(['A következőben fel kell ismernie az előbb bemutatott hangminta-típusokat.\n'...,
    'Minden választ követően visszajelzést kap a válasz helyességéről. \n\n',...
    'Két féle mintát használunk: emelkedő vagy ereszkedő hangsor.\n\n',...
    'A hangmintában van emelkedő hangsor  -  "', KbName(keys.figAsc), '" billentyű. \n',...
    'A hangmintában van ereszkedő hangsor  -  "', KbName(keys.figDesc), '" billentyű. \n\n',...
            'Mindig akkor válaszoljon, amikor a kérdőjel látható.\n\n',...
    'Nyomja meg a "SPACE" billentyűt a kezdéshez! \n\n',...
    'Az "', KbName(keys.abort), '" billentyűvel befejezheti a feladatot.']);

% display instructions
Screen('FillRect', win, backGroundColor);
DrawFormattedText(win, introText, 'center', 'center', textColor);
Screen('Flip', win);

% user message
disp([newline, 'Showing the instructions text right now...']);

% wait for key press to start
while 1
    [keyIsDownSub, ~, keyCodeSub] = KbCheck(KbIdxSub);
    [keyIsDownExp, ~, keyCodeExp] = KbCheck(KbIdxExp);
    % subject key down
    if keyIsDownSub 
        % if subject is ready to start
        if find(keyCodeSub) == keys.go
            break;
        end
    % experimenter key down    
    elseif keyIsDownExp
        % if abort was requested    
        if find(keyCodeExp) == keys.abort
            abortFlag = 1;
            break;
        end
    end
end
if abortFlag
    closePTB(screenNumber);
    return;
end

% feedback to subject - we are starting
Screen('FillRect', win, backGroundColor);
DrawFormattedText(win, 'Starting...', 'center', 'center', textColor);
Screen('Flip', win);

%% Loop of playing requested stimuli

targetAbsStepSize = 50;
stepSizeStep = -10;
minTrialsPerStepSize = 20;
minCumAcc = 0.75;
feedbackDisplayTimeSec = 1;

trialTypes = [-1, 1];

acc = [];
cumAcc = 0;

index = 1;
while ~(stimoptFigureAsc.figureStepS == targetAbsStepSize && index > minTrialsPerStepSize && cumAcc >= minCumAcc)  % until exit condition is met or abort is requested
    
    % display fixation cross
    % background with fixation cross, get trial start timestamp
    Screen('CopyWindow', fixCrossWin, win);
    Screen('DrawingFinished', win);
    trialStart = Screen('Flip', win); 
    
    rnd = randi(2);
    nextTrial = trialTypes(rnd);
    
    % create stimulus - with an ascending or a descending figure
    if nextTrial == 1
        % create next stimulus and load it into buffer
        [soundOutput, ~, ~] = createSingleSFGstim(stimoptFigureAsc, loudnessEq);
        buffer = PsychPortAudio('CreateBuffer', [], soundOutput);
        PsychPortAudio('FillBuffer', pahandle, buffer); 
    elseif nextTrial == -1
        % create next stimulus and load it into buffer
        [soundOutput, ~, ~] = createSingleSFGstim(stimoptFigureDesc, loudnessEq);
        buffer = PsychPortAudio('CreateBuffer', [], soundOutput);
        PsychPortAudio('FillBuffer', pahandle, buffer); 
    end
    
    % iti - random wiat time of 500-800 ms, treated generously
    iti = rand(1)*0.3+0.5;
    
    % user message
    if nextTrial==1
        trialMessage = 'with an ascending';
    elseif nextTrial==-1
        trialMessage = 'with a descending';
    end
    disp([newline, 'Playing next stimulus - ', trialMessage, ' figure']);
    disp(['Step size: ', num2str(stimoptFigureAsc.figureStepS)]);
    disp(['Trial index for this step size: ', num2str(index)]);
    
    % play stimulus - blocking start
    startTime = PsychPortAudio('Start', pahandle, 1, trialStart+iti, 1);
    
    % wait till playback is over
    WaitSecs('UntilTime', startTime+stimopt.totalDur);
    
   % prepare screen change for response period       
    Screen('CopyWindow', qMarkWin, win);
    Screen('DrawingFinished', win);

    % switch visual right when the audio finishes
    respStart = Screen('Flip', win, startTime+stimopt.totalDur);

    % wait for response
    while 1
        [keyIsDownSub, ~, keyCodeSub] = KbCheck(KbIdxSub);
        [keyIsDownExp, ~, keyCodeExp] = KbCheck(KbIdxExp);
        % subject key down
        if keyIsDownSub
            % if subject responded figure presence/absence
            if find(keyCodeSub) == keys.figAsc
                detectedDirection = 1;
                acc(index) = detectedDirection == nextTrial;
                
                if acc(index)
                    Screen('CopyWindow', okRespWin, win);
                    Screen('DrawingFinished', win);
                    Screen('Flip', win);
                    WaitSecs(feedbackDisplayTimeSec);
                else
                    Screen('CopyWindow', badRespWin, win);
                    Screen('DrawingFinished', win);
                    Screen('Flip', win);
                    WaitSecs(feedbackDisplayTimeSec);
                end
                break;
            elseif find(keyCodeSub) == keys.figDesc
                detectedDirection = -1;
                acc(index) = detectedDirection == nextTrial;
                
                if acc(index)
                    Screen('CopyWindow', okRespWin, win);
                    Screen('DrawingFinished', win);
                    Screen('Flip', win);
                    WaitSecs(feedbackDisplayTimeSec);
                else
                    Screen('CopyWindow', badRespWin, win);
                    Screen('DrawingFinished', win);
                    Screen('Flip', win);
                    WaitSecs(feedbackDisplayTimeSec);
                end
                break;
            end
        % experimenter key down    
        elseif keyIsDownExp
            % if abort was requested    
            if find(keyCodeExp) == keys.abort
                abortFlag = 1;
                break;
            end
        end
    end

    % if abort was requested, quit
    if abortFlag
        closePTB(screenNumber);
        return;
    end   
    
    cumAcc = sum(acc) / size(acc, 2);
    disp(['Cumulative accuracy: ', num2str(cumAcc)]);
    
    if stimoptFigureAsc.figureStepS > targetAbsStepSize && index >= minTrialsPerStepSize && cumAcc >= minCumAcc
        acc = [];
        cumAcc = 0;
        newAbsStepSize = stimoptFigureAsc.figureStepS + stepSizeStep;
        disp(['Min trial count and cumulative accuracy criteria met. Raising absolute step size to ', num2str(newAbsStepSize)]);
        stimoptFigureAsc.figureStepS = newAbsStepSize;
        stimoptFigureDesc.figureStepS = -newAbsStepSize;
        index = 1;
    else
        index = index + 1;
    end
        
    % only go on to next stimulus when keys are released
    KbReleaseWait;
    
end


%% Ending

disp('Terminating at user''s or subject''s request')
ListenChar(0);
Priority(0);
RestrictKeysForKbCheck([]);
PsychPortAudio('Close');
sca; Screen('CloseAll');
ShowCursor(screenNumber);


return









