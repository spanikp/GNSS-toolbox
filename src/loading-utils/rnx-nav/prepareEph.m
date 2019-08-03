function navMessageList = prepareEph(gnss,ephType,folderEph,timeFrame)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to download and unzip broadcast/precise ephermeris files for
% given satellite system and given time frame.
%
% Inputs:
% gnss - sat. specifiers ('GREC' or separate 'G','R' ...)
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
% navMessageList - structure with fields of specified GNSS
%                - each field consists of cell of nav. message filenames
%
% Note:
% For unzipping the function uses 7-Zip application, so it is needed to
% install it previously.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for i = 1:numel(gnss)
        s = gnss(i);
        switch ephType
            case 'broadcast'
                navMessageList.(s) = downloadBroadcastData(s,timeFrame,folderEph);
            case 'precise'
                
            otherwise
                fprintf('Only ephType of "broadcast" or "precise" available!\n');
        end
    end
end