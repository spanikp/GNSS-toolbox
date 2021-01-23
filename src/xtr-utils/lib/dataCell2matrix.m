function [timeStamp, meanVal, dataMatrix] = dataCell2matrix(dataCell)

for i = 1:length(dataCell)
    timeStamp(i,1) = datetime(dataCell{i}(9:27),'InputFormat','yyyy-MM-dd HH:mm:ss');
end
data = cell2mat(cellfun(@(c) str2num(strrep([c(28:end),' '],'- ','0 ')),dataCell,'UniformOutput',false));
data(data == 0) = nan;
meanVal = data(:,1);
dataMatrix = data(:,2:end);