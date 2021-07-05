function stimArrayFile = stimulusGenerationGlueSLTraining(varargin)
%% Function glueing stimulus generation steps together for subject-specific stimuli
%
% USAGE: stimArrayFile = stimulusGenerationGlueThresholded(subNum, trialMax=[1/stimType], loudnessEq=true)
%
% Our goal is generate stimuli similar to those used in Toth et al., 2016
% (https://www.sciencedirect.com/science/article/pii/S1053811916303354?via%3Dihub).
% The main difference is that we drop the location manipulation and stimuli
% are generated based on earlier, subject-specific thresholding blocks. 
% These blocks specify a "normal" and an "easy" stimulus type, defined in
% terms of coherence level and number of background tones. The values used
% are loaded from the output files generated by SFGthresholdCoherence and
% SFGthresholdBackground.
% 
% Mandatory input:
% subNum            - Numeric value, one of 1:999. Subject number.
%
% Optional inputs:
% trialMax          - Numeric value, one of 12:1200. Number of trials to 
%                   generate. Must be a multiple of stimulus types that
%                   exist.
% loudnessEq        - Logical value. Flag for correcting for the perceived
%                   loudness of different frequency components (see equal
%                   loudness curves). Defaults to true. Gets passed on to 
%                   createSFGstimuliInDir. 
%                   If "true", the necessary gains for the frequencies specified
%                   in "stimopt" are derived from the outputs of iso226
%                   and are applied to the pure sine components.
%
% Output:
% stimArrayFile     - Char array, path for the file containing all stimuli
%                   and their main features. Serves as input for SFGmain.
%
% The script creates a folder with subfolders for stimulus types, and a
% cell array accumulating all stimuli together, saved out into a 
% "stimArray*.mat" file
%
% NOTES:
% (1) The script relies on the following functions:
% SFGparams         - base parameter settings
% createSFGstimuliInDir  - create stimuli for specific parameters
% getStimuliArray   - aggregate stimuli from multiple runs of
%                   createSFGstimuliInDir
% (2) Make sure SFGparams contains the right base parameters. While
% generating stimuli, we only change the coherence and onset values
% across runs of createSFGstimuliInDir, the rest is taken from SFGparams.m.  
%


%% Input checks

% check optional args
if ~isempty(varargin)
    for v = 1:length(varargin)
        if isnumeric(varargin{v}) && ismembertol(varargin{v}, 12:5000) && mod(varargin{v}, 4)==0 && ~exist('trialMax', 'var') 
            trialMax = varargin{v};
        elseif islogical(varargin{v}) && numel(varargin{v})==1 && ~exist('loudnessEq', 'var')
            loudnessEq = varargin{v};
        else
            error('At least one input arg could not be matched nicely to "trialMax" or "loudnessEq"!');
        end
    end
end
% assign default values
if ~exist('loudnessEq', 'var')
    loudnessEq = true;
end


%% Check for subject-level directory, load results from SFGthreshold* functions

% subject folder name
subDirName = 'trainingStimuli';

% check if subject folder already exists, complain if not
if ~exist(subDirName, 'dir')
    mkdir(subDirName);
end

% Load experiment params (choose the params which are the easiest to detect):
paramFunctionName = 'experimentParamsElderlyHI';
expopt = feval(paramFunctionName);

% coherence and background values to be used throughout all trials
baseCoherence = expopt.figureCoh;
backgroundVal = 20-baseCoherence;

%% Basic parameters - hardcoded values

% create date and time based ID for current stimulus set
c = clock;  % dir name based on current time
id = strcat(date, '-', num2str(c(4)), num2str(c(5)));
% directory name for stimulus subdirs
stimDirName = [subDirName, '/stimulusTypes-', id];
mkdir(stimDirName);
% file for saving final cell array containing all stimuli
stimArrayFile = [subDirName, '/stimArray-', id, '.mat'];
% file for saving experiment options
expoptFile = [subDirName, '/expopt-', id, '.mat'];

% step size adjustment values
stepSizes = expopt.stepSizeMin:expopt.stepSizeStep:expopt.stepSizeMax;
stepSizes = stepSizes(stepSizes~=0);

% no. of stimulus types
stimTypeNo = numel(stepSizes)*2;

% no. of trials for each stimulus type
if ~exist('trialMax', 'var')
    trialMax = stimTypeNo;
    trialPerType = 1;
else
    trialPerType = trialMax/stimTypeNo;
end

% cell array holding the subfolder names with different stimulus types
stimTypeDirs = cell(stimTypeNo, 1);

% Workaround for a command window text display bug - too much printing to
% command window results in garbled text, see e.g.
% https://www.mathworks.com/matlabcentral/answers/325214-garbled-output-on-linux
% Calling "clc" from time to time prevents the bug from making everything
% unreadable
clc;

% user message
disp([newline, 'Called the stimulusGenerationGlueSLTraining script, ',... 
    'main params:', ...
    newline, 'Requested number of trials: ', num2str(trialMax),...
    newline, 'loudnessEq is set to: ', num2str(loudnessEq),...
    newline, 'Figure coherence value: ', num2str(baseCoherence),...
    newline, 'Background tone count: ', num2str(backgroundVal)]);


%% Create stimuli for each type

% load base params
stimopt = SFGparams();

% change coherence level
stimopt.figureCoh = baseCoherence;
stimopt.toneComp = backgroundVal + baseCoherence;

% counter for stimuli folders created
counter = 1;   

% directions (ascending, descending)
directions = [1, -1];

% loop over step sizes
for s = stepSizes

    % loop over directions (ascending/descending)
    for d = directions

        stimopt.figureStepS = s * d;

        dirname = strcat('coh', num2str(baseCoherence), 'bg', num2str(backgroundVal), 'step', num2str(stimopt.figureStepS));
        mkdir(dirname);

        % generate stimuli
        stimTypeDirs{counter} = createSFGstimuliInDir(trialPerType, stimopt, dirname, loudnessEq);

        % adjust counter
        counter = counter+1;

    end % for d

end % for s

% user message
disp([newline, 'Generated stimuli for all requested parameter values']);


%% Aggregate stimuli across types
    
stimArray = getStimuliArray(stimTypeDirs);    
% concatenate cell arrays of different stimulus types
stimArray = vertcat(stimArray{:});
    
    
%% Sanity checks - do we have the intended stimuli set?    

% user message
disp([newline, 'Quick and minimal sanity checks on generated stimuli...']);

% intended number of trials with each of step sizes
stepTypeNo = (stimTypeNo*trialPerType)/length(stepSizes);
% check if true
figParams = cell2mat(stimArray(:, 7));
for s = 1:length(stepSizes)
    stepValueNo = sum(ismember(figParams, stepSizes(s))) * 2;
    if ~isequal(stepValueNo, stepTypeNo)
        error('Not the right number of trials with step size values in resulting stimArray! Needs debugging!');
    end
end
% same as above but for background tone numbers
backgrTypeNo = (stimTypeNo*trialPerType);
% check if true
toneCompParams = cell2mat(stimArray(:, 11));
backgrValueNo = sum(toneCompParams == (backgroundVal+baseCoherence));
if ~isequal(backgrValueNo, backgrTypeNo)
    error('Not the right number of trials with figure duration values in resulting stimArray! Needs debugging!');
end
   
% user message
disp('Found no obvious errors with the generated stimulus set with regards to requested parameters');
    

%% Move around dirs, save out final stimulus cell array

% move the subfolders with stimulus type files under a common stimulus
% folder
for d = 1:length(stimTypeDirs)
    movefile(stimTypeDirs{d}, [stimDirName, '/', stimTypeDirs{d}]);
end

% save out stimArray
save(stimArrayFile, 'stimArray', '-v7.3');

% save out expopt
save(expoptFile, 'expopt', '-v7.3');

% user message
disp([newline, 'Saved out final stimulus array to ', stimArrayFile]);


return

