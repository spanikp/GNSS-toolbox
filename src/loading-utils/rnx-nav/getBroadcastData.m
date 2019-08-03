function brdc = getBroadcastData(satsys, time_frame)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to load navigation messages of GPS, GLONASS, GALILEO or
% BEIDOU navigation system for given time frame. No previous action needed!
% Program download data from the internet.
%
% Function need a directory brdc where navigation messages are stored. If 
% the folder does not exist, program will create empty folder and download
% broadcast navigation files from internet.
% 
% In case you want to use your own files it is possible, but:
%
% * files have to be in the same format, otherwise only files with format 
%   as first file (with first doy) will be used. 
%   
%   E.g. in brdc folder are 3 files: brdc1160.18n (v2)
%                                    brdc1170.18n (v3)
%                                    brdc1180.18n (v2)
%
%   -> only files brdc1160.18n and brdc1180.18n will be merged and used!
%
% * files have to be stored in brdc folder with proper name: 
%   brdcDOY0.YYT, where:
% 
%     DOY - doy number of file (in case that navigation message span over
%           more doys create copy of particular file for all days (e.g.
%           nav. message 1234005.18n span from doy 5 - 7, then it is
%           neccesary to have 3 copies of this file with the names: 
% 
%           1234005.18n -> copy ->  brdc005.18n, brdc006.18n, brdc007.18n
%
%           If the files will have different names, program will ignore them
%           and downloads files from internet and will work with them!
%
%     YY  - last two digits of the year
%
%     T   - character for GNSS recognition ("n" - GPS, "g" - GLONASS, 
%           "l" - GALILEO, "c" - BEIDOU)
%
% Input: satsys - character defining GNSS ('GREC')
%        time_frame - first and last moment you want to load data
%
%        time_frame = [2017, 12, 30,    <- function handle year shifts
%                      2018,  1,  4];    
%
% Output: brdc - structure with the fields:
%          .hdr - header structure of first file (mandatory field is
%                 information about version brdc.hdr.version = 2 or 3)
%          .sat - [1 x n] - satellites which have information
%
% Usage: getBroadcastMessage('C', [2017,12,30; 2018,1,4])
%        -> in brdc folder will be: brdc3640.17c, brdc3650.17c,
%                                   brdc0010.17c, brdc0020.18c,
%                                   brdc0030.17c, brdc0030.18c,
%
% Dependecies: checkEphStatus.m
%              checkFileExistence.m
%              downloadBroadcastMessage.m
%              getNavigationHeader.m
%              mergeBroadcastMessages.m
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Extent input time_frame by one day
t = datetime(time_frame) + [-day(1); day(1)];
time_frame = datevec(t);
time_frame = time_frame(:,1:6);

% Time conversions
mTime      = datenum(time_frame(1,:)):1:datenum(time_frame(2,:));
dt         = datetime(mTime,'ConvertFrom','datenum');
doy        = day(dt,'DayOfYear');

% Check if last day is after first day
if isempty(doy)
    fprintf('Wrong input date: [first moment; last moment] !\n')
    brdc = [];
    return
end

% Chceck upper limit of time_frame
if mTime(end) > now()
    fprintf('Wrong input date: Last moment is in the future !\n')
    brdc = [];
    return
end

% Check existence of brdc folder and list its content (list only files)
if ~(exist('brdc','dir') == 7)
    fprintf('Creating directory: brdc\n');
    mkdir('brdc');
    list = {};
else
    list = dir('brdc');
    list(1:2) = [];
    list = {list.name};
    if isempty(list)
        list = {};
    else
        list(~cellfun(@(x) contains(x,'.'), list)) = [];
    end
end

% Create base for filenames (last character missing)
filenames = cell(1,length(doy));
for i = 1:length(doy)
    filenames{i} = ['brdc', sprintf('%03d0.%s',doy(i),datestr(mTime(i),'yy'))];
end

% Adding last character according to satellite system
switch satsys
    case 'G'
        filenames = cellfun(@(x) [x, 'n'], filenames, 'UniformOutput', false);
    case 'R'
        filenames = cellfun(@(x) [x, 'g'], filenames, 'UniformOutput', false);
    case 'E'
        filenames = cellfun(@(x) [x, 'l'], filenames, 'UniformOutput', false);
    case 'C'
        filenames = cellfun(@(x) [x, 'c'], filenames, 'UniformOutput', false); 
end

% Filter files to get list only non-existed files in brdc folder
neededFiles = filenames;
selection = ~checkFileExistence(filenames,list);
filenames = filenames(selection);
mTime = mTime(selection);

% Downloading files one by one -> if filenames is empty list no downloading
% neccessarry. 
for i = 1:length(filenames)
    if i == 1
        fprintf('\n>>> Downloading files >>>\n');
    end
    downloadBroadcastMessage(satsys, mTime(i), 'brdc');
end

% Load RINEX message to Matlab
brdc = loadRINEXNavigation(satsys,neededFiles);

% Check ephemeris for duplicity
brdc = checkEphStatus(brdc);
