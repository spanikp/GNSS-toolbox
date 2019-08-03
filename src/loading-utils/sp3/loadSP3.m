function sp3 = loadSP3(filename)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to read content of SP3 file.
% 
% Input:  filename - input file string 
% Output: sp3 - structure with the following fields:
%          .gnss - satellite system identifiers
%          .t - [epochs x 9] array of time moments with following content:
%           [year, month, day, hour, minute, second, GPSWeek, GPSSecond, mTime]
%
%          .sat.(gnss) - [1 x n] array of PRN numbers
%          .satpos.(gnss) - [n x 4] array of [X, Y, Z, dT]
%
% Author: Peter Spanik, 22.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Opening file
finp = fopen(filename,'r');
raw = textscan(finp,'%s','Delimiter','\n','Whitespace', '');
raw = raw{1};
fclose(finp);

% Skip header
lindex = 0;
systems = '';
while 1
    lindex = lindex + 1;
    line = raw{lindex};
    if strcmp(line(1),'+')
        systems = [systems, line];
    end
    
    if strcmp(line(1),'*')
        break; 
     end
end

% Find out number of epochs in file
raw = raw(lindex:end);
selEpochs = cellfun(@(x) strcmp(x(1),'*'),raw);
ymdhms = cell2mat(cellfun(@(x) sscanf(x(2:end),'%f')', raw(selEpochs),'UniformOutput',false));
[gpsweek, tow, ~, ~] = greg2gps(ymdhms);
sp3.t = [ymdhms, gpsweek, tow, datenum(ymdhms)];

% Allocate structure fields for different systems
gnss = unique(systems(regexp(systems,'[A-Z]')));
sp3.gnss = gnss;
for i = 1:length(gnss)
    sp3.satpos.(gnss(i)) = cell(1,32);
    sp3.satpos.(gnss(i))(:) = {zeros(size(sp3.t,1),4)};
end

% Looping through the file
idxEpoch = 0;
for i = 1:length(raw)
    if contains(raw{i},'EOF')
        break; 
    end
    
    line = raw{i};
    if strcmp(line(1),'*')
        idxEpoch = idxEpoch + 1;
    else
        prn = sscanf(line(3:4),'%f');
        xyzc = sscanf(line(5:60),'%f')';
        xyzc(:,1:3) = xyzc(:,1:3)*1000;
        sp3.satpos.(line(2)){prn}(idxEpoch,:) = xyzc;
    end
end

% Remove cells without records
allSats = 1:32;
for i = 1:length(gnss)
    satSel = cellfun(@(x) sum(sum(x))~=0, sp3.satpos.(gnss(i)));
    sp3.sat.(gnss(i)) = allSats(satSel);
	sp3.satpos.(gnss(i))(~satSel) = [];
end

