function [fileList,filesRequired,agency] = checkEphFolderForFiles(timeFrame,folderEph)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function will check in folderEph for SP3 files and try to find match
% in files and days which are required in interval defined by timeFrame
%
% Input:
% timeFrame - [2,3] matrix of [day1Year, day1Month, day1Day;
%                              day2Year, day2Month, day2Day]
% folderEph - absolute or relative path to folder where SP3 files are
%             stored. SP3 files has to have '.sp3' or '.SP3' extension!
%
% Output:
% fileList - cell with filenames which fullfill YearDay or WeekDoy condition.
%          - in case that any file fullfill both conditions, YearDay file
%            is preffered
%
%          YearDay condition: filename contains sprintf('%4d%3d',year,day)
%          WeekDoy condition: filename contains sprintf('%4d%d.',gpsWeek,dow)
% filesRequired - total number of days for which ephemeris are needed
% agency - processing agencies/centers for fileList
%        - information is taken from SP3 file header
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get days for which the data are necessary
[gpsWeek, doy, dow, dt] = getGPSDaysBetween(timeFrame,1);
filesRequired = numel(dt);

% Get list of SP3 files with correct date specifier in name
dirContent = dir(folderEph);
dirContent = struct2cell(dirContent);
dirContent = dirContent(1,:)';

% Condition 1: File is ending with '.sp3' or '.SP3'
fileIsSP3 = cellfun(@(x) ~isempty(regexp(x,'(\.sp3$)|(\.SP3$)','once')),dirContent);
dirContentSP3 = dirContent(fileIsSP3);

fileIsCompliantYearDay = false(numel(dirContentSP3),numel(dt));
fileIsCompliantWeekDoy = false(numel(dirContentSP3),numel(dt));
for i = 1:numel(dirContentSP3)
    for j = 1:numel(dt)
        fileIsCompliantYearDay(i,j) = ~isempty(strfind(dirContentSP3{i},sprintf('%d%03d',year(dt(j)),doy(j))));
        fileIsCompliantWeekDoy(i,j) = ~isempty(strfind(dirContentSP3{i},sprintf('%d%d',gpsWeek(j),dow(j))));
    end
end

% Select only files which fullfill YearDay or WeekDoy condition
fileOKIdx = 1;
fileList = cell(1,1);
for i = 1:numel(dt)
    ix1 = find(fileIsCompliantYearDay(:,i));
    if ~isempty(ix1)
        fileList{fileOKIdx} = dirContentSP3{ix1(1)};
        fileOKIdx = fileOKIdx + 1;
    else
        ix2 = find(fileIsCompliantWeekDoy(:,i));
        if ~isempty(ix2)
            fileList{fileOKIdx} = dirContentSP3{ix2(1)};
            fileOKIdx = fileOKIdx + 1;
        end
    end
end

% Processing center extraction (from SP3 file header's)
if all(cellfun(@(x) ~isempty(x),fileList))
    agency = cell(size(fileList));
    for i = 1:numel(agency)
        sp3header = SP3header(fullfile(folderEph,fileList{i}));
        agency{i} = sp3header.agency;
    end
    
    % raise warning if there are more centers among SP3 files
    if numel(unique(agency)) > 1
        error('\nPrecise ephemeris files in "%s" are from more analysis centers: %s!\nProvide ephemeris only from one analysis center!\n',folderEph,strjoin(unique(agency),', '));
    end
end

