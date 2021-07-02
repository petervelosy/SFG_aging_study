function dirName = makeUniqueDirectory(dirName)
    % Add a suffix if a directory with this name already exists:
    dircount = 0;
    while exist(dirName, 'dir')
        dircount = dircount + 1;
        if dircount > 1
            dirName = strsplit(dirName, '_');
            dirName = dirName{1};
        end
        dirName = strcat(dirName, '_', num2str(dircount));
    end
    mkdir(dirName);
end