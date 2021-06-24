function neededFiles = downloadPreciseData(timeFrame,folderEph,center)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to download precise ephemeris data from CDDIS FTP:
% FTP link: ftp://cddis.gsfc.nasa.gov/pub/gps/products/mgex
%
% Input (mandatory):
% timeFrame - [2x3] matrix which define start/stop moment for data download
%           - example: [2019 05 18; 2019 05 23];
% 
% Input (optional):
% folderEph - folder where files will be stored and unpacked
%           - default: './eph'
% center - center from which ephemeris will be downloaded
%        - default: 'COD'
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
validateattributes(timeFrame,{'double'},{'size',[2,3]},1);
if nargin == 1
   folderEph = 'eph';
   center = 'COD';
end
if nargin == 2
    center = 'COD';
end
validateattributes(folderEph,{'char'},{'size',[1,NaN]});
validateattributes(center,{'char'},{'size',[1,NaN]});
validatestring(center,{'COD'});

% Handle existence of folderEph
mkdir(folderEph);
currentFolder = pwd();
cd(folderEph)

% Extent input timeFrame by one day
[gpsWeek,doy,~,dt] = getGPSDaysBetween(timeFrame,1);

% Check if last day is after first day
if isempty(doy)
    fprintf('Wrong input date: [first moment; last moment] !\n')
    neededFiles = {''};
    return
end

% Check upper limit of timeFrame
if datenum([timeFrame(2,1:2), timeFrame(2,3)+1]) > floor(now())
    fprintf('Wrong input date: Last moment is in the future !\n')
    neededFiles = {''};
    return
end

% Cell of needed files
neededFiles = cell(numel(doy),1);
for i = 1:numel(doy)
    neededFiles{i,1} = [center '0MGXFIN_' sprintf('%d%03d',year(dt(i)),doy(i)) '0000_01D_05M_ORB.SP3'];
end
dirContent = dir();
dirContent = struct2cell(dirContent);
dirContent = dirContent(1,:);
filesToDownload = setdiff(neededFiles,dirContent);

% Downloading files one by one
servername = 'cddis.gsfc.nasa.gov';
for i = 1:numel(filesToDownload)
    if i == 1
        fprintf('\n>>> Downloading files >>>\n');
    end
    filename = [center '0MGXFIN_' sprintf('%d%03d',year(dt(i)),doy(i)) '0000_01D_05M_ORB.SP3'];
    
    if ismember(filename,filesToDownload)
        path = ['pub/gps/products/mgex/', num2str(gpsWeek(i)), '/'];
        % Downloading file
        fprintf(' -> %s [downloading]', filename);
        try
            % Default method using Matlab mget function
            server = ftp(servername);    % Open FTP server
            cd(server, path);            % Change directory at FTP server
            %sf = struct(server);
            % The following line is needed in my case due to the issue with passive Matlab connection (https://undocumentedmatlab.com/blog/solving-an-mput-ftp-hang-problem)
            %sf.jobject.enterLocalPassiveMode();
        
            mget(server,[filename '.gz']);       % Download file
            fprintf(' [done]\n');
        catch
            fprintf('\nWarning:          Matlab mget method for file %s failed.\n', filename);
            try
                % Alternative method using Matlab websave function
                link = ['ftp://', servername, '/', path, '/', filename];
                websave(link, [filename '.gz']);
                fprintf(' [done]\n');
            catch
                fprintf('Warning:          Matlab urlwrite method for file %s failed.\n', filename);
                cd(currentFolder);
                error('Error:            File %s not downloaded!\n', filename);
            end
        end
    else
        fprintf(' -> %s [exist in folder]', filename);
        cd(currentFolder)
        return
    end

    % Extract file
	[~, cmdout] = system('7z --help');
	if contains(cmdout,'not recognized as an internal or external command')
		cd(currentFolder);
		error('\n7-Zip application not found!\nPlease install before continue or provide unzipped navigation messages.\nLink to download: https://www.7-zip.org/download.html');
	else
        fprintf('[extract]\n');
        % unix(['gzip -d -f ', filename]); % If gzip is installed
        system(['7z e ', filename '.gz']);       % If 7z is installed
        
        % Remove original navigation message
        delete([filename '.gz'])
	end
end
cd(currentFolder)
