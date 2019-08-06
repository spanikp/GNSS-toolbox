function eph = mergeSP3(ephFolder, ephList)

for i = 1:numel(ephList)
    filename = fullfile(ephFolder,ephList);
    sp3(i) = loadSP3(filename);
end

