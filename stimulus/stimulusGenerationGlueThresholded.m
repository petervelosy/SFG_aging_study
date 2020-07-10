function stimArrayFile = stimulusGenerationGlueThresholded(subNum, trialMax)
%% Script glueing stimulus generation functions together for our use case
%
% USAGE: stimArrayFile = stimulusGenerationGlueThresholded(subNum, trialMax=800)
%
% Our goal is generate stimuli similar to those used in Toth et al., 2016
% (https://www.sciencedirect.com/science/article/pii/S1053811916303354?via%3Dihub).
% The difference is that we drop the location manipulation and stimuli are
% generated based on earlier, subject-specific thresholding blocks. These
% blocks specify a "normal" and an "easy" stimulus type, defined in terms
% of coherence level and number of background tones. The values used are
% loaded from the output files generated by SFGthresholdCoherence and
% SFGthresholdBackground.
% 
% Mandatory input:
% subNum            - Numeric value, one of 1:999. Subject number.
%
% Optional input:
% trialMax          - Numeric value, one of 12:1200. Number of trials to 
%                   generate. Defaults to 800.
%
% Output:
% stimArrayFile     - String, path for the file containing all stimuli and
%                   their main features. Serves as input for SFGmain.m
%
% The script creates a folder with subfolders for stimulus types, and a
% cell array accumulating all stimuli together, saved out into a .mat file
%
% The script relies on the following functions:
% SFGparams         - base parameter settings
% createSFGstimuli  - create stimuli for specific parameters
% getStimuliArray   - aggregate stimuli from multiple runs of
%                   createSFGstimuli
%
% NOTE:
% (1) Make sure SFGparams contains the right base parameters. While
% generating stimuli, we only change the coherence and toneComp values
% across runs of createSFGstimuli, the rest is taken from SFGparams.m. 
%


%% Input checks

if ~ismembertol(nargin, 1:2)
    error('Function "stimulusGenerationGlueThresholded" requires input arg "subNum" while input arg "trialNo" is optional!');
end
if nargin == 1
    trialMax = 800;
end
if ~ismembertol(subNum, 1:999)
    error('Input arg "subNum" should be one of 1:999!');
end
if ~ismembertol(trialMax, 12:1200)
    error('Input arg "trialNo" should be one of 12:1200!');
end
if mod(trialMax, 4) ~= 0
    error('Input arg "trialNo" must be multiple of four!');
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
trialNo = trialMax/stimTypeNo;

% cell array holding the subfolder names with different stimulus types
stimTypeDirs = cell(stimTypeNo, 1);

% user message
disp([char(10), 'Called the stimulusGenerationGlueThresholded script, ',... 
    'main params:', ...
    char(10), 'Subject number: ', num2str(subNum),...
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
        stimTypeDirs{counter} = createSFGstimuli(trialNo, stimopt);
        
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
figTypeNo = (stimTypeNo*trialNo)/length(figValues);
% check if true
figParams = (cell2mat(stimArray(:, 6))~=0);
for f = 1:length(figValues)
    figValueNo = sum(ismember(figParams, figValues(f)));
    if ~isequal(figValueNo, figTypeNo)
        error('Not the right number of trials with figure presence/absence values in resulting stimArray! Needs debugging!');
    end
end
% same as above but for background tone numbers
backgrTypeNo = (stimTypeNo*trialNo)/length(backgrValues);
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

