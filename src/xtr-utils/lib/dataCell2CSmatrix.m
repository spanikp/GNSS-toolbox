function [timeStamp, CSprns, CScell] = dataCell2CSmatrix(dataCell)

timeStamp = cellfun(@(c) datetime(c(9:27),'InputFormat','yyyy-MM-dd HH:mm:ss'), dataCell);
CSprns = cell2mat(cellfun(@(c) str2num(c(31:32)), dataCell, 'UniformOutput', 0));

CScell = cell(1,32);
uniqueCSsats = unique(CSprns);
for i = 1:numel(uniqueCSsats)
    currentSat = uniqueCSsats(i);
    selSat = CSprns == currentSat;
    CScell{currentSat} = timeStamp(selSat);
end
