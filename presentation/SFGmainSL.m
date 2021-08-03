function SFGmainSL(subNum, feedback, devMode, varargin)
%% Stochastic figure-ground experiment - main experimental script
%
% USAGE: SFGmain(subNum, stimArrayFile=./subjectXX/stimArray*.mat, blockNo=10, triggers='yes')
%
% Stimulus presentation script for stochastic figure-ground (SFG) experiment. 
% The script requires pre-generated stimuli organized into a
% "stimArrayFile". See the functions in /stimulus for details on producing
% stimuli. 
% The script also requires stim2blocksSupervisedLearning.m for sorting stimuli into blocks
% and expParamsHandlerSupervisedLearning.m for handling the loading of stimuli and existing
% parameters/settings, and also for detecting and handling earlier sessions 
% by the same subject (for multi-session experiment).
%
% Mandatory input:
% subNum        - Numeric value, one of 1:999. Subject number.
% feedback      - true = training mode, false = test mode
% devMode       - Development mode
%
% Optional inputs:
% stimArrayFile - Char array, path to *.mat file containing the cell array 
%               "stimArray" that includes all stimuli + features
%               (size: no. of stimuli X 12 columns). Defaults to
%               ./subjectXX/stimArray*.mat, where XX stands for subject
%               number (subNum).
% blockNo       - Numeric value, one of 1:50. Number of blocks to sort 
%               trials into. Defaults to 10. 
% triggers      - Char array, one of {'yes', 'no'}. Sets flag for using /
%               not using TTL-level triggers used with EEG-recording.
%
% Results (response times and presentation timestamps for later checks) are
% saved out into /subjectXX/subXXLog.mat, where XX stands for subject
% number.
%
% NOTES:
% (1) Responses are counterbalanced across subjects, based on subject
% numbers (i.e., based on mod(subNum, 2)). This is a hard-coded method!!
% (2) Response keys are "L" and "S", hard-coded!!
% (3) Main psychtoolbox settings are hard-coded!! Look for the psychtoolbox
% initialization + the audio parameters code block for details
% (4) Logging (result) variable columns: 
% logHeader={'subNum', 'blockNo', 'trialNo', 'stimNo', 'toneComp',... 
%     'figCoherence', 'figPresence', 'figStartChord', 'figEndChord',... 
%     'accuracy', 'buttonResponse', 'respTime', 'iti', 'trialStart',... 
%     'soundOnset', 'figureStart', 'respIntervalStart', 'trigger'};
%
%

%% Input checks

% check no. of input args
if ~ismembertol(nargin, 1:6)
    error('Function SFGmain requires input arg "subNum" while input args "feedback", "devMode", "stimArrayFile", "blockNo" and "triggers" are optional!');
end
% check mandatory arg - subject number
if ~ismembertol(subNum, 1:999)
    error('Input arg "subNum" should be between 1 - 999!');
end
if ~exist('feedback', 'var')
    feedback = false;
end
if ~exist('devMode', 'var')
    devMode = false;
end
% check and sort optional input args
if ~isempty(varargin)
    for v = 1:length(varargin)
        if isnumeric(varargin{v}) && ismembertol(varargin{v}, 1:50) && ~exist('blockNo', 'var')
            blockNo = varargin{v};
        elseif ischar(varargin{v}) && exist(varargin{v}, 'file') && ~exist('stimArrayFile', 'var')
            stimArrayFile = varargin{v};
        elseif ischar(varargin{v}) && ismember(varargin{v}, {'yes', 'no'}) && ~exist('triggers', 'var')
            triggers = varargin{v};    
        else
            error('An input arg could not be mapped nicely to "stimArrayFile" or "blockNo"!');
        end
    end
end
% default values
if ~exist('stimArrayFile', 'var')
    % look for any file "stimArray*.mat" in the subject's folder
    stimArrayFileStruct = dir(['subject', num2str(subNum), '/stimArray*.mat']);
    expoptFileStruct = dir(['subject', num2str(subNum), '/expopt*.mat']);
    % if there was none or there were multiple
    if isempty(stimArrayFileStruct) || length(stimArrayFileStruct)~=1
        error(['Either found too many or no stimArrayFile at ./subject', num2str(subNum), '/stimArray*.mat !!!']);
    else
        stimArrayFile = [stimArrayFileStruct.folder, '/', stimArrayFileStruct.name];
        expoptFile = [stimArrayFileStruct.folder, '/', expoptFileStruct.name];
    end
end
if ~exist('blockNo', 'var')
    blockNo = 4; % TODO
end
if ~exist('triggers', 'var')
    triggers = 'yes';
end

% turn input arg "triggers" into boolean
if strcmp(triggers, 'yes')
    triggers = true;
else
    triggers = false;
end

% Workaround for a command window text display bug - too much printing to
% command window results in garbled text, see e.g.
% https://www.mathworks.com/matlabcentral/answers/325214-garbled-output-on-linux
% Calling "clc" from time to time prevents the bug from making everything
% unreadable
clc;

% user message
disp([newline, 'Called SFGmain (the main experimental function) with input args: ',...
    newline, 'subNum: ', num2str(subNum),...
    newline, 'stimArrayFile:', stimArrayFile,...
    newline, 'blockNo: ', num2str(blockNo)]);


%% Load/set params, stimuli, check for conflicts

% user message
disp([newline, 'Loading params and stimuli, checking ',...
    'for existing files for the subject']);

% a function handles all stimulus sorting to blocks and potential conflicts
% with earlier recordings for same subject
[stimArray, ~,... 
    startBlockNo,...
    logVar, subLogF, returnFlag,... 
    logHeader, stimTypes] = expParamsHandlerSupervisedLearning(subNum, stimArrayFile, blockNo);

%%%%%%%%%%%%%%%%%%%%%% HARDCODED BREAKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
breakBlocks = [4, 7];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% if there was early return from expParamsHandlerSupervisedLearning.m, abort
if returnFlag
    return
end

% user message
disp([newline, 'Ready to start the experiment']);

%% Stimulus features for triggers + logging

% get step size variable for stimuli
stepSizes = cell2mat(stimArray(:, 7));

% we check the length of stimuli + sanity check
stimLength = cell2mat(stimArray(:, 2));
if ~isequal(length(unique(stimLength)), 1)
    error([newline, 'There are multiple different stimulus length values ',...
        'specified in the stimulus array!']);
else
    stimLength = unique(stimLength);
end

% we also check the length of a cord + sanity check
chordLength = cell2mat(stimArray(:, 3));
if ~isequal(length(unique(chordLength)), 1)
    error([newline, 'There are multiple different chord length values ',...
        'specified in the stimulus array!']);
else
    chordLength = unique(chordLength);
end

% user message
disp([newline, 'Extracted stimulus features']);


%% Triggers

% basic triggers for trial start, sound onset and response
trig = struct;
trig.playbackStartPart = 10;
trig.figureStartPart = 20;
trig.respCorrect = 55;
trig.respIncorrect = 66;
trig.l = 1000; % trigger length in microseconds
trig.blockStartPart = 100;
trig.blockEnd = 200;

% user message
disp([newline, 'Set up triggers']);


%% Psychtoolbox initialization

fs = stimArray{1,8}; % take sample rate from the first stimulus
[pahandle, screenNumber, KbIdxSub, KbIdxExp] = initPTB(fs, devMode);

% Define the specific keys we use
keys = struct;
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

% screen params, screen selection
backGroundColor = [0 0 0];
textColor = [255 255 255];
% smallScreen = devMode; TODO
smallScreen = false;
[win, rect, ifi] = setUpAndOpenPTBScreen(screenNumber, backGroundColor, smallScreen);

[xCenter, yCenter] = RectCenter(rect);

fixCrossWin = createFixationCrossOffscreenWindow(win, backGroundColor, textColor, rect);
qMarkWin = createQuestionMarkOffscreenWindow(win, backGroundColor, textColor, rect);

% TODO refactor to take 'rect' instead of 'xCenter' and 'yCenter'
okRespWin = createTextFeedbackOffscreenWindow('Jó válasz', win, backGroundColor, rect, xCenter, yCenter, textColor);
badRespWin = createTextFeedbackOffscreenWindow('Rossz válasz', win, backGroundColor, rect, xCenter, yCenter, textColor);

% set random ITI between 500-800 ms, with round 100 ms values
iti = (randi(4, [size(stimArray, 1)*100 1])+4)/10;  % in secs

% response time interval
respInt = 2;

% response variables preallocation
detectedDirection = nan(size(stimArray, 1)*100, 1);
respTime = detectedDirection;
acc = detectedDirection;

% set flag for aborting experiment
abortFlag = 0;
if devMode
    % hide mouse
    HideCursor(screenNumber);
    % suppress keyboard input to command window
    ListenChar(-1);
end
% realtime priority
Priority(1);

% minimum wait time for breaks in secs
breakTimeMin = 120;

if triggers
    % init parallel port control
    ppdev_mex('Open', 1);
end

% user message
disp([newline, 'Initialized psychtoolbox basics, opened window, ',...
    'started PsychPortAudio device']);


%% Instructions phase

% instructions text
instrText = double(['A feladat ugyanaz lesz, mint az előző blokkok során - \n',... 
    'jelezze, hogy a hangmintában emelkedő vagy ereszkedő hangsort hall.\n\n',...
    'Emelkedő hangsor a hangmintában - "', KbName(keys.figAsc), '" billentyű. \n',... 
    'Ereszkedő hangsor a hangmintában - "' ,KbName(keys.figDesc), '" billentyű. \n\n',...
    'Mindig akkor válaszoljon, amikor megjelenik a kérdőjel.\n\n',...
    'Nyomja meg a SPACE billentyűt ha készen áll!']);

% write instructions to text
Screen('FillRect', win, backGroundColor);
DrawFormattedText(win, instrText, 'center', 'center', textColor);
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
    if triggers
        ppdev_mex('Close', 1);
    end
    closePTB(screenNumber);
    return;
end

% user message
disp([newline, 'Subject signalled she/he is ready, we go ahead with the task']);

%% Preload all stimuli

expopt = load(expoptFile, 'expopt');

buffer = [];
for i = 1:size(stimArray,1)
    audioData = stimArray{i, 12};
    buffer(end+1) = PsychPortAudio('CreateBuffer', [], audioData');
end

feedbackDisplayTimeSec = 1;

% Exit conditions:
minTrialCount = expopt.expopt.minTrialCountPerBlock;
minReversalCount = expopt.expopt.minReversalCountPerBlock;

%% Blocks loop

% overall trial counter
trial = 0;

% start from the block specified by the parameters/settings parts
for block = startBlockNo:blockNo
    
    reversalCount = 0;

    % uniform background
    Screen('FillRect', win, backGroundColor);
    Screen('Flip', win);    
    
    % wait for releasing keys before going on
    releaseStart = GetSecs;
    KbReleaseWait([], releaseStart+2);

    % counter for trials in given block
    trialCounterForBlock = 0;    
    
    % user message
    disp([newline, 'Buffered all stimuli for block ', num2str(block),... 
        ', showing block start message']);    
     
    % block starting text
    blockStartText = double(['Kezdhetjük a(z) ', num2str(block), '. blokkot,\n\n\n',... 
            'Nyomja meg a SPACE billentyűt ha készen áll!']);
    
    % uniform background
    Screen('FillRect', win, backGroundColor);
    % draw block-starting text
    DrawFormattedText(win, blockStartText, 'center', 'center', textColor);
    Screen('Flip', win);
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
        if triggers
            ppdev_mex('Close', 1);
        end
        closePTB(screenNumber);
        return;
    end    
    
    if triggers
        % block start trigger
        sendTrigger(1, trig.blockStartPart+block, trig.l);
    end
    
    
    %% Trials loop
    
    initialStepSize = expopt.expopt.initialStepSize;
    staircaseHitThreshold = expopt.expopt.staircaseHitThreshold;
    staircaseMissThreshold = expopt.expopt.staircaseMissThreshold;
    
    stepSize = initialStepSize;
    hitsInARow = 0;
    missesInARow = 0;
    staircaseTendency = 0;
    
    % TODO move up
    subDirName = ['subject', num2str(subNum)];
    
    % get file name for SFGthresholdBackgroundSL results - exact file name contains unknown time stamp
    backgrResFile = dir([subDirName, '/thresholdBackgroundSL_sub', num2str(subNum), '*.mat']);
    backgrResFilePath = [backgrResFile.folder, '/', backgrResFile.name];
    % load results from background-thresholding
    backgrRes = load(backgrResFilePath);
    
    toneCompConditions = [backgrRes.backgroundEst, backgrRes.backgroundEst+expopt.expopt.highLowBgCompDiff];
    % Odd numbered blocks will contain high SNR, even numbered blocks low SNR stimuli. 
    toneCompIndex = iif(mod(block,2) == 1, 1, 2);
    toneComp = toneCompConditions(toneCompIndex);
    toneCompTriggerParts = [0, 2];
    toneCompTriggerPart = toneCompTriggerParts(toneCompIndex);
 
    directionConditions = [-1, 1];
    directionTriggerParts = [2, 1];
    
    % trial loop (over the trials for given block)
    while ~(trialCounterForBlock >= minTrialCount && reversalCount >= minReversalCount)
        
        % randomize parameters
        directionIndex = randi(2);
        direction = directionConditions(directionIndex);
        directionTriggerPart = directionTriggerParts(directionIndex);
        desiredStepSize = stepSize * direction;
        disp(['Step size:', num2str(desiredStepSize)]);
        
        filteredStimIndexes = find(cell2mat(stimArray(:,7))==desiredStepSize & cell2mat(stimArray(:,11))-cell2mat(stimArray(:,6))==toneComp);
        stimIndex = filteredStimIndexes(randi(length(filteredStimIndexes)));
        disp(['StimIndex: ', num2str(stimIndex)]);
        
        % relative trial number (trial in given block)
        trialCounterForBlock = trialCounterForBlock+1;
       
        % absolute trial number
        trial = trial + 1;
        
        % background with fixation cross, get trial start timestamp
        Screen('CopyWindow', fixCrossWin, win);
        Screen('DrawingFinished', win);
        trialStart = Screen('Flip', win);
        
        % user message
        disp([newline, 'Starting trial ', num2str(trialCounterForBlock)]);
        if stepSizes(stimIndex) > 0
            disp('There is an ascending figure in this trial');
        elseif stepSizes(stimIndex) < 0
            disp('There is a descending figure in this trial');
        end

        % fill audio buffer with next stimuli
        PsychPortAudio('FillBuffer', pahandle, buffer(stimIndex));
        
        % wait till we are 100 ms from the start of the playback
        while GetSecs-trialStart <= iti(trial)-100
            WaitSecs(0.001);
        end
        
        % blocking playback start for precision
        startTime = PsychPortAudio('Start', pahandle, 1, trialStart+iti(trial), 1);
        
        % playback start trigger
        playbackStartTrigger = trig.playbackStartPart + toneCompTriggerPart + directionTriggerPart;
        figureStartTrigger = trig.figureStartPart + toneCompTriggerPart + directionTriggerPart;
        if triggers
            sendTrigger(1, playbackStartTrigger, trig.l);
            figStartChord = cell2mat(stimArray(stimIndex,9));
            chordLength = cell2mat(stimArray(stimIndex,3));
            WaitSecs(chordLength * (figStartChord-1));
            sendTrigger(1, figureStartTrigger, trig.l);
        end
        
        % user message
        disp(['Audio started at ', num2str(startTime-trialStart), ' secs after trial start']);
        disp(['(Target ITI was ', num2str(iti(trial)), ' secs)']);
        
        % prepare screen change for response period       
        Screen('CopyWindow', qMarkWin, win);
        Screen('DrawingFinished', win);
        
        % switch visual right when the audio finishes
        respStart = Screen('Flip', win, startTime+stimLength-0.5*ifi);
        
        % user message
        disp(['Visual flip for response period start was ', num2str(respStart-startTime),... 
            ' secs after audio start (should equal ', num2str(stimLength), ')']);
        
        % wait for response
        respFlag = 0;
        while GetSecs-(startTime+stimLength) <= respInt
            [keyIsDownSub, respSecs, keyCodeSub] = KbCheck(KbIdxSub);
            [keyIsDownExp, ~, keyCodeExp] = KbCheck(KbIdxExp);
            % subject key down
            if keyIsDownSub
                % if subject responded figure presence/absence
                if find(keyCodeSub) == keys.figAsc
                    detectedDirection(trial) = 1;
                    respFlag = 1;
                    break;
                elseif find(keyCodeSub) == keys.figDesc
                    detectedDirection(trial) = -1;
                    respFlag = 1;
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
            if triggers
                ppdev_mex('Close', 1);
            end
            closePTB(screenNumber);
            return;
        end        
        
        % response time into results variable
        if respFlag
            respTime(trial) = 1000*(respSecs-respStart);
        end
        
        % user messages
        if detectedDirection(trial) == 1
            disp('Subject detected an ascending figure');    
        elseif detectedDirection(trial) == -1
            disp('Subject detected a descending figure');
        elseif isnan(detectedDirection(trial))
            disp('Subject did not respond in time');
        end
        % accuraccy
        if (detectedDirection(trial)==1 && desiredStepSize > 0) || (detectedDirection(trial)==-1 && desiredStepSize < 0)
            disp('Subject''s response was accurate');
            acc(trial) = 1;
            if triggers
                lptwrite(1, trig.respCorrect, trig.l);
            end
            hitsInARow = hitsInARow + 1;
            missesInARow = 0;
            disp(['Hits in a row:', num2str(hitsInARow)]);
            if staircaseTendency == 0
                staircaseTendency = -1;
            end
            if hitsInARow == staircaseHitThreshold
                if stepSize > expopt.expopt.stepSizeMin
                    hitsInARow = 0;
                    stepSize = stepSize - expopt.expopt.stepSizeStep;
                    if staircaseTendency == 1
                        staircaseTendency = -1;
                        reversalCount = reversalCount + 1;
                        disp(['REVERSAL nr. ', num2str(reversalCount)]);
                    end
                else
                    disp('No reversal will occur: we are at the minimum available step size.');
                end
            end
            if feedback
                Screen('CopyWindow', okRespWin, win);
                Screen('DrawingFinished', win);
                Screen('Flip', win);
                WaitSecs(feedbackDisplayTimeSec);
            end
        elseif (detectedDirection(trial)==1 && desiredStepSize < 0) || (detectedDirection(trial)==-1 && desiredStepSize > 0)
            disp('Subject made an error');
            acc(trial) = 0;
            if triggers
                lptwrite(1, trig.respIncorrect, trig.l);
            end
            missesInARow = missesInARow + 1;
            hitsInARow = 0;
            disp(['Misses in a row:', num2str(missesInARow)]);
            if staircaseTendency == 0
                staircaseTendency = -1;
            end
            if missesInARow == staircaseMissThreshold
                if stepSize < expopt.expopt.stepSizeMax
                    stepSize = stepSize + expopt.expopt.stepSizeStep;
                    if staircaseTendency == -1
                        staircaseTendency = 1;
                        reversalCount = reversalCount + 1;
                        disp(['REVERSAL nr. ', num2str(reversalCount)]);
                    end
                else
                    disp('No reversal will occur: we are at the maximum available step size.');
                end
            end
            if feedback
                Screen('CopyWindow', badRespWin, win);
                Screen('DrawingFinished', win);
                Screen('Flip', win);
                WaitSecs(feedbackDisplayTimeSec);
            end
        end
        % response time
        if ~isnan(respTime(trial))
            disp(['Response time was ', num2str(respTime(trial)), ' ms']);
        end
        % cumulative accuraccy
        % in block
        blockAcc = sum(acc(trial-trialCounterForBlock+1:trial), 'omitnan')/trialCounterForBlock*100;
        disp(['Overall accuraccy in block so far is ', num2str(blockAcc), '%']);
        
        % accumulating all results in logging / results variable
            
        stimFileName = cell2mat(stimArray(stimIndex, 1));
        toneComps = cell2mat(stimArray(stimIndex, 11));
        figCoherence = cell2mat(stimArray(stimIndex, 6));
        figStepSize = cell2mat(stimArray(stimIndex, 7));
        figStartChord = cell2mat(stimArray(stimIndex, 9));
        figEndChord = cell2mat(stimArray(stimIndex, 10));
    
        logVar(end+1, 1:end) = {subNum, block, trial, stimFileName, toneComps, ...
            figCoherence, figStepSize, figStartChord, figEndChord...
            acc(trial), detectedDirection(trial),... 
            respTime(trial), iti(trial),...
            trialStart, startTime-trialStart,... 
            (figStartChord-1)*chordLength,... 
            respStart-startTime, playbackStartTrigger};
        
        % save logging/results variable
        save(subLogF, 'logVar');
        
    end  % trial for loop
     
    % Workaround for a command window text display bug - too much printing to
    % command window results in garbled text, see e.g.
    % https://www.mathworks.com/matlabcentral/answers/325214-garbled-output-on-linux
    % Calling "clc" from time to time prevents the bug from making everything
    % unreadable
    clc;    
    
    % user messages
    disp([newline, newline, 'Block no. ', num2str(block), ' has ended,'... 
        'showing block-ending text to participant']);
    disp([newline, 'Overall accuracy in block was ', num2str(blockAcc),... 
        '%']);    
    
    
    %% Feedback to subject at the end of block
    % if not last block and not a break
    if (block ~= blockNo) && ~ismembertol(block, breakBlocks)  
        
        if triggers
            % block end trigger
            lptwrite(1, trig.blockEnd, trig.l);
        end
        
        % block ending text
        blockEndText = double(['Vége a(z) ', num2str(block), '. blokknak!\n\n\n',... 
                'Ebben a blokkban a próbák ', num2str(round(blockAcc, 2)), '%-ra adott helyes választ.\n\n\n',... 
                'Nyomja meg a SPACE billentyűt ha készen áll a következő blokkra!']);
        % uniform background
        Screen('FillRect', win, backGroundColor);
        % draw block-starting text
        DrawFormattedText(win, blockEndText, 'center', 'center', textColor);   
        Screen('Flip', win);
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
            if triggers
                ppdev_mex('Close', 1);
            end
            closePTB(screenNumber);
            return;
        end  
    
    % if not last block and there is a break
    elseif (block ~= blockNo) && ismembertol(block, breakBlocks)
        
        if triggers
            % block end trigger
            lptwrite(1, trig.blockEnd, trig.l);
        end
        
        % user message
        disp([newline, 'There is a BREAK now!']);
        disp('Only the experimenter can start the next block - press "SPACE" when ready');
        
        % block ending text
        blockEndText = double(['Vége a(z) ', num2str(block), '. blokknak!\n\n\n',... 
                'Ebben a blokkban a próbák ', num2str(round(blockAcc, 2)), '%-ra adott helyes választ.\n\n\n',... 
                'Most tartunk egy rövid szünetet, a kísérletvezető hamarosan beszél Önnel.']);
        % uniform background
        Screen('FillRect', win, backGroundColor);
        % draw block-starting text
        DrawFormattedText(win, blockEndText, 'center', 'center', textColor);   
        Screen('Flip', win);
        
        % approximate wait time 
        
        % wait for key press to start
        while 1
            [keyIsDownExp, ~, keyCodeExp] = KbCheck(KbIdxExp);
            % experimenter key down
            if keyIsDownExp 
                % if subject is ready to start
                if find(keyCodeExp) == keys.go
                    break;
                % if abort was requested    
                elseif find(keyCodeExp) == keys.abort
                    abortFlag = 1;
                    break;
                end
            end
        end
        if abortFlag
            if triggers
                ppdev_mex('Close', 1);
            end
            closePTB(screenNumber);
            return;
        end      
        
        
    % if last block ended now   
    elseif block == blockNo
 
        % user message
        disp([newline, 'The task has ended!!!']);
        
        % block ending text
        blockEndText = double(['Vége a feladatnak!\n',...
            'Az utolsó blokkban a próbák ', num2str(round(blockAcc, 2)), '%-ra adott helyes választ.\n\n',...
            'Köszönjük a részvételt!']);       
        % uniform background
        Screen('FillRect', win, backGroundColor);
        % draw block-starting text
        DrawFormattedText(win, blockEndText, 'center', 'center', textColor);  
        Screen('Flip', win);
        
        WaitSecs(5);
        
    end  % if block       
         
    
end  % block for loop


%% Ending, cleaning up

disp(' ');
disp('Got to the end!');

if triggers
    ppdev_mex('Close', 1);
end
ListenChar(0);
Priority(0);
RestrictKeysForKbCheck([]);
PsychPortAudio('Close');
Screen('CloseAll');
ShowCursor(screenNumber);


return


    
  
    