SUBJECT_ID=int
DEV_MODE=bool
GROUP='Young', 'Elderly', 'ElderlyHI'

SFGintro(SUBJECT_ID)
SFGIntroTrainingSL(SUBJECT_ID, DEV_MODE)
SFGthresholdBackgroundSL(SUBJECT_ID, GROUP)
stimulusGenerationGlueSL(SUBJECT_ID)

------------------------------------

SFGmainSupervisedLearning(1, false, DEVMODE, 'no') - teszt 
SFGmainSupervisedLearning(1, true, DEVMODE, 'no') - training with feedback