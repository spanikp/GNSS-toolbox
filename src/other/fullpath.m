function fullFolderPath = fullpath(folderPath)
    fp = what(folderPath);
    if isempty(fp)
        mkdir(folderPath)
        fp = what(folderPath);
    end
    fullFolderPath = fp.path;