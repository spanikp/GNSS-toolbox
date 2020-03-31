classdef OBSRNX
	properties
        % header is OBSRNXheader object
		header
        
        % path is rel/abs to folder where input RINEX file is stored
        path (1,:) char
        
        % filename is file in RINEX v3 format which stores GNSS observations 
        filename (1,:) char
        
        % gnss specify sat system (one of 'GREC')
        gnss (1,:) char
        
        % t gives moments of observation in GPS time system
        % t = [year,month,day,hour,minute,second,GPSWeek,GPSSecond,datenum]
        t (:,9) double
        
        % epochFlags is struct which summarize epoch status
        % struct is loaded from flags given for every epoch in RINEX files
        % (for many static RINEX files this flags are empty)
        epochFlags (1,1) struct = struct('OK',[],'PowerFailure',[],'StartMovingAntenna',[],...
                                         'NewStationOccupation',[],'HeaderInfo',[],...
                                         'ExternalEvent',[],'CycleSlipRecord',[]);
        
        % recClockOffset is given for every observation epoch
        % (for many static files this value is not set)
        recClockOffset (:,1) double
        
        % recpos - receiver position
        % Any update of this property will trigger recalculation of
        % satellites positions stored in satpos(i).local
        recpos (1,3) double 
        
        % obs is struct which stores observations for all GNSS given is
        % gnss property. Rows of obs.(gnss) are epochs defined in t, columns
        % are observation types stored in struct header.obsTypes. If sat was
        % not measured in given epoch, zero value is stored in matrix.
        obs
        
        % obsqi s struct for quality index of observation given in obs
        % (loaded from RINEX v3, many of obs quality indices are empty)
        % By default this is empty - will not be loaded during RINEX read
        % use param.parseQualityIndicator = true to read these values
        obsqi
        
        % satTimeFlags is struct with matrices representing satellite/epochs
        % in which given sat has at least one available observation:
        % - rows represents epochs (specified in gpstime)
        % - columns represents sats according satList array
        satTimeFlags
        
        % sat is struct with array of observed satellites
        sat
        
        % satblock represents sat block (like for GPS-IIM, GPS-IIF, ...
        satblock
        
        % satpos is array of SATPOS objects
		satpos (1,:) SATPOS
	end
	
	methods
		function obj = OBSRNX(filepath,param)
            if nargin == 1
				param = OBSRNX.getDefaults();
            end
            tic
            hdr = OBSRNXheader(filepath);
            validateattributes(hdr,{'OBSRNXheader'},{})
            param = OBSRNX.checkParamInput(param);
            if ~strcmp(hdr.marker.type,'GEODETIC')
                warning('Input RINEX marker type differs from "GEODETIC" or does not contain "MARKER TYPE" record. RINEX may contain kinematic records for which this reader was not programmed and can fail!');
                answer = input('Do you wish to continue? [Y/N] > ','s');
                if ~strcmpi(answer,'y') && ~strcmpi(answer,'yes')
                    return
                end
            end
            obj.header = hdr;
            warning('off');
            obj.recpos = hdr.approxPos;
            warning('on');
            obj.path = obj.header.path;
            obj.filename = obj.header.filename;
            obj = obj.loadRNXobservation(param);
            tReading = toc;
            fprintf('Elapsed time reading RINEX file "%s": %.4f seconds.\n',obj.filename,tReading);
        end
        function obj = loadRNXobservation(obj,param)
            % Check if there is something to read
            obj.gnss = intersect(obj.header.gnss,param.filtergnss);
            if ~isempty(obj.gnss)
                % Reading raw RINEX data using textscan
                absfilepath = fullfile(obj.header.path, obj.header.filename);
                fprintf('\nReading content of RINEX: %s\n',absfilepath)
                finp = fopen(absfilepath,'r');
                fileBuffer = textscan(finp, '%s', 'Delimiter', '\n', 'whitespace', '');
                fileBuffer = fileBuffer{1};
                fclose(finp);
                
                % Copy body part to new structure
                bodyBuffer = fileBuffer(obj.header.headerSize+1:end);
                clear fileBuffer;
                obj.obs = struct();
                
                % Find epoch identifiers (slow performance on big files)
                %timeSelection = cellfun(@(x) strcmp(x(1),'>'),bodyBuffer);
                %epochRecords = cell2mat(cellfun(@(x) sscanf(x,'> %f %f %f %f %f %f %f %f')',...
                %   bodyBuffer(timeSelection),'UniformOutput',false));
                
                
                % Find epoch identifiers (faster version)
                tic
                fprintf('Resolving measurement''s epochs ')
                tmp = char(bodyBuffer);
                timeSelection = tmp(:,1) == '>';
                %epochStringArray = string(tmp(timeSelection,3:29));
                %edt = datetime(epochStringArray,'InputFormat','yyyy MM dd HH mm ss.sssss');
                epochRecords = zeros(nnz(timeSelection),8);
                %epochRecords(:,1:6) = [edt.Year, edt.Month, edt.Day, edt.Hour, edt.Minute, edt.Second];
                epochRecords(:,1) = str2doubleq(cellstr(tmp(timeSelection,3:6)));
                epochRecords(:,2) = str2doubleq(cellstr(tmp(timeSelection,8:9)));
                epochRecords(:,3) = str2doubleq(cellstr(tmp(timeSelection,11:12)));
                epochRecords(:,4) = str2doubleq(cellstr(tmp(timeSelection,14:15)));
                epochRecords(:,5) = str2doubleq(cellstr(tmp(timeSelection,17:18)));
                epochRecords(:,6) = str2doubleq(cellstr(tmp(timeSelection,20:29)));
                epochRecords(:,7) = str2doubleq(cellstr(tmp(timeSelection,32)));
                epochRecords(:,8) = str2doubleq(cellstr(tmp(timeSelection,33:35)));
                epochRecords = real(epochRecords);
                fprintf('[done]\n');
                
                % Decimate epochRecords by param.samplingDecimation factor
                totalEpochsInRINEX = size(epochRecords,1);
                epochAllIdxs = find(timeSelection);
                linesToRead = [];
                for i = 1:param.samplingDecimation:size(epochRecords,1)
                    linesToRead = [linesToRead; (epochAllIdxs(i):epochAllIdxs(i)+epochRecords(i,8))'];
                end
                
                % Remove lines from buffer and epochRecords
                epochRecords = epochRecords(1:param.samplingDecimation:end,:);
                bodyBuffer = bodyBuffer(linesToRead);
                clear timeSelection;
                
                % Resolving epoch flags
                % For details see (RINEX 3.04, GNSS Observation Data File - Data Record Description)
                % 0 - OK
                % 1 - Power failure
                % 2 - StartMovingAntenna
                % 3 - NewStationOccupation
                % 4 - HeaderInfo
                % 5 - ExternalEvent
                % 6 - CycleSlipRecord

                epochRecordsNumber = epochRecords(:,8);
                epochFlagNames = {'OK', 'PowerFailure', 'StartMovingAntenna', 'NewStationOccupation',...
                                  'HeaderInfo', 'ExternalEvent', 'CycleSlipRecord'};
                epochRecordsToRemove = 0;
                for epochFlag = 0:6
                    epochFlagName = epochFlagNames{epochFlag+1};
                    obj.epochFlags.(epochFlagName) = epochRecords(:,7) == epochFlag;
                    fprintf('Epoch flag %d: %d records\n',epochFlag,nnz(obj.epochFlags.(epochFlagName)));
                    if epochFlag ~= 0
                        epochRecordsToRemove = epochRecordsToRemove + nnz(obj.epochFlags.(epochFlagName));
                    end
                end
                fprintf('Remove non-zero epoch flags: %d records removed\n',epochRecordsToRemove);
                
                gregTime = epochRecords(obj.epochFlags.OK,1:6);
                [GPSWeek, GPSSecond, ~, ~] = greg2gps(gregTime);
                obj.t = [gregTime, GPSWeek, GPSSecond, datenum(gregTime)];
                
                % Allocating cells for satellites
                noRows = size(obj.t,1);
                obj.recClockOffset = zeros(noRows,1);
                for i = 1:length(obj.gnss)
                    s = obj.gnss(i);
                    noCols = obj.header.noObsTypes(obj.header.gnss == s);
                    obj.obs.(s) = cell(1,50);
                    obj.obs.(s)(:) = {zeros(noRows,noCols)};
                    
                    % Quality flags as array of chars
                    if param.parseQualityIndicator
                        obj.obsqi.(s) = cell(1,50);
                        obj.obsqi.(s)(:) = {repmat(' ',[noRows,noCols*2])};
                    else
                        obj.obsqi = [];
                    end
                end
                fprintf('Totally %d of %d epochs will be loaded (using decimation factor = %d)\n\n',...
                    size(obj.t,1),totalEpochsInRINEX,param.samplingDecimation);
                
                % Reading body part line by line
                carriageReturn = 0;
                idxt = 0;
                iEpoch = 0;
                nLinesToSkip = 0;
                for i = 1:length(bodyBuffer)
                    if nLinesToSkip > 0
                        nLinesToSkip = nLinesToSkip-1;
                        continue
                    end
                    
                    line = bodyBuffer{i};
                    if strcmp(line(1),'>')
                        iEpoch = iEpoch + 1;
                        if obj.epochFlags.OK(iEpoch)
                            idxt = idxt + 1;
                            if numel(line) > 35
                                obj.recClockOffset(idxt) = sscanf(line(36:end),'%d');
                            end
                        else
                            nLinesToSkip = epochRecordsNumber(iEpoch);
                        end
                    else
                        sys = line(1);
                        sysidx = obj.header.gnss == sys;
                        %if ~isempty(find(sys == obj.gnss,1))
                        if any(obj.gnss == sys)
                            lineLength = obj.header.noObsTypes(sysidx)*16;
                            linePrnMeas = [line(2:end) repmat(' ',[1,lineLength-length(line)+3])];
                            qi = [17:16:lineLength; 18:16:lineLength];
                            
                            % Quality info as chars
                            if param.parseQualityIndicator
                                obj.obsqi.(sys){1,prn}(idxt,:) = linePrnMeas(qi(:)');
                            end
                            
                            % Erase quality flags and convert code,phase,snr to numeric values
                            linePrnMeas(qi(:)') = ' ';
                            measIsPresent = linePrnMeas(13:16:end) == '.';
                            col = sscanf(linePrnMeas,'%f')'; % Slower due to replace in string
                            prn = col(1);
                            obj.obs.(sys){1,prn}(idxt,measIsPresent) = col(2:end);
                        end
                    end
                    
                    % Fast version of text waitbar
                    if rem(i,round(length(bodyBuffer)/100)) == 0
                        if carriageReturn == 0
                            fprintf('Loading RINEX: %3.0f%%',(i/length(bodyBuffer))*100);
                            carriageReturn = 1;
                        else
                            fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\bLoading RINEX: %3.0f%%',(i/length(bodyBuffer))*100);
                        end
                    end
                end
                fprintf('\b\b\b\b\b [done]\n');
                
                % Adding field to structure of available satellites in file
                obj.sat = struct();
                obj.satblock = struct();
                obj.satTimeFlags = struct();
                for i = 1:length(obj.gnss)
                    s = obj.gnss(i);
                    satSel = cellfun(@(x) sum(sum(x))~=0, obj.obs.(s));
                    obj.sat.(s) = find(satSel);
                    obj.satblock.(s) = getPRNBlockNumber(obj.sat.(s),s);
                    obj.obs.(s)(~satSel) = [];
                    if param.parseQualityIndicator
                        obj.obsqi.(s)(~satSel) = [];
                    end
                    obj.satTimeFlags.(s) = false(size(obj.t,1),nnz(satSel));
                    for j = 1:numel(obj.sat.(s))
                        obj.satTimeFlags.(s)(:,j) = sum(obj.obs.(s){j},2) ~= 0;
                    end
                end
            end
        end
        function obj = computeSatPosition(obj,ephType,ephFolder)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % 
            % Compute satellite positions for observed satellites
            %
            % Method will download required ephemeris files if path to
            % existing ephemeris files is not provided (via ephFolder input
            % variable).
            % 
            % Input (required):
            % ephType - type of ephemeris used for calculation, can be:
            %     * precise - precise ephemeris in SP3 format
            %               - default analysis center is CODE
            %     * broadcast - navigation RINEX files in version > 3.02
            %
            % Input (optional):
            % ephFolder - relative or absolute path to folder with
            %     ephemeris files (default path is where the RINEX is)
            %   
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            validateattributes(ephType,{'char'},{},2)
            mustBeMember(ephType,{'broadcast','precise'})
            if nargin == 2
            	switch ephType
                    case 'broadcast'
                        f = 'brdc';
                    case 'precise'
                        f = 'eph';
            	end
                ephFolder = fullfile(obj.path,f);
            end
            validateattributes(ephFolder,{'char'},{},3)

            % Looping through GNSS in OBSRNX and compute satellite positions
            for i = 1:numel(obj.gnss)
                s = obj.gnss(i);
                localRefPoint = obj.recpos;
                satList = obj.sat.(s);
                satFlags = obj.satTimeFlags.(s);
                obj.satpos(i) = SATPOS(s,satList,ephType,ephFolder,obj.t(:,7:8),localRefPoint,satFlags);
            end
        end
        function obj = updateRecposWithIncrement(obj,increment,incType)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Method will update recpos property with incrementing value
            % defined by "increment" variable. Increment can be given in
            % global ECEF or local ENU frame. Specification of the
            % increment frame is given in "incType".
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            validateattributes(increment,{'numeric'},{'size',[1,3]},1)
            validateattributes(incType,{'char'},{},2)
            mustBeMember(incType,{'dxyz','denu'})
            
            % Update of the recpos property will trigger update of
            % satpos.local coordinates
            obj.recpos = OBSRNX.addIncrementToRecpos(obj.recpos,increment,incType);
        end
        function saveToMAT(obj,outMatFullFileName)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Store OBSRNX object to MAT file
            % outMatFullFileName
            %   - full path to output MAT file
            %	- can be with or withou extension
            %	- if other extension than *.mat given, warning is called 
            %     and etension is forced to be *.mat
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if nargin == 1
                [~,filenameOut,~] = fileparts(fullfile(obj.path, obj.filename));
                outMatFileName = [filenameOut '.mat'];
                outMatFullFileName = fullfile(obj.path, outMatFileName);
            end
            [outPath,outFileName,outExtension] = fileparts(outMatFullFileName);
            if strcmp(outExtension,'.mat')
                outMatFileName = [outFileName, outExtension];
            else
                warning('Output file extension changed from *%s to *.mat!',outExtension);
                outMatFileName = [outFileName, '.mat'];
                outMatFullFileName = fullfile(outPath, outMatFileName);
            end
            fprintf('Saving RINEX "%s" to "%s" ...',obj.filename,outMatFileName);
            save(outMatFullFileName,'obj');
            fprintf(' [done]\n')
        end
        function obj = set.recpos(obj,recposInput)
            validateattributes(recposInput,{'numeric'},{'size',[1,3]},1)
            if (recposInput(1) == 0 && recposInput(2) == 0)
                warning('Unable to compute local coordinates for given localRefPoint! Property "localRefPoint" not set!');
            else
                warning('Change of receiver position:\n         from: [%.4f %.4f %.4f]\n           to: [%.4f %.4f %.4f]\n         This change triggers re-calculation of satellite local coordinates (if these are available)!',...
                    obj.recpos(1),obj.recpos(2),obj.recpos(3),recposInput(1),recposInput(2),recposInput(3))
                obj.recpos = recposInput;
                
                % Change also satpos(i).localRefPoint what will force
                % the satpos(i).local coordinates to be recalculated
                for i = 1:numel(obj.satpos)
                    obj.satpos(i).localRefPoint = recposInput;
                end
            end
        end
        function data = getObservation(obj,gnss,satNo,obsType,indices)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % 
            % Get satellite observation from loaded RINEX:
            % 
            % Input (required):
            % gnss - satellite system identifier (one of 'GREC')
            % satNo - satellite number
            % obsType - observation identifier
            % 
            % Input (optional)
            % indices - specify indices which you want to select
            % 
            % Output:
            % data - observation data
            %      - no unit conversion performed, data provided as stored
            %        in RINEX (see RINEX Version 3.04 Appendix A8):
            %        * pseudorange - in meters
            %        * carrier-phase - in cycles
            %        * doppler - in Hz
            %        * SNR - mostly in DB-HZ
            %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            validateattributes(gnss,{'char'},{'nonempty'},1);
            validatestring(gnss,split(obj.gnss,''));
            validateattributes(satNo,{'double'},{'scalar','positive'},2);
            mustBeMember(satNo,obj.sat.(gnss))
            validateattributes(obsType,{'char'},{'size',[1,3]},3);
            validatestring(obsType,obj.header.obsTypes.(gnss));
            
            satIdx = obj.sat.(gnss) == satNo;
            obsTypeIdx = strcmp(obsType,obj.header.obsTypes.(gnss));
            data = obj.obs.(gnss)(satIdx);
            if nargin < 5
                indices = 1:size(data{1},1);
            end
            data = data{1}(indices,obsTypeIdx);
        end
        function [elevation,azimuth,slantRange] = getLocal(obj,gnss,satNo,indices)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % 
            % Get satellite local coordinates:
            % 
            % Input (required):
            % gnss - satellite system identifier (one of 'GREC')
            % satNo - satellite number
            % 
            % Input (optional):
            % indices - specify indices which you want to select
            % 
            % Output:
            % elevation - elevation of satellite in deg
            % azimuth - azimuth of satellite in def
            % slantRange - slant range in meters between obsrnx.recpos 
            %       (default taken from RINEX) and reference point on the 
            %       satellite which can be:
            %         * APC (antenna phase center) for BROADCAST ephemeris
            %         * COM (center of mass) for PRECISE ephemeris
            %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % Checkif satellite positions are available
            if isempty(obj.satpos)
                elevation = []; azimuth = []; slantRange =[];
                warning('No satellite positions available! Please use method "computeSatPosition"...')
                return
            end
            
            % Verify inputs
            validateattributes(gnss,{'char'},{'nonempty'},1);
            validatestring(gnss,split(obj.gnss,''));
            validateattributes(satNo,{'double'},{'scalar','positive'},2);
            mustBeMember(satNo,obj.sat.(gnss))
            
            gnssIdx = find([obj.satpos.gnss] == gnss);
            satIdx = obj.satpos(gnssIdx).satList == satNo;
            
            % Return empty arrays if there is no data for given satellite 
            % (can happen if there are observation, but not ephemeris data)
            if nnz(satIdx) == 0
                warning('For satellite %s%02d there are no ECEF coordinates available!',gnss,satNo)
                elevation = []; azimuth = []; slantRange = [];
                return 
            end
            data = obj.satpos(gnssIdx).local{satIdx};
            if nargin < 4
                indices = 1:size(data,1);
            end
            elevation = data(indices,1);
            azimuth = data(indices,2);
            slantRange = data(indices,3);
        end
        function obj = correctAntennaVariation(obj,antex,correctionMode)
            % antex - ANTEX object
            % correctionMode - one of 'PCV,'PCO','PCV+PCO' -> see ANTEX doc
            validateattributes(antex,{'ANTEX'},{'size',[1,1]},1)
            if nargin < 3
                correctionMode = 'PCV';
            end
            
            for i = 1:numel(obj.gnss)
                GNSS = obj.gnss(i);
                phaseObsSel = cellfun(@(x) contains(x,'L'), obj.header.obsTypes.(GNSS));
                phaseObsSelIdx = find(phaseObsSel);
                phaseObsFreq = cellfun(@(x) str2double(x(2)), obj.header.obsTypes.(GNSS)(phaseObsSel));
                for j = 1:numel(obj.obs.(GNSS))
                    satNo = obj.sat.(GNSS)(j);
                    [satEle,satAzi,~] = obj.getLocal(GNSS,satNo);
                    if isempty(satEle) || isempty(satAzi)
                        warning('ANTEX %s corrections not applied for %s%02d, no satellite positions available!',correctionMode,GNSS,satNo)
                        continue 
                    end
                    phaseObs = obj.obs.(GNSS){j}(:,phaseObsSel);
                    fprintf('Compute PCV correction for %s%02d (mode: %s)\n',GNSS,satNo,correctionMode);
                    for k = 1:nnz(phaseObsSel)
                        if sum(phaseObs(:,k)) ~= 0
                            measuredEpochIdxs = phaseObs(:,k) ~= 0;
                            pcvCorr = antex.getCorrection(GNSS,phaseObsFreq(k),[satEle(measuredEpochIdxs),satAzi(measuredEpochIdxs)],correctionMode);
                            obj.obs.(GNSS){j}(measuredEpochIdxs,phaseObsSelIdx(k)) = phaseObs(measuredEpochIdxs,k) + pcvCorr;
                        end
                    end
                end
            end
        end
    end
    
	methods (Static)
        function obj = loadFromMAT(filepath)
            warning('off');
            xobj = load(filepath);
            warning('on');
            propAre1 = fieldnames(xobj.obj);
            propAre2 = fieldnames(xobj.obj.header);
            propShould1 = properties('OBSRNX');
            propShould2 = properties('OBSRNXheader');
            
            if isempty(setdiff(propAre1,propShould1)) && isempty(setdiff(propAre2,propShould2))
                obj = xobj.obj;
            else
                error('Input MAT file has not complete format structure!');
            end

            % Update filename and path to MAT file
            [folderpath,filename,ext] = fileparts(filepath);
            s = what(folderpath);
            obj.path = s.path;
            obj.filename = [filename ext];
        end
        function param = getDefaults()
			param.filtergnss = 'GREC';
            param.samplingDecimation = 1;
            param.parseQualityIndicator = false;
        end
        function param = checkParamInput(param)
            validateattributes(param,{'struct'},{'size',[1,1]},1);
            validateFieldnames(param,{'filtergnss'});
            validateFieldnames(param,{'samplingDecimation'});
            validateFieldnames(param,{'parseQualityIndicator'});
            
            % Handle filtergnss
            s = unique(param.filtergnss);
            param.filtergnss = s;
            for i = 1:numel(s)
                if ~ismember(s(i),'GREC')
                    error('Not implemented system "%s", only "GREC" are supported!',s(i));
                end
            end
            
            % Handle samplingInterval
            if isnumeric(param.samplingDecimation)
                if param.samplingDecimation < 0 || mod(param.samplingDecimation,1) ~= 0
                    error('Input parameter "samplingDecimation" has to be positive integer value!')
                end
            else
                error('Input parameter "samplingDecimation" has to be of numeric type!')
            end
        end
        function recpos = addIncrementToRecpos(oldrecpos,increment,incType)
            validateattributes(oldrecpos,{'numeric'},{'size',[1,3]},1)
            validateattributes(increment,{'numeric'},{'size',[1,3]},2)
            validateattributes(incType,{'char'},{},3)
            mustBeMember(incType,{'dxyz','denu'})
            switch incType
                case 'dxyz'
                    recpos = oldrecpos + increment;
                case 'denu'
                    ell = referenceEllipsoid('wgs84');
                    [lat0,lon0,h0] = ecef2geodetic(oldrecpos(1),oldrecpos(2),oldrecpos(3),ell,'degrees');
                    [xnew,ynew,znew] = enu2ecef(increment(1),increment(2),increment(3),lat0,lon0,h0,ell);
                    recpos = [xnew,ynew,znew];
            end
        end
    end
end