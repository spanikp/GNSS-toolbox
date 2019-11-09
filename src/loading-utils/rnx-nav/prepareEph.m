function fileList = prepareEph(gnss,ephType,folderEph,timeFrame)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to download and unzip broadcast/precise ephermeris files for
% given satellite system and given time frame.
%
% Inputs:
% gnss - sat. specifier ('G', 'R', 'E' or 'C')
% ephType - 'broadcast' or 'precise' for more info see downloadBroadcastMessage.m
% folderEph - folder where ephemeris files will be stored (does not need to exist)
% timeFrame - [2 x 3] time frame info from which to download data
%           - to avoid problems with data extrapolation the actual time
%             span is extended by +- 1 day
%           - time span has following format:
%             [year1, month1, day1;
%              year2, month2, day2]
%
% Output:
% fileList - structure with fields of navigation/ephemeris file
%
% Note:
% For unzipping the function uses 7-Zip application, so it is needed to
% install it previously.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch ephType
    case 'broadcast'
        fileList = downloadBroadcastData(gnss,timeFrame,folderEph);
    case 'precise'
        % Check if for all required days there are files in folderEph, if not
        % then precise data for CODE center will be downloaded
        [fileList,filesRequired] = checkEphFolderForFiles(timeFrame,folderEph);
        if numel(fileList) < filesRequired
            % Function will download precise ephemeris from CDDIS MGEX for CODE analysis center
            fileList = downloadPreciseData(timeFrame,folderEph,'COD');
        end
    otherwise
        fileList = {''};
        fprintf('Only ephType "broadcast" or "precise" available!\n');
end