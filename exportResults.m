function exportResults

    subjectDirRegex = 'subject(\d+)';

    results = {'subject_id', 'session', 'stepsize_block1', 'stepsize_block2', 'stepsize_block3', 'stepsize_block4', 'stepsize_mean'};
    
    logVarColBlockId = 2;
    logVarColStepSize = 7;

    blockTrialCount = 100;

    sessions = ["pretest", "training1", "training2", "posttest"];

    dirContents = dir;
    for i = 1:size(dirContents, 1)
        entry = dirContents(i);
        [match, tokens] = regexp(entry.name, subjectDirRegex, 'match', 'tokens');
        if isfolder(entry.name) && ~isempty(match)
            subjectId = str2double(cell2mat(tokens{1}));
            for session = sessions
                fileName = strcat('sub', num2str(subjectId), '_', session, 'Log.mat');
                filePath = strcat(entry.name, filesep, fileName);

                if ~exist(filePath, 'file')
                    fprintf('File %s does not exist\n', filePath)
                else
                    load(filePath, 'logVar');
        
                    row = {subjectId, session, NaN, NaN, NaN, NaN, NaN};
        
                    for blockIx = 1:4
                        rowIxs = cell2mat(logVar(2:end,logVarColBlockId)) == blockIx;
                        blockLog = logVar(rowIxs, :);
                        blockStr = strcat(num2str(subjectId), '_', session, '_', num2str(blockIx));
                        disp(strcat("Processing ", blockStr));
                        if length(blockLog) < blockTrialCount
                            disp('Block incomplete, skipping')
                        else
                            blockStartStepSize = abs(cell2mat(blockLog(2, logVarColStepSize)));
                            blockEndStepSize = abs(cell2mat(blockLog(end, logVarColStepSize)));  % actual block end
                            %blockEndStepSize = min(abs(cell2mat(blockLog(2:end, logVarColStepSize)))); % block minimum
                            if blockStartStepSize <= blockEndStepSize
                                fprintf("Subject did not understand the task in %s. Dropping block.", blockStr);
                            else
                                row{2+blockIx} = blockEndStepSize;
                            end
                        end
                    end

                    row{7} = mean([row{3}, row{4}, row{5}, row{6}], 'omitnan');

                    results(end+1, :) = row;
                end
            end
        end
    end

    resultFile = strcat('stats', filesep', 'results.csv');
    writecell(results, resultFile);
    fprintf("Results saved to %s\n", resultFile);
end