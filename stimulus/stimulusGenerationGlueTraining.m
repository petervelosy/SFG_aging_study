function stimulusGenerationGlueTraining(varargin)
%% Function glueing stimulus generation steps together for training
%
% USAGE: stimulusGenerationGlueTraining(paramValues=[8, 10, 20; 10, 10, 20; 12, 10, 20;...], trialMax=60; loudnessEq=true)
%
% Our goal is generate training stimuli similar to those used in 
% Toth et al., 2016
% (https://www.sciencedirect.com/science/article/pii/S1053811916303354?via%3Dihub).
% The main difference is that we drop the location manipulation, use a
% fixed number of tone components and a fixed figure duration.
% 
% Current glue script generates "trialMax" training stimuli. Each
% figure type defined by "paramValues" is represented equally in the
% stimulus set and will have a corresponding set of stimuli without figure. 
% E.g., if there are 5 figure types (stimulus types with a figure, that is,
% with figureCoh>0) defined by paramValues and "trialMax" is set to 100, 
% the function generates 10-10 stimuli with figure types defined by 
% paramValues, and 10-10 corresponding stimuli without figure. 
% In other words, half of the trials generated by the function will always 
% contain a figure while the other half will not. 
%
% Input arg "paramValues" manipulates figure coherence, duration and overall
% tone component number (stimopt.figureCoh, stimopt.figureDur and 
% stimopt.toneComp - see SFGparams for stimuli parameter details) 
% over successive calls to createSFGstimuli.m. Sorting stimuli into blocks 
% is not handled by the current function, that task falls to 
% stim2blocksTraining.
%
% The function creates a folder with subfolders for stimulus types, and a
% cell array accumulating all stimuli together, saved out into a 
% "stimArrayTraining*.mat" file
%
% Optional inputs:
% paramValues   - Numeric matrix with three columns. Columns hold arrays
%               for figureCoh, figureDur and toneComp values (see
%               SFGparams.m for details on parameters). Rows must be unique
%               and will correspond to the figure types in the generated
%               set. Defaults to coherence values 8:2:18, while duration
%               and toneComp values are held constant at 10 and 20,
%               respectively.
% trialMax      - Numeric value, one of 12:120. Number of trials to 
%               generate. Must be multiple of size(paramValues, 1)*2. 
%               Defaults to 60.
% loudnessEq    - Logical value. Flag for correcting for the perceived
%               loudness of different frequency components (see equal
%               loudness curves). Defaults to true. Gets passed on to 
%               createSFGstim. 
%               If "true", the necessary gains for the frequencies specified
%               in "stimopt" are derived from the outputs of iso226
%               and are applied to the pure sine components.
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

if ~ismembertol(nargin, 0:3)
    error(['Input arg error! Function stimulusGenerationGlueTraining might ',...
        'take optional input args "paramValues", "trialMax" and "loudnessEq"!']);
end
% check optional input args
if ~isempty(varargin)
    for v = 1:length(varargin)
        if ismatrix(varargin{v}) && size(varargin{v}, 2)==3 &&... 
                size(unique(varargin{v}, 'rows'), 1)==size(varargin{v}, 1)... 
                && ~exist('paramValues', 'var')
            paramValues = varargin{v};
        elseif isnumeric(varargin{v}) && ismembertol(varargin{v}, 12:120) &&...
                mod(varargin{v}, size(paramValues, 1)*2)==0 && ~exist('trialMax', 'var') 
            trialMax = varargin{v};
        elseif islogical(varargin{v}) && numel(varargin{v})==1 && ~exist('loudnessEq', 'var')
            loudnessEq = varargin{v};
        else
            error('At least one input arg could not be matched nicely to "paramValues", "trialMax" or "loudnessEq"!');
        end
    end
end
% assign default values
if ~exist('paramValues', 'var')
    paramValues = [[8:2:18]', ones(6, 1)*10, ones(6, 1)*20];
end
if ~exist('trialMax', 'var')
    trialMax = 60;
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
disp([char(10), 'Called function stimulusGenerationGlueTraining with args: ',... 
    char(10), 'Number of trials to generate: ', num2str(trialMax),...
    char(10), 'loudnessEq is set to: ', num2str(loudnessEq),...
    char(10), 'Figure (stimulus) types in terms of figure coherence, duration and tone component no. (columns): ']);
disp(paramValues);


%% Basic parameters - hardcoded values

% create date and time based ID for current stimulus set
c = clock;  % dir name based on current time
id = strcat(date, '-', num2str(c(4)), num2str(c(5)));
% directory name for stimulus subdirs
stimDirName = ['stimulusTypes-', id];
mkdir(stimDirName);
% file for saving final cell array containing all stimuli
saveF = ['stimArrayTraining-', id, '.mat'];

% figure presence/absence values
figValues = [1 0];
% no. of stimulus types - the rows of paramValues + their no-figure
% coutnerparts
stimTypeNo = size(paramValues, 1)*2;
% cell array holding the subfolder names with different stimulus types
stimTypeDirs = cell(stimTypeNo, 1);
% no. of trials for each stimulus type
trialPerType = trialMax/stimTypeNo;


%% Create stimuli for each stimulus type

% load base params
stimopt = SFGparams();

% counter for stimuli folders created
counter = 1;

% loop over stimulus types
for type = 1:stimTypeNo/2
    
    % change params accordingly
    stimopt.figureCoh = paramValues(type, 1);    
    stimopt.figureDur = paramValues(type, 2);
    stimopt.toneComp = paramValues(type, 3);
    
    % generate stimuli with figure
    stimTypeDirs{counter} = createSFGstimuli(trialPerType, stimopt, loudnessEq);
    
    % update counter
    counter = counter+1;
    
    % set stimoipt to "no figure"
    stimopt.figureCoh = 0;
            
    % generate stimuli without figure
    stimTypeDirs{counter} = createSFGstimuli(trialPerType, stimopt, loudnessEq);  
    
    % update counter
    counter = counter+1;
    
end  % for t

% user message
disp([char(10), 'Generated figure stimuli for all requested parameter values ',...
    'and their without-figure counterparts']);


%% Aggregate stimuli across types
    
stimArray = getStimuliArray(stimTypeDirs);    
% concatenate cell arrays of different stimulus types
stimArray = vertcat(stimArray{:});
    
    
%% Sanity checks - do we have the intended stimuli set?    

% user message
disp([char(10), 'Quick and minimal sanity checks on generated stimuli...']);

% check if we have the expected number of stimuli with requested figure
% coherence values
cohValues = unique(paramValues(:, 1));
cohTypeNo = (stimTypeNo/2*trialPerType)/length(cohValues);
% check if true
cohParams = cell2mat(stimArray(:, 6));
for c = 1:length(cohValues)
    cohValueNo = sum(cohParams == cohValues(c) & cohParams ~= 0);
    if ~isequal(cohValueNo, cohTypeNo)
        error('Not the right number of trials with figure coherence values in resulting stimArray! Needs debugging!');
    end
end 

% check if we have the expected number of stimuli with requested figure
% duration values
durValues = unique(paramValues(:, 2));
durTypeNo = (stimTypeNo/2*trialPerType)/length(durValues);
% check if true
durParams = cell2mat(stimArray(:, 5));
for c = 1:length(durValues)
    durValueNo = sum(durParams == durValues(c) & cohParams ~= 0);
    if ~isequal(durValueNo, durTypeNo)
        error('Not the right number of trials with figure duration values in resulting stimArray! Needs debugging!');
    end
end 

% check if we have the expected number of stimuli with requested tone
% component numbers
toneCompValues = unique(paramValues(:, 3));
toneCompTypeNo = (stimTypeNo/2*trialPerType)/length(toneCompValues);
% check if true
toneCompParams = cell2mat(stimArray(:, 11));
for c = 1:length(toneCompValues)
    toneCompValueNo = sum(toneCompParams == toneCompValues(c) & cohParams ~= 0);
    if ~isequal(toneCompValueNo, toneCompTypeNo)
        error('Not the right number of trials with tone component no. values in resulting stimArray! Needs debugging!');
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
save(saveF, 'stimArray');

% user message
disp([char(10), 'Saved out final stimulus array to ', saveF]);


return

