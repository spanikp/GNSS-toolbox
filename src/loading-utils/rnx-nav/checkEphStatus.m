function brdcChecked = checkEphStatus(brdc)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to chceck uniquity of records in brdc.eph cell. There is chance
% that some satellites have more identical records for one moment. This is
% mainly case of GALILEO and BEIDOU, less often GPS or GLONASS. Function
% also make filtering base on SV Health status (row 18 for GLONASS and row
% 36 for GPS/GALILEO/BEIDOU). If satellite is set unhealthy (value ~= 0)
% then this record is skipped.
%
% Function will list a table with the following content:
%
% +-------+--------+-------+------+-----------+---------+-------+--------+
% |  sat  | before | after | diff | unhealthy | bad DOY | other |  perc  |
% +-------+--------+-------+------+-----------+---------+-------+--------+
% |  G03  |     36 |    36 |    0 |         0 |       0 |     0 |    0%  |
% |  G04  |     37 |    11 |   26 |        26 |       0 |     0 |   70%  |
% +-------+--------+-------+------+-----------+---------+-------+--------+
%
% Where: sat        - satellite identifier
%        before     - number of ephemeris block before filtering
%        after      - number of ephemeris blocks after filtering
%        diff       - befor - after
%        unhealthy  - number of eph. blocks with bad SV Health (removed)
%        bad DOY    - doy in eph. block is not the same as the name of file
%        other      - duplicity of eph. block (e.g. Galileo has one block
%                     of ephemeris reported more times for each channel
%                     separately, but value of kepl. elements are the same)
%        perc       - percentage of removed eph. blocks
%
% Input:  brdc - structure containing broadcast ephemeris
%                (output of "loadRINEXNavigation.m")
%
% Output: brdcChecked - cell structure containing filtered values of brdc.eph
%                Unhealthy broadcast blocks are removed and there are no two
%                blocks with identical time (in some cases this happens in
%                raw broadcast messages).
%
% Peter Spanik, 10.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Print info
fprintf('\n>>> Filtering loaded data >>>\n')

% Make copy of brdc
brdcChecked = brdc;

% Find health index according to satellite system
satsys = brdc.gnss;
if strcmp(satsys,'R')
    healthIndex = 18;
else
    healthIndex = 36;
end

% Get DOY information from filenames
filenamesDoys = cellfun(@(x) str2double(x(5:7)),brdc.files);
filenamesDoys = [min(filenamesDoys)-1; filenamesDoys];
filenamesYears = cellfun(@(x) str2double(x(10:11)),brdc.files) + 2000;

% Initialize output cell
out = cell(size(brdc.eph));

% Looping throught satellites
fprintf('Filtering results (perc - ratio of remove ephemeris blocks):\n')
fprintf('+-------+--------+-------+------+-----------+---------+-------+--------+\n');
fprintf('|  sat  | before | after | diff | unhealthy | bad DOY | other |  perc  |\n');
fprintf('+-------+--------+-------+------+-----------+---------+-------+--------+\n');
for i = 1:length(brdc.eph)
    
    sat = brdc.sat(i);
    frame = brdc.eph{i};
    frameCorrected = frame;
    
    % Health information check
    selBad = frame(healthIndex,:) ~= 0;
    if strcmp(satsys,'E')
        if sat == 14 || sat == 18
            selBad = true(size(selBad));
        end
    else
        frameCorrected = frameCorrected(:,~selBad);
    end

    % Check if info from filename corresponds to info in data
    doyMatch = ismember(frameCorrected(9,:),filenamesDoys);
    yearMatch = ismember(frameCorrected(1,:),filenamesYears);
    filenameMatch = doyMatch & yearMatch;
    frameCorrected = frameCorrected(:,filenameMatch);
    
    % Check of unique whole ephemeris blocks
    [~, uniqueFrameIdx] = unique(frameCorrected','rows');
    uniqueFrameIdx = uniqueFrameIdx';
    frameCorrected = frameCorrected(:,uniqueFrameIdx);

    % Check of time uniquity
    [~, uniqueTimeIdx] = unique(frameCorrected(11,:));
    %satMessage = horzcat(satMessage, sprintf('     unique time       -> %.0f/%.0f\n\n',length(uniqueTime),size(frameCorrected,2)));
    frameCorrected = frameCorrected(:,uniqueTimeIdx);
    
    % % Make report if times are not unique
    % if length(uniqueTime) < size(frameCorrected,2)
    %     fprintf(satMessage);
    % end
    
    sizeBefore = size(frame,2);
    sizeAfter  = size(frameCorrected,2);
    d = sizeBefore-sizeAfter;
    if strcmp(satsys,'E') && (sat == 14 || sat == 18)
        fprintf('|  %s%02d* |%7d |%6d |%5d |%10d*|%8d |%6d | %4.0f%%  |\n',satsys,sat,sizeBefore,sizeAfter,d,sum(selBad),sum(~filenameMatch),d-sum(selBad)-sum(~filenameMatch),(d/sizeBefore)*100);
    else
        fprintf('|  %s%02d  |%7d |%6d |%5d |%10d |%8d |%6d | %4.0f%%  |\n',satsys,sat,sizeBefore,sizeAfter,d,sum(selBad),sum(~filenameMatch),d-sum(selBad)-sum(~filenameMatch),(d/sizeBefore)*100);
    end
    out{i} = frameCorrected;
end

fprintf('+-------+--------+-------+------+-----------+---------+-------+--------+\n');

% Save results to brdcChecked
brdcChecked.eph = out;

% Check if there are some epmty cells and remove them
emptySats = cellfun(@(x) isempty(x), out);
if any(emptySats)
    remSats = brdcChecked.sat(emptySats);
    fprintf('Removed satellites: %s.\n',strjoin(arrayfun(@(x) sprintf('%s%02d',brdc.gnss,x),remSats,'UniformOutput',false),', '))
    brdcChecked.sat(emptySats) = [];
    brdcChecked.eph(emptySats) = [];
end

fprintf('Filtering done!\n')
