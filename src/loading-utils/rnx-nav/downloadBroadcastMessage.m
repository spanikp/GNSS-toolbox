function downloadBroadcastMessage(satsys, mTime, folderPath,extract)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to download navigation message of GPS, GLONASS, GALILEO or
% BEIDOU navigation system. There are used different archives to download
% GPS and GLONASS (IGS CDDIS server) and GALILEO and BEIDOU (IGS BKG
% server). Downloaded files may be in RINEX v2 or v3, but always will have
% RINEX v2 filename, e.g. "brdc1160.17l".
%
% Input: satsys - character defining GNSS ('GREC')
%        mTime - Matlab datenum date (not vector)
%        folderPath - path to folder where files should be stored
%        extract - true/false switch if the data should be unzipped by 7z
%
% Output: downloaded and extracted files
%
% Usage: downloadBroadcastMessage('C', datenum([2017 1 5]), 'brdc')
%
% Peter Spanik, 9.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get defaults
if nargin == 3
	extract = true;
end

% Change directory to destination folder
currentFolder = pwd();
cd(folderPath)

% Convert nums to strings
dt = datetime(mTime,'ConvertFrom','datenum');
doy = sprintf('%03d',day(dt,'DayOfYear'));
yyyy = datestr(mTime,'yyyy');
yy = datestr(mTime,'yy');

% Setting  of individual servers according to satellite system:
% GR - using IGS CDDIS server - filename is RINEX v2
% EC - using IGS BKG server - filename is RINEX v3
switch satsys
    case 'G'
        servername = 'cddis.gsfc.nasa.gov';
        path = ['gps/data/daily/', yyyy, '/', doy, '/', yy, 'n'];
        filename = ['brdc', doy, '0.', yy, 'n.Z'];
    case 'R'
        servername = 'cddis.gsfc.nasa.gov';
        path = ['gps/data/daily/', yyyy, '/', doy, '/', yy, 'g'];
        filename = ['brdc', doy, '0.', yy, 'g.Z'];
    case 'E'
        servername = 'igs.bkg.bund.de';
        path = ['EUREF/BRDC/', yyyy, '/', doy, '/'];
        filename = ['BRDC00WRD_R_', yyyy, doy, '0000_01D_EN.rnx.gz'];
    case 'C'
        servername = 'igs.bkg.bund.de';
        path = ['EUREF/BRDC/', yyyy, '/', doy, '/'];
        filename = ['BRDC00WRD_R_', yyyy, doy, '0000_01D_CN.rnx.gz'];
    otherwise
        fprintf('Error: %s is not supported GNSS identifier (use one of "GREC")\n', satsys);
        return
end

% Downloading file
fprintf(' -> %s [downloading]', filename);
try 
    % Default method using Matlab mget function
    server = ftp(servername);    % Open FTP server
    cd(server, path);            % Change directory at FTP server
    sf = struct(server);
    sf.jobject.enterLocalPassiveMode();             %% This line is needed in my case due to the issue with passive Matlab connection (https://undocumentedmatlab.com/blog/solving-an-mput-ftp-hang-problem) 
    
    mget(server,filename);       % Download file
catch        
    fprintf('\nWarning:          Matlab mget method for file %s failed.\n', filename);
    try
        % Alternative method using Matlab websave function
        link = ['ftp://', servername, '/', path, '/', filename];
        websave(link, name);
    catch        
        fprintf('Warning:          Matlab urlwrite method for file %s failed.\n', filename);
        error('Error:            File %s not downloaded!\n', filename);
    end
end

% extract file
if extract
	[status, cmdout] = system('7z --help');
	if ~isempty(strfind(cmdout,'not recognized as an internal or external command'))
		cd(currentFolder);
		error('\n7-Zip application not found!\nPlease install before continue or provide unzipped navigation messages.\nLink to download: https://www.7-zip.org/download.html');
	else
        fprintf('[extract]\n');
        % unix(['gzip -d -f ', filename]); % If gzip is installed
        system(['7z e ', filename]);       % If 7z is installed
        
        % Rename navigation message of EC systems
        if contains('EC',satsys)
            if satsys == 'E'
                filenamev2 = ['brdc', doy, '0.', yy, 'l'];
            else
                filenamev2 = ['brdc', doy, '0.', yy, 'c'];
            end
            fprintf('Renaming file:    %s -> %s\n', filename(1:end-3), filenamev2);
            movefile(filename(1:end-3),filenamev2);
        end
	end
end

cd(currentFolder);
