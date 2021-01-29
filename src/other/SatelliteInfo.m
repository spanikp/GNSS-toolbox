classdef SatelliteInfo
    properties
        satInfoTable
    end
    properties (Access = private)
        satInfoFile
        satInfoLocalFolder
    end
    methods
        function obj = SatelliteInfo()
            % Set location where satellite info file should be stored
            obj.satInfoLocalFolder = fileparts(mfilename('fullpath'));
            obj.satInfoFile = 'SATELLIT.I14';
            
            % Download info file if not exist or update if older than 1 day
            obj.updateInfoFileIfNeeded();
            
            % Parse satellite info file
            obj = obj.parseSatteliteInfoFile();
        end
        function satsBlock = getSatelliteBlock(obj,satsNo,gnss,t)
            validateattributes(satsNo,{'double'},{'size',[1,nan]},1);
            validateattributes(gnss,{'char'},{'size',[1,1]},2);
            validateattributes(t,{'datetime'},{'size',[1,1]},3);
            
            assert(any(gnss == 'GREC'),'Satellite system has to be one of: GREC!');
            assert(t<=datetime('now'),'Cannot get satellite block number for future!');
            
            satsBlock = nan(size(satsNo));
            for i = 1:length(satsNo)
                selSatNo = obj.satInfoTable.PRN == satsNo(i);
                selGnss = strcmp(obj.satInfoTable.GNSS,gnss);
                selTime = t >= obj.satInfoTable.START_TIME & t <= obj.satInfoTable.END_TIME;
                selAllCriteria = selSatNo & selGnss & selTime;
                
                switch nnz(selAllCriteria)
                    case 0
                        warning('Not found matching block number for %s%02d!',gnss,satsNo(i));
                    case 1
                        satsBlock(i) = obj.satInfoTable.BLOCK(selAllCriteria);
                    otherwise
                        sat_block_unique = unique(obj.satInfoTable.BLOCK(selAllCriteria));
                        if length(sat_block_unique) == 1
                            satsBlock(i) = sat_block_unique;
                        else
                            error('Satellite block number not unique for %s%02d!',gnss,satsNo(i));
                        end
                end
            end
        end
    end
    methods (Access = private)
        function downloadSatteliteInfoFile(obj)
            warning('Satellite info file "%s" will be downloaded!',obj.satInfoFile);
            remoteFileURL = ['http://ftp.aiub.unibe.ch/BSWUSER52/GEN/',obj.satInfoFile];
            try
                websave(fullfile(obj.satInfoLocalFolder,obj.satInfoFile),remoteFileURL);
            catch
                error('Satellite info file "%s" cannot be downloaded! Download file manually and place it to: "%s"',...
                    obj.satInfoFile,obj.satInfoLocalFolder);
            end
            
            % % mget method (Matlab FTP connection) - old
            % serverURL = 'ftp.aiub.unibe.ch';
            % serverPath = 'BSWUSER52/GEN';
            % try
            %     % Open FTP server connection and change to directory
            %     server = ftp(serverURL);
            %     cd(server,serverPath);
            %     mget(server,obj.satInfoFile);
            %     if ~strcmp(pwd(),obj.satInfoLocalFolder)
            %         movefile(fullfile(pwd(),obj.satInfoFile),fullfile(obj.satInfoLocalFolder,obj.satInfoFile));
            %     end
            %     fprintf('File "%s" downloaded successfully!\n',obj.satInfoFile);
            %     return
            % catch
            %     warning('Download failed via "mget" method!');
            % end
            
            % % curl command (call system command)
            % curlDownload(fullfile(serverURL,serverPath,obj.satInfoFile),fullfile(obj.satInfoLocalFolder,obj.satInfoFile));
        end
        function updateInfoFileIfNeeded(obj)
            if exist(fullfile(obj.satInfoLocalFolder,obj.satInfoFile),'file')
                f = dir(fullfile(obj.satInfoLocalFolder,obj.satInfoFile));
                t0 = datetime('now');
                % Fetch file if it older than 1 day
                if f.date < datetime([t0.Year,t0.Month,t0.Day])
                    obj.downloadSatteliteInfoFile();
                end
            else
                obj.downloadSatteliteInfoFile();
            end
        end
        function obj = parseSatteliteInfoFile(obj)
            raw_txt = readlines(fullfile(obj.satInfoLocalFolder,obj.satInfoFile));
            idxRawSelect = nan(1,2);
            for i = 1:2
                tmp = find(cellfun(@(x) contains(x,sprintf('PART %d',i)),raw_txt));
                idxRawSelect(i) = tmp(1);
            end
            txt = raw_txt(idxRawSelect(1)+8:idxRawSelect(2)-3);

            satInfo = struct('PRN',[],'SVN',[],'BLOCK',[],'COSPAR_ID',[],...
                'ATTITUDE_FLAG',[],'START_TIME',[],'END_TIME',[],'MASS',[]);
            for i = 1:length(txt)
                s = txt{i};
                satInfo(i).PRN = sscanf(s(1:3),'%f');
                satInfo(i).SVN = sscanf(s(6:8),'%f');
                satInfo(i).BLOCK = sscanf(s(10:12),'%f');
                satInfo(i).COSPAR_ID = sscanf(s(16:24),'%s');
                satInfo(i).ATTITUDE_FLAG = sscanf(s(29:30),'%f');
                t1 = sscanf(s(36:54),'%f');
                t2 = sscanf(s(57:75),'%f');
                if isempty(t1)
                    error('Incorrect file format! Cannot be empty string for START TIME!');
                else
                    satInfo(i).START_TIME = datetime(t1');
                end
                if isempty(t2)
                    t0 = datetime('now');
                    satInfo(i).END_TIME = datetime([t0.Year,t0.Month,t0.Day]) + day(1);
                else
                    satInfo(i).END_TIME = datetime(t2');
                end 
                satInfo(i).MASS = sscanf(s(80:85),'%f');
            end

            infoTable = struct2table(satInfo);
            for i = 1:length(infoTable.PRN)
                prn = infoTable.PRN(i);
                if prn < 100
                    infoTable.GNSS{i} = 'G';
                elseif prn >= 100 && prn < 200
                    infoTable.GNSS{i} = 'R';
                elseif prn >= 200 && prn < 300
                    infoTable.GNSS{i} = 'E';
                end     
            end
            obj.satInfoTable = infoTable;
            obj = obj.fixPRNs();
        end
        function obj = fixPRNs(obj)
            for i = 1:length(obj.satInfoTable.PRN)
                gnss = obj.satInfoTable.GNSS{i};
                if isempty(gnss)
                    obj.satInfoTable.PRN(i) = nan;
                else
                    switch gnss
                        case 'R'
                            obj.satInfoTable.PRN(i) = obj.satInfoTable.PRN(i) - 100;
                        case 'E'
                            obj.satInfoTable.PRN(i) = obj.satInfoTable.PRN(i) - 200;
                    end
                end
            end
        end
    end
end