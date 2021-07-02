function [stimopt, lastIntensity, tTest] = setUpStimOptFromQuest(q, snrLogLevels, backgroundLevels, baseCoherence, trialType, trialIx, stimopt, TRIAL_TYPE_ASCENDING, TRIAL_TYPE_DESCENDING)
    if trialType(trialIx) == TRIAL_TYPE_ASCENDING  
        stimopt.figureStepS = 50;
    elseif trialType(trialIx) == TRIAL_TYPE_DESCENDING  
        stimopt.figureStepS = -50;
    end

    % stimopt.toneComp is adjusted according to Quest:

    % ask Quest object about optimal log SNR - for setting toneComp
    tTest=QuestMean(q); 
    % find the closest SNR level we have
    [~, closestSnrIdx] = min(abs(snrLogLevels-tTest));
    % get corresponding intensity (log SNR) - will be used for Quest update
    lastIntensity = snrLogLevels(closestSnrIdx);
    % update stimopt accordingly - we get the required number of background
    % tones indirectly, via manipulating the total number of tones
    stimopt.toneComp = backgroundLevels(closestSnrIdx)+baseCoherence;
end