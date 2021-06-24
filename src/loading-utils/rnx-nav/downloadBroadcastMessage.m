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
gnss_abbrev = containers.Map({'G','R','E','C'},{'n','g','l','c'});

% Setting  of individual servers according to satellite system:
% GR - using IGS CDDIS server - filename is RINEX v2
% EC - using IGS BKG server - filename is RINEX v3
switch satsys
    case 'G'
        % Using CDDIS -> needs to be fixed due to transition to HTTPS
        %servername = 'cddis.gsfc.nasa.gov';
        %path = ['gps/data/daily/', yyyy, '/', doy, '/', yy, 'n'];
        %filename = ['brdc', doy, '0.', yy, 'n.Z'];
        
        % Alternatively use BKG FTP server
        servername = 'igs.bkg.bund.de';
        path = ['EUREF/BRDC/', yyyy, '/', doy, '/'];
        filename = ['BRDC00WRD_R_', yyyy, doy, '0000_01D_GN.rnx.gz'];
    case 'R'
        % Using CDDIS -> needs to be fixed due to transition to HTTPS
        %servername = 'cddis.gsfc.nasa.gov';
        %path = ['gps/data/daily/', yyyy, '/', doy, '/', yy, 'g'];
        %filename = ['brdc', doy, '0.', yy, 'g.Z'];
        
        % Alternatively use BKG FTP server
        servername = 'igs.bkg.bund.de';
        path = ['EUREF/BRDC/', yyyy, '/', doy, '/'];
        filename = ['BRDC00WRD_R_', yyyy, doy, '0000_01D_RN.rnx.gz'];
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
fprintf(' -> %s [downloading]\n', filename);

% Try another approach (download file from IGS BKG https server via websave
try
    fileURL = ['https://',servername,'/root_ftp/',path,filename];
    websave(filename,fileURL);
catch
    warning(sprintf('Download method websave from HTTP IGS BKG server failed!\nFile "%s" not accessible!',filename));
    try
        filenameAltV2 = ['brdc',doy,'0.',yy,gnss_abbrev(satsys),'.Z'];
        fileURL = ['https://',servername,'/root_ftp/',path,filenameAltV2];
        websave(filename,fileURL);
    catch
        warning(sprintf('Download method websave from HTTP IGS BKG server failed!\nFile "%s" not accessible!',filenameAltV2));
    end
end

% Rename navigation message file
gnssExtension = containers.Map({'G','R','E','C'},{'n','g','l','c'});
filenamev2 = sprintf('brdc%s0.%s%s.gz',doy,yy,gnssExtension(satsys));
fprintf('    Renaming archive: %s -> %s\n',filename,filenamev2);
movefile(filename,filenamev2);

% Extract downloaded archive with broadcast ephemeris file
if extract
    fprintf('[extract]\n');
    gunzip(filenamev2,'tmp');
    if exist('tmp','dir')
        f = dir('tmp');
        f = f(arrayfun(@(x) isfile(fullfile('tmp',x.name)),f));
        assert(length(f)==1,'At this stage there should be only one file in "Tmp" folder!');
        movefile(fullfile('tmp',f.name),strrep(filenamev2,'.gz',''));
        rmdir tmp s;
    end
    
    % Remove original navigation message
    delete(filenamev2)
end

cd(currentFolder);
