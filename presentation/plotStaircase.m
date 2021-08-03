function plotStaircase(subjectNr, fileNameSuffix, mode)
    if ~exist('fileNameSuffix', 'var')
        fileNameSuffix = '';
    end
    if ~exist('mode', 'var') || ~ismember(mode, {'all', 'snr-contrast'})
        mode = 'all';
    end
    subjectStr = num2str(subjectNr);
    logFileName = strcat('subject', subjectStr, filesep, 'sub', subjectStr, 'Log', fileNameSuffix, '.mat');
    load(logFileName, 'logVar');
    yticks(0:1:10);
    logNoHeader = logVar(2:end, :);
    blockNumbers = cell2mat(logNoHeader(:,2));
    blockNumberList = unique(blockNumbers);
    
    if strcmp(mode, 'all')
        seriesTitles = cell2mat(arrayfun(@(x) sprintf('Block %s', num2str(x)), blockNumberList, 'uniformoutput',false));
        lineWidth = length(blockNumberList);
    else
        lineWidth = 1;
    end
    

    
    toneCompValues = cell2mat(logVar(2:end,5));
    lowSnrToneComp = max(toneCompValues);
    highSnrToneComp = min(toneCompValues);
    
    for block = blockNumberList'
       blockLog=logNoHeader(blockNumbers == block, :);
        switch mode
            case 'all'
                plot(abs(cell2mat(blockLog(:, 7))), 'LineWidth', lineWidth);
                hold on;
                % Decrementing the line width so that overlapping lines stay visible
                lineWidth = lineWidth - 1;
            case 'snr-contrast'
                figure(block);
                blockLogHighSnr = blockLog(cell2mat(blockLog(:,5))==highSnrToneComp, :);
                blockLogLowSnr = blockLog(cell2mat(blockLog(:,5))==lowSnrToneComp, :);
                plot(abs(cell2mat(blockLogHighSnr(:, 7))), 'LineWidth', lineWidth);
                hold on;
                plot(abs(cell2mat(blockLogLowSnr(:, 7))), 'LineWidth', lineWidth);
                title(sprintf('SFG learning staircase for subject %s, block %d', subjectStr, block));
                xlabel('Trial');
                ylabel('Step size');
                seriesTitles = strings(2,1);
                seriesTitles(1) = 'High SNR';
                seriesTitles(2) = 'Low SNR';
                legend(seriesTitles);
                
                meanAccuracyHigh = mean(cell2mat(blockLogHighSnr(:, 10)),'omitnan');
                meanAccuracyLow = mean(cell2mat(blockLogLowSnr(:, 10)),'omitnan');
                fprintf('Mean accuracy (high SNR, block %d): %f', block, meanAccuracyHigh);
                fprintf('Mean accuracy (low SNR, block %d): %f', block, meanAccuracyLow);
        end
    end
    if strcmp(mode, 'all')
        title(sprintf('SFG learning staircase for subject %s', subjectStr));
        xlabel('Trial');
        ylabel('Step size');
        legend(seriesTitles);
    end
end