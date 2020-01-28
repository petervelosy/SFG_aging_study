# SFG_aging_study
Matlab code for the ongoing research project _**Testing aging deficits in auditory object perception**_ 
<br></br>
## On SFG
SFG stands for Stochastic Figure-Ground, a stimulus type used in auditory research that combines sets of randomly selected tones from a broad frequency range (*Background*) with short sequences of repeated tones (*Figure*). The latter is regularly perceived as an auditory object, that is, as a sound source separate from the background. 

For more on the SFG please see (among others):  
- [Teki et al., 2011. Brain bases for auditory stimulus-driven figure–ground segregation](https://www.jneurosci.org/content/jneuro/31/1/164.full.pdf)  
- [O'Sullivan et al., 2015. Evidence for neural computations of temporal coherence in an auditory scene and their enhancement during active listening](https://www.jneurosci.org/content/jneuro/35/18/7256.full.pdf)
- [Tóth et al., 2016. EEG signatures accompanying auditory figure-ground segregation](https://europepmc.org/article/PMC/5656226)
<br></br>
## Dependencies / environment
The study relies on [Psychtoolbox](https://psychtoolbox.org/) under Ubuntu 18.04 for stimulus generation/presentation. While Psychtoolbox is compatible with Octave, development is for Matlab (2017a) and Octave compatibility is not tested. In principle though, adapting the functions to Octave should be simple.   
<br></br>
## Usage
Functions in `/stimulus` are used for stimulus generation:  
- **stimulusGenerationGlue.m** - Glueing script for generating full stimulus ensemble for an experiment, needs to be edited for use case in question  
- **SFGparams.m** - Basic parameters for stimuli generation
- **createSFGstimuli.m** - Generates given number of stimuli for specific parameters
- **getStimuliArray.m** - Aggregates stimulus (sub)sets into full ensemble
- **plotChords.m** - Diagnostic and visualization tool: plot the chords defining a given stimulus next to its spectrogram
- **getEnDiff.m** - Diagnostic tool testing for putative mean acoustic energy differences between two stimuli (sub)sets

Functions in `/presentation` for stimulus presentation and recording responses:
<br></br>
## Citation
Code is free to all (MIT license) but please cite earlier work by the group:

Tóth, Brigitta, Zsuzsanna Kocsis, Gábor P. Háden, Ágnes Szerafin, Barbara G. Shinn-Cunningham, and István Winkler. "EEG signatures accompanying auditory figure-ground segregation." Neuroimage 141 (2016): 108-119. https://doi.org/10.1016/j.neuroimage.2016.07.028

