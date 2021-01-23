function [timeStamp, CSprns, CScell] = dataCell2CSmatrix(dataCell)

for i = 1:length(dataCell)
    timeStamp(i,1) = datetime(dataCell{i}(9:27),'InputFormat','yyyy-MM-dd HH:mm:ss');
end
CSprns = cell2mat(cellfun(@(c) str2num(c(31:32)), dataCell, 'UniformOutput', 0));

CScell = cell(1,32);
uniqueCSsats = unique(CSprns);
for i = 1:numel(uniqueCSsats)
    currentSat = uniqueCSsats(i);
    selSat = CSprns == currentSat;
    CScell{currentSat} = timeStamp(selSat);
end
