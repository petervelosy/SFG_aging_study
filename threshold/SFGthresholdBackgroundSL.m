function SFGthresholdBackgroundSL(subNum, group, varargin)
Screen('Preference', 'SkipSyncTests', 1); % TODO remove this

% TODO SNR min-max
% TODO set stepSize (70)
% TODO development mode (do not restrict keyboard or mouse input, skip sync
% tests)

%% Quest threshold for SFG stimuli aimed at estimating the effect of background notes
%
% USAGE: SFGthresholdBackground(subNum, stimopt=SFGparamsThreshold, trialMax=80, loudnessEq=true)
%
% The procedure changes the number of background tones using the adaptive staircase
% procedure QUEST. Fixed trial + QuestSd check approach, that is, the
% function checks QuestSd after a fixed number of trials (=trialMax), and
% runs for an additional number of trials ("trialExtraMax", hardcoded!) if  
% the standard deviation is under a predefined threshold 
% (1.5*median(abs(diff(snrLogLevels)))).
%
% The function returns the Quest object ("q") and also saves it out to 
% the folder of the subject. 
%
% Expects subject's folder to already exist and contain the results /
% output from SFGthresholdCoherence.m
%
% IMPORTANT: INITIAL QUEST PARAMETERS AND PSYCHTOOLBOX SETTINGS ARE 
% HARDCODED! TARGET THRESHOLD IS 75%! 
%
% Specific settings in general are for Mordor / Gondor labs of RCNS, Budapest.
%
% Mandatory input:
% subNum        - Numeric value, subject number. One of 1:999.
% group         - String, one of 'Young', 'Elderly', 'ElderlyHI'.
%
% Optional inputs:
% stimopt       - Struct containing the base parameters for SFG stimulus. 
%               Passed to createSingleSFGstim for generating stimuli. See
%               SFGparamsThreshold.m for details. Defaults to calling 
%               SFGparamsThreshold.m
% trialMax      - Numeric value, number of trials used for staircase
%               procedure, one of 10:120. Defaults to 80.
% loudnessEq    - Logical value. Flag for correcting for the perceived
%               loudness of different frequency components (see equal
%               loudness curves). Defaults to true. Gets passed on to 
%               createSingleSFGstim. 
%               If "true", the necessary gains for the frequencies specified
%               in "stimopt" are derived from the outputs of the iso226.m 
%               and are applied to the pure sine components.
%
% Output:
% q             - Quest object.
%
% NOTES:
% (1) Pay attention to Quest outcomes as inattentive / fatiqued / etc
% subjects might have unrealistic results at first.


%% Input checks

% check no. of args
if ~ismember(nargin, 1:4) 
    error('Function SFGthresholdBackground needs mandatory input arg "subNum" and "group" while args "stimopt", "trialMax" and "loudnessEq" are optional!');
end
% check mandatory input arg
if ~ismembertol(subNum, 1:999)
    error('Input arg "subNum" should be one of 1:999!');
end
if ~ismember(group, ['Young', 'Elderly', 'ElderlyHI'])
    error('Input arg "group" should be one of "Young", "Elderly", "ElderlyHI"!');
end
% check optional input args
if ~isempty(varargin)
    for v = 1:length(varargin)
        if isstruct(varargin{v}) && ~exist('stimopt', 'var')
            stimopt = varargin{v};
        elseif isnumeric(varargin{v}) && ismembertol(varargin{v}, 10:120) && ~exist('trialMax', 'var')
            trialMax = varargin{v};
        elseif islogical(varargin{v}) && numel(varargin{v})==1 && ~exist('loudnessEq', 'var')
            loudnessEq = varargin{v};             
        else
            error('An input arg could not be mapped nicely to "stimopt", "trialMax" or "loudnessEq"!');
        end
    end
end
% default values to optional args
if ~exist('stimopt', 'var')
    stimopt = SFGparamsThreshold();
end
if ~exist('trialMax', 'var')
    trialMax = 80;
end
if ~exist('loudnessEq', 'var')
    loudnessEq = true;
end

% Workaround for a command window text display bug - too much printing to
% command window results in garbled text, see e.g.
% https://www.mathworks.com/matlabcentral/answers/325214-garbled-output-on-linux
% Calling "clc" from time to time prevents the bug from making everything
% unreadable
clc;

% user message
disp([newline, 'Called function SFGthresholdBackground with inputs: ',...
     newline, 'subNum: ', num2str(subNum),...
     newline, 'number of trials for Quest: ', num2str(trialMax),...
     newline, 'loudness correction flag is set to: ', num2str(loudnessEq),...
     newline, 'stimulus params: ']);
disp(stimopt);
disp([newline, 'TARGET THRESHOLD IS SET TO 75%!']); % TODO make this dynamic from the corresponding variable passed to Quest

% Load experiment params:
paramFunctionName = strcat('experimentParams', group);
expopt = feval(paramFunctionName);

%% Get subject's folder, define output file path

% subject folder name
dirN = ['subject', num2str(subNum)];

if ~exist(dirN, 'dir')
     % create a folder for subject if there was none
    mkdir(dirN);
    disp([newline, 'Created folder for subject at ', dirN]);
end

% check for earlier results from running this function  
backgrResFiles = dir([dirN, '/', 'thresholdBackgroundSL_sub', num2str(subNum), '*']);
% if we found any, report to user and rename/move them
if ~isempty(backgrResFiles)
    disp([newline, 'Found ', num2str(length(backgrResFiles)),... 
        ' results file(s) for subject ', num2str(subNum),... 
        ' from earlier runs of this function']);
    disp('Appending earlier files with a prefix "old_"...');
    for i = 1:length(backgrResFiles)
        % rename files
        src = [backgrResFiles(i).folder, '/', backgrResFiles(i).name];
        dest = [backgrResFiles(i).folder, '/old_', backgrResFiles(i).name];
        success = movefile(src, dest);
        if ~success
            error(['Could not move file ', src, '!']);
        end
    end  % for i
end  % if ~isempty        

% date and time of starting with a subject
c = clock; d = date;
timestamp = {[d, '-', num2str(c(4)), num2str(c(5))]};
% subject log file for training
saveF = [dirN, '/thresholdBackgroundSL_sub', num2str(subNum), '_', timestamp{1}, '.mat'];

disp([newline, 'Got output file path: ', saveF]);


%% Get coherence level 

baseCoherence = expopt.figureCoh;  

% user message
disp(['Coherence level for background-thresholding: ', num2str(baseCoherence)]);


%% Basic settings for Quest

% user message
disp([newline, 'Setting params for Quest and initializing the procedure']);

% log SNR scale of possible stimuli, for Quest
% levels are defined for background tone numbers as
% 1:stimopt.toneComp-stimopt.figCoh
backgroundLevels = stimopt.toneComp-baseCoherence-3:stimopt.toneComp+10;  % HARDCODED MIN AND MAX BACKGROUNDLEVEL
snrLevels = baseCoherence./backgroundLevels;  % broadcasting in Matlab! :)
snrLogLevels = log(snrLevels);

% settings for quest 
qopt = struct;
% -0.61 -> SNR ~0.54
qopt.tGuess = -0.61;  % prior threshold guess, -0.84 equals an SNR of ~0.43 (backgroundlevel=21 at a coherence level of 9 and stimopt.toneComp=20), we start with lot of added noise
qopt.tGuessSd = 5;  % SD of prior guess
qopt.beta = 3.5;  % Weibull steepness, 3.5 is the default used for a wide range of stimuli 
qopt.delta = 0.02;  % ratio of "blind" / "accidental" responses
qopt.gamma = 0.5;  % ratio of correct responses without stimulus present
qopt.grain = 0.001;  % internal table quantization
qopt.range = 7;  % range of possible values

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
qopt.pThreshold = 0.75;  % threshold of interest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create Quest procedure object
q = QuestCreate(qopt.tGuess, qopt.tGuessSd, qopt.pThreshold,... 
    qopt.beta, qopt.delta, qopt.gamma, qopt.grain, qopt.range);

% the first few trials are not used for updating the Quest object (due to
% unfamiliarity with the task in the beginning), we set a variable
% controlling the number of trials to ignore:
qopt.ignoreTrials = 3;  % must be > 0 

% maximum number of extra trials when Quest estimate SD is too large
trialExtraMax = 20;

% target value for QuestSd - the staircase stops if this level is reached
questSDtarget = 1.5*median(abs(diff(snrLogLevels)));

% user message
disp('Done with Quest init');


%% Basic settings for Psychtoolbox & PsychPortAudio

fs = stimopt.sampleFreq;
[pahandle, screenNumber, KbIdxSub, KbIdxExp] = initPTB(fs);

try

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

    setUpKeyRestrictions(keys);

    % Set up display params:
    backGroundColor = [0 0 0];
    textColor = [255 255 255];

    [win, rect, ifi] = setUpAndOpenPTBScreen(screenNumber, backGroundColor);

    fixCrossWin = createFixationCrossOffscreenWindow(win, backGroundColor, textColor, rect);
    qMarkWin = createQuestionMarkOffscreenWindow(win, backGroundColor, textColor, rect);

    % set flag for aborting experiment
    abortFlag = 0;
    % hide mouse
    % HideCursor(screenNumber); % TODO
    % suppress keyboard input to command window
    % ListenChar(-1); % TODO
    % realtime priority
    Priority(1);

    % user message
    disp([newline, 'Initialized psychtoolbox basics, opened window, ',...
        'started PsychPortAudio device']);

    % user message
    disp([newline, 'Psychtoolbox functions, PsychPortAudio prepared']);


    %% Procedure settings

    % user message
    disp([newline, 'Initializing experiment settings...']);

    % vector for trials
    trialType = randi(2,trialMax+trialExtraMax, 1)-1;
    % inter-trial interval, random between 700-1200 ms
    iti = rand([trialMax+trialExtraMax, 1])*0.5+0.7;
    % maximum time for a response, secs
    respInt = 2;
    % stimulus length for sanity checks later
    stimLength = stimopt.totalDur;

    % response variables preallocation
    figDetect = nan(trialMax+trialExtraMax, 1);
    respTime = figDetect;
    acc = figDetect;

    % user message
    disp('Done');


    %% Prepare first stimulus

    % user message
    disp([newline, 'Preparing first stimulus in staircase...']);

    stimopt.figureCoh = baseCoherence;

    TRIAL_TYPE_ASCENDING = 1;
    TRIAL_TYPE_DESCENDING = 0;

    [stimopt, lastIntensity, tTest] = setUpStimOptFromQuest(q, snrLogLevels, backgroundLevels, baseCoherence, trialType, 1, stimopt, TRIAL_TYPE_ASCENDING, TRIAL_TYPE_DESCENDING);

    % generate a stimulus
    % closePTB(screenNumber); % TODO
    [soundOutput, ~, ~] = createSingleSFGstim(stimopt, loudnessEq);

    % fill audio buffer with next stimulus
    buffer = PsychPortAudio('CreateBuffer', [], soundOutput);
    PsychPortAudio('FillBuffer', pahandle, buffer);

    % user message
    disp([newline, 'Done, we are ready to start the staircase for threshold ',... 
        num2str(qopt.pThreshold)]);


    %% Instructions phase

    % instructions text
    instrText = ['Ugyanaz lesz a feladata, mint az előző blokkban. \n\n',...
        'Összesen kb. ', num2str(trialMax+trialExtraMax/2), ' hangmintát fogunk lejátszani Önnek, \n',...
        'a feladat kb. ', num2str(round(trialMax/9)), ' percen át fog tartani.\n\n',...
        'Hangmintában van emelkedő hangsor  -  "', KbName(keys.figAsc), '" billentyű. \n',... 
        'Hangmintában nincs emelkedő hangsor  -  "' ,KbName(keys.figDesc), '" billentyű. \n\n',...
        'Mindig akkor válaszoljon, amikor megjelenik a kérdőjel.\n\n',...
        'Nyomja meg a SPACE billentyűt ha készen áll!'];   

    % write instructions to text
    Screen('FillRect', win, backGroundColor);
    DrawFormattedText(win, instrText, 'center', 'center', textColor);
    Screen('Flip', win);

    % user message
    disp([newline, 'Showing the instructions right now...']);

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

    % user message
    disp([newline, 'Subject signalled she/he is ready, we go ahead with the task']);


    %% Starting staircase - Trial loop

    % blank screen (uniform background) after instructions
    Screen('FillRect', win, backGroundColor);
    Screen('Flip', win);

    % trial loop is a while loop, so we can add trials depending on the level
    % of QuestSd reached
    trialN = 0;  % trial counter
    SDestFlag = 0;  % flag for reaching QuestSd target
    while trialN < trialMax  || (SDestFlag == 0 && trialN < (trialMax+trialExtraMax))
        trialN = trialN + 1;

        % wait for releasing keys before going on
        releaseStart = GetSecs;
        KbReleaseWait([], releaseStart+2);

        % background with fixation cross, get trial start timestamp
        Screen('CopyWindow', fixCrossWin, win);
        Screen('DrawingFinished', win);
        trialStart = Screen('Flip', win);  

        % user message
        disp([newline, 'Starting trial ', num2str(trialN)]);
        if trialType(trialN) == TRIAL_TYPE_ASCENDING
            disp('There is an ascending figure in this trial');
        elseif trialType(trialN) == TRIAL_TYPE_DESCENDING
            disp('There is a descending figure in this trial');
        end 

        % update quest only after the first few trials
        if trialN > qopt.ignoreTrials

            % do not update Quest on a missing response
            if ~isnan(figDetect(trialN-1))
                questResp = figDetect(trialN-1);
                q = QuestUpdate(q, lastIntensity, questResp);
            end

        end

        % prepare next stimulus if not first trial
        if trialN ~= 1    

            [stimopt, lastIntensity, tTest] = setUpStimOptFromQuest(q, snrLogLevels, backgroundLevels, baseCoherence, trialType, trialN, stimopt, TRIAL_TYPE_ASCENDING, TRIAL_TYPE_DESCENDING);

            % user message
            disp(['Number of background tones is set to: ', num2str(stimopt.toneComp-stimopt.figureCoh)]);
            disp(['Coherence level is set to: ', num2str(stimopt.figureCoh)]);

            % create next stimulus and load it into buffer
            [soundOutput, ~, ~] = createSingleSFGstim(stimopt, loudnessEq);
            buffer = PsychPortAudio('CreateBuffer', [], soundOutput);
            PsychPortAudio('FillBuffer', pahandle, buffer);        

        end

        % blocking playback start for precision
        startTime = PsychPortAudio('Start', pahandle, 1, trialStart+iti(trialN), 1);

        % user message
        disp(['Audio started at ', num2str(startTime-trialStart), ' secs after trial start']);
        disp(['(Target ITI was ', num2str(iti(trialN)), ' secs)']);

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
                % if subject responded figure asc/desc
                if find(keyCodeSub) == keys.figAsc
                    figDetect(trialN) = TRIAL_TYPE_ASCENDING;
                    respFlag = 1;
                    break;
                elseif find(keyCodeSub) == keys.figDesc
                    figDetect(trialN) = TRIAL_TYPE_DESCENDING;
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
            closePTB(screenNumber);
            return;
        end        

        if respFlag
            % response time into results variable
            respTime(trialN) = 1000*(respSecs-respStart);

            % accuracy
            if figDetect(trialN)==trialType(trialN)
                acc(trialN) = 1;
            else
                acc(trialN) = 0;
            end    
        end    

        % blank screen (uniform background) after response / end of response
        % interval
        Screen('FillRect', win, backGroundColor);
        Screen('Flip', win);    

        % user messages
        if figDetect(trialN) == TRIAL_TYPE_ASCENDING
            disp('Subject detected an ascending figure');    
        elseif figDetect(trialN) == TRIAL_TYPE_DESCENDING
            disp('Subject detected a descending figure');
        elseif isnan(figDetect(trialN))
            disp('Subject did not respond in time');
        end
        % accuraccy
        if acc(trialN) == 1
            disp('Subject''s response was accurate');
        elseif acc(trialN) == 0
            disp('Subject made an error');
        end
        % response time
        if ~isnan(respTime(trialN))
            disp(['Response time was ', num2str(respTime(trialN)), ' ms']);
        end    

        % get SD of current Quest estimate
        SDest = QuestSd(q);
        if SDest < questSDtarget
            SDestFlag = 1;
        else
            SDestFlag = 0;
        end
        % user message
        disp(['Standard deviation of threshold estimate is ', num2str(SDest),... 
            ', (ideally < ', num2str(questSDtarget), ')']);    

        % save logging/results variable
        save(saveF, 'q', 'respTime', 'figDetect', 'acc', 'trialType',... 
            'trialMax', 'stimopt', 'qopt', 'backgroundLevels', 'snrLogLevels',...
            'snrLevels');

        % user message for adding extra trials if QuestSd did not reach target
        % by trialMax
        if trialN == trialMax && ~SDestFlag
            disp([newline, newline, 'Standard deviation of threshold estimate is too large,',... 
                newline, 'we add extra trials (max ', num2str(trialExtraMax), ' trials) ',... 
                'to derive a more accurate estimate']);
        end

        % wait a bit before next trial
        WaitSecs(0.4);

    end  % trial while loop


    %% Final Quest object update

    % do not update Quest on a missing response
    if ~isnan(figDetect(trialN))
        questResp = figDetect(trialN);
        q = QuestUpdate(q, tTest, questResp);
    end

    % get final background-threshold estimate
    % ask Quest object about optimal log SNR - for setting toneComp
    tTest=QuestMean(q); 
    % find the closest SNR level we have
    [~, closestSnrIdx] = min(abs(snrLogLevels-tTest));
    % update stimopt accordingly - we get the required number of background
    % tones indirectly, via manipulating the total number of tones
    backgroundEst = backgroundLevels(closestSnrIdx); 

    % user message
    disp([newline, 'Final estimate for number of background tones: ', num2str(backgroundEst)]);


    %% Ending

    % user message
    disp([newline, 'The task has ended!!!']);

    % block ending text
    blockEndText = ['Vége a feladatnak! \n\n',...
        'Köszönjük a részvételt!'];       
    % uniform background
    Screen('FillRect', win, backGroundColor);
    % draw block-starting text
    DrawFormattedText(win, blockEndText, 'center', 'center', textColor);  
    Screen('Flip', win);

    % user message about the two types of figure identified in the thresholding
    % blocks
    disp([newline, newline, '%%%%%%  IMPORTANT INFO  %%%%%%']);
    disp('Thresholding results:');
    disp(['"Easy" stimuli: coherence ', num2str(baseCoherence), '; no. of background tones: ', num2str(backgroundEst)]);
    disp(['"Difficult" stimuli: coherence ', num2str(baseCoherence), '; no. of background tones: ', num2str(backgroundEst+expopt.highLowBgCompDiff)]);
    disp(['%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%', newline, newline]);

    % saving results with extra info
    save(saveF, 'q', 'respTime', 'figDetect', 'acc', 'trialType',... 
        'trialMax', 'stimopt', 'qopt', 'backgroundLevels', 'snrLogLevels',...
        'snrLevels', 'backgroundEst');

    % show ending message for a few secs
    WaitSecs(3);

    % cleanup
    disp(' ');
    disp('Got to the end!');
    closePTB(screenNumber);
    
catch e
    closePTB(screenNumber);
    rethrow(e);
end

return









