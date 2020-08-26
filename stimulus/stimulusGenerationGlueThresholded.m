function stimArrayFile = stimulusGenerationGlueThresholded(subNum, varargin)
%% Function glueing stimulus generation steps together for subject-specific stimuli
%
% USAGE: stimArrayFile = stimulusGenerationGlueThresholded(subNum, trialMax=800, loudnessEq=true)
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
%                   generate. Must be multiple of four. Defaults to 800.
% loudnessEq        - Logical value. Flag for correcting for the perceived
%                   loudness of different frequency components (see equal
%                   loudness curves). Defaults to true. Gets passed on to 
%                   createSFGstimuli. 
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
% createSFGstimuli  - create stimuli for specific parameters
% getStimuliArray   - aggregate stimuli from multiple runs of
%                   createSFGstimuli
% (2) Make sure SFGparams contains the right base parameters. While
% generating stimuli, we only change the coherence and onset values
% across runs of createSFGstimuli, the rest is taken from SFGparams.m.  
%


%% Input checks

% check number of args
if ~ismembertol(nargin, 1:3)
    error(['Function "stimulusGenerationGlueThresholded" requires input arg "subNum" ',...
        'while input args "trialMax" and "loudnessEq" are optional!']);
end
% check mandatory arg
if ~ismembertol(subNum, 1:999)
    error('Input arg "subNum" should be one of 1:999!');
end
% check optional args
if ~isempty(varargin)
    for v = 1:length(varargin)
        if isnumeric(varargin{v}) && ismembertol(varargin{v}, 12:1200) && mod(varargin{v}, 4)==0 && ~exist('trialMax', 'var') 
            trialMax = varargin{v};
        elseif islogical(varargin{v}) && numel(varargin{v})==1 && ~exist('loudnessEq', 'var')
            loudnessEq = varargin{v};
        else
            error('At least one input arg could not be matched nicely to "trialMax" or "loudnessEq"!');
        end
    end
end
% assign default values
if ~exist('trialMax', 'var')
    trialMax = 800;
end
if ~exist('loudnessEq', 'var')
    loudnessEq = true;
end


%% Check for subject-level directory, load results from SFGthreshold* functions

% subject folder name
subDirName = ['subject', num2str(subNum)];

% check if subject folder already exists, complain if not
if ~exist(subDirName, 'dir')
    error(['Could not find subject''s folder at ', subDirName, '!']);
end

% get file name for SFGthresholdCoherence results - exact file name contains unknown time stamp
cohResFile = dir([subDirName, '/thresholdCoherence_sub', num2str(subNum), '*.mat']);
cohResFilePath = [cohResFile.folder, '/', cohResFile.name];
% load results from coherence-thresholding
cohRes = load(cohResFilePath);

% get file name for SFGthresholdBackground results - exact file name contains unknown time stamp
backgrResFile = dir([subDirName, '/thresholdBackground_sub', num2str(subNum), '*.mat']);
backgrResFilePath = [backgrResFile.folder, '/', backgrResFile.name];
% load results from background-thresholding
backgrRes = load(backgrResFilePath);

% coherence value to be used throughout all trials
baseCoherence = cohRes.coherenceEst;
% background values for normal and easy trials
stdBackgr = cohRes.stimopt.toneComp-baseCoherence;
lowBackgr = backgrRes.backgroundEst;
backgrValues = [stdBackgr, lowBackgr];


%% Basic parameters - hardcoded values

% create date and time based ID for current stimulus set
c = clock;  % dir name based on current time
id = strcat(date, '-', num2str(c(4)), num2str(c(5)));
% directory name for stimulus subdirs
stimDirName = [subDirName, '/stimulusTypes-', id];
mkdir(stimDirName);
% file for saving final cell array containing all stimuli
stimArrayFile = [subDirName, '/stimArray-', id, '.mat'];

% figure presence/absence values
figValues = [1 0];

% no. of stimulus types
stimTypeNo = numel(backgrValues)*numel(figValues);

% no. of trials for each stimulus type
trialPerType = trialMax/stimTypeNo;

% cell array holding the subfolder names with different stimulus types
stimTypeDirs = cell(stimTypeNo, 1);

% Workaround for a command window text display bug - too much printing to
% command window results in garbled text, see e.g.
% https://www.mathworks.com/matlabcentral/answers/325214-garbled-output-on-linux
% Calling "clc" from time to time prevents the bug from making everything
% unreadable
clc;

% user message
disp([char(10), 'Called the stimulusGenerationGlueThresholded script, ',... 
    'main params:', ...
    char(10), 'Subject number: ', num2str(subNum),...
    char(10), 'Requested number of trials: ', num2str(trialMax),...
    char(10), 'loudnessEq is set to: ', num2str(loudnessEq),...
    char(10), 'Figure coherence value: ', num2str(baseCoherence),...
    char(10), 'Background tone numbers: ', num2str(backgrValues),...);
    char(10), 'Figure presence/absence: ']);
disp(figValues);


%% Create stimuli for each type

% load base params
stimopt = SFGparams();

% change coherence level
stimopt.figureCoh = baseCoherence;

% counter for stimuli folders created
counter = 1;

% loop over figure presence/absence values
for f = 1:length(figValues)
    
    % figPresent is fed to createSFGparams indirectly, via figureCoh
    if figValues(f) == 1
        stimopt.figureCoh = baseCoherence;
    elseif figValues(f) == 0
        stimopt.figureCoh = 0;
    end        
    
    % loop over background tone numbers
    for b = 1:length(backgrValues)
        % change params accordingly
        stimopt.toneComp = backgrValues(b) + baseCoherence;
        
        % generate stimuli
        stimTypeDirs{counter} = createSFGstimuli(trialPerType, stimopt, loudnessEq);
        
        % adjust counter
        counter = counter+1;
        
    end  % for b
    
end  % for f

% user message
disp([char(10), 'Generated stimuli for all requested parameter values']);


%% Aggregate stimuli across types
    
stimArray = getStimuliArray(stimTypeDirs);    
% concatenate cell arrays of different stimulus types
stimArray = vertcat(stimArray{:});
    
    
%% Sanity checks - do we have the intended stimuli set?    

% user message
disp([char(10), 'Quick and minimal sanity checks on generated stimuli...']);

% intended number of trials with each of figValues
figTypeNo = (stimTypeNo*trialPerType)/length(figValues);
% check if true
figParams = (cell2mat(stimArray(:, 6))~=0);
for f = 1:length(figValues)
    figValueNo = sum(ismember(figParams, figValues(f)));
    if ~isequal(figValueNo, figTypeNo)
        error('Not the right number of trials with figure presence/absence values in resulting stimArray! Needs debugging!');
    end
end
% same as above but for background tone numbers
backgrTypeNo = (stimTypeNo*trialPerType)/length(backgrValues);
% check if true
toneCompParams = cell2mat(stimArray(:, 11));
for b = 1:length(backgrValues)
    backgrValueNo = sum(toneCompParams == (backgrValues(b)+baseCoherence));
    if ~isequal(backgrValueNo, backgrTypeNo)
        error('Not the right number of trials with figure duration values in resulting stimArray! Needs debugging!');
    end
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
save(stimArrayFile, 'stimArray');

% user message
disp([char(10), 'Saved out final stimulus array to ', stimArrayFile]);


return

