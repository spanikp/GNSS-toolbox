function [timeStamp, meanVal, dataMatrix] = dataCell2matrix(dataCell)

timeStamp = cellfun(@(c) datetime(c(9:27),'InputFormat','yyyy-MM-dd HH:mm:ss'), dataCell);
data = cell2mat(cellfun(@(c) str2num(strrep([c(28:end),' '],'- ','0 ')), dataCell, 'UniformOutput', 0));
data(data == 0) = nan;
meanVal = data(:,1);
dataMatrix = data(:,2:end);