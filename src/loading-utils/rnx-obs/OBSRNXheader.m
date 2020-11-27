classdef OBSRNXheader
	properties
    	interval (1,1) double
        approxPos (1,3) double
        gnss (1,:) char
        leapSeconds (1,1) double
        leapSecondsInfo (1,3) double
        leapSecondsSystem (1,3) char
		obsTypes struct
		noObsTypes (1,:) double
        version (1,:) char
        path (1,:) char
        filename (1,:) char
        headerSize (1,1) double
        marker (1,1) struct = struct('name','','number','','type','')
        receiver (1,1) struct = struct('serialnumber','','type','','version','','clockOffsetApplied',false)
        antenna (1,1) struct = struct('serialnumber','','type','','offset',zeros(3,1),'offsetType','')
        observer (1,:) char
        agency (1,:) char
        signalStrengthUnit (1,:) char
        glonassFreqSlots (:,2) double
        glonassCodeBias (1,:) char
        sysPhaseShifts (:,1) struct
    end
   
    methods
    	function obj = OBSRNXheader(filepath)
            [folderpath,filename,ext] = fileparts(filepath);
            obj.path = fullpath(folderpath);
            obj.filename = [filename ext];
            absfilepath = fullfile(obj.path, obj.filename);
            obj.obsTypes = struct();

            % Reading raw RINEX data using textscan
            fprintf('Reading header of RINEX: %s\n', absfilepath);
            finp = fopen(absfilepath,'r');
            %fileBuffer = textscan(finp, '%s', 'Delimiter', '\n', 'whitespace', '');
            %fileBuffer = fileBuffer{1};
            %fclose(finp);
            
            % Initialize rnx structure
            lineIndex = 0;
            sysObsTypesBuffer = {};
            glonassFreqSlotsTemp = [];
            firstGlonassSlotLine = true;
            while 1
                lineIndex = lineIndex + 1;
                %line = fileBuffer{lineIndex};
                line = fgetl(finp);
                
                if lineIndex == 1
                    if contains(line,'RINEX VERSION / TYPE') && contains(line,'OBSERVATION DATA')
                        obj.version = strtrim(line(1:20));
                    else
                        error('Input file is not observation RINEX!')
                    end
                end
                if contains(line,'APPROX POSITION XYZ')
                    obj.approxPos = sscanf(line(1:60),'%f');
                end
                if contains(line,'LEAP SECONDS')
                    obj.leapSeconds = str2double(strtrim(line(1:6)));
                    obj.leapSecondsInfo(1) = str2double(strtrim(line(7:12)));
                    obj.leapSecondsInfo(2) = str2double(strtrim(line(13:18)));
                    obj.leapSecondsInfo(3) = str2double(strtrim(line(19:24)));
                    obj.leapSecondsSystem = line(25:27);
                end
                if contains(line,'SIGNAL STRENGTH UNIT')
                    obj.signalStrengthUnit = strtrim(line(1:60));
                end
                if contains(line,'MARKER NAME')
                    obj.marker.name = strtrim(line(1:60));
                end
                if contains(line,'MARKER NUMBER')
                    obj.marker.number = strtrim(line(1:60));
                end
                if contains(line,'MARKER TYPE')
                    obj.marker.type = strtrim(line(1:60));
                end
                if contains(line,'ANT # / TYPE')
                    obj.antenna.serialnumber = strtrim(line(1:20));
                    obj.antenna.type = strtrim(line(21:40));
                end
                if contains(line,'REC # / TYPE / VERS')
                    obj.receiver.serialnumber = strtrim(line(1:20));
                    obj.receiver.type = strtrim(line(21:40));
                    obj.receiver.version = strtrim(line(41:60));
                end
                if contains(line,'RCV CLOCK OFFS APPL')
                    obj.receiver.clockOffsetApplied = logical(str2double(strtrim(line(1:60))));
                end
                if contains(line,'ANTENNA: DELTA H/E/N')
                    obj.antenna.offset = sscanf(line(1:60),'%f');
                    match = regexp(line,'[A-Z]/[A-Z]/[A-Z]','match');
                    obj.antenna.offsetType = match{1};
                    
                end
                if contains(line,'OBSERVER / AGENCY')
                    obj.observer = strtrim(line(1:20));
                    obj.agency = strtrim(line(21:40));
                end
                if contains(line,'INTERVAL')
                    obj.interval = sscanf(line(1:60),'%f');
                end
                if contains(line,'SYS / # / OBS TYPES')
                    sysObsTypesBuffer = [sysObsTypesBuffer; line];
                end
                if contains(line,'GLONASS SLOT / FRQ #')
                    if firstGlonassSlotLine
                        firstGlonassSlotLine = false;
                        glonassFreqSlotsNoSats = sscanf(line(1:3),'%d');
                    end
                    glonassFreqSlotsTemp = [glonassFreqSlotsTemp; reshape(line(5:60),[7,8])'];
                end
                if contains(line,'SYS / PHASE SHIFT')
                    i = length(obj.sysPhaseShifts)+1;
                    obj.sysPhaseShifts(i,1).gnss = line(1);
                    obj.sysPhaseShifts(i,1).signal = line(3:5);
                    obj.sysPhaseShifts(i,1).value = sscanf(line(6:14),'%f');
                end
                if contains(line,'GLONASS COD/PHS/BIS')
                    obj.glonassCodeBias = line;
                end
                
                % Breaks if lineIndex reaches 'END OF HEADER'
                if contains(line,'END OF HEADER')
                    obj.headerSize = lineIndex;
                    break
                end
            end
            obj = obj.parseObsTypes(sysObsTypesBuffer);
            obj.printSummary();
            
            % Parse GLONASS frequency slots
            if ~firstGlonassSlotLine
                for i = 1:size(glonassFreqSlotsTemp,1)
                    satNo = sscanf(glonassFreqSlotsTemp(i,2:3),'%d');
                    freqSlot = sscanf(glonassFreqSlotsTemp(i,4:6),'%d');
                    if isempty(satNo)
                        break
                    else
                        obj.glonassFreqSlots(i,:) = [satNo, freqSlot];
                    end
                end
                assert(glonassFreqSlotsNoSats == size(obj.glonassFreqSlots,1),'GLONASS SLOTs / FRQ # mismatch!');
            end
            
            % Raise warning if GLONASS specific records are missing in RINEX header
            if ismember('R',obj.gnss)
                if isempty(obj.glonassCodeBias)
                    warning('Mandatory header record "GLONASS COD/PHS/BIS" not provided. Zero Glonass code biases used!');
                end
                if isempty(obj.glonassFreqSlots)
                    warning('Mandatory header record "GLONASS SLOT / FRQ #" not provided!');
                end
            end
            
            fclose(finp);
        end
        function printSummary(obj)
            aot = strsplit(obj.antenna.offsetType,'/');
            fprintf([repmat('#',[1 80]), '\n']);
            fprintf('RINEX version:              %s\n',obj.version);
            fprintf('RINEX marker/number:        %s/%s\n',obj.marker.name,obj.marker.number);
            fprintf('RINEX receiver:             %s (%s, %s)\n',obj.receiver.type,obj.receiver.serialnumber,obj.receiver.version);
            fprintf('RINEX antenna:              %s (%s)\n',obj.antenna.type,obj.antenna.serialnumber);
            fprintf('RINEX antenna offset:       %s = %7.4f m\n',aot{1},obj.antenna.offset(1));
            for i = 2:3
                fprintf('                            %s = %7.4f m\n',aot{i},obj.antenna.offset(i));
            end
            fprintf('RINEX ARP position:         X = %14.4f m\n',obj.approxPos(1));
            fprintf('                            Y = %14.4f m\n',obj.approxPos(2));
            fprintf('                            Z = %14.4f m\n',obj.approxPos(3));
            fprintf('RINEX recording interval:   %d s\n',obj.interval);
            fprintf('RINEX available systems:    %s\n',obj.gnss);
            for i = 1:numel(obj.gnss)
                s = obj.gnss(i);
                fprintf('RINEX %s obs types (%2d):     %s\n',s,obj.noObsTypes(i),strjoin(obj.obsTypes.(s),','));
            end
            fprintf([repmat('#',[1 80]), '\n']);
        end
    end
    methods (Access = private)
        function obj = parseObsTypes(obj,buffer)
            for i = 1:numel(buffer)
                line = buffer{i};
                if ~strcmp(line(1),' ')
                    obj.gnss(end+1) = line(1);
                    obj.noObsTypes(end+1) = str2double(line(5:6));
                    
                    obsTypesTemp = strsplit(line(8:60));
                    obsTypesTemp = obsTypesTemp(1:end-1);
                    obj.obsTypes.(line(1)) = obsTypesTemp;
                    
                    if i ~= numel(buffer)
                        if strcmp(buffer{i+1}(1),' ')
                            obsTypesTemp = strsplit(buffer{i+1}(8:60));
                            obsTypesTemp = obsTypesTemp(1:end-1);
                            obj.obsTypes.(line(1))(end+1:end+length(obsTypesTemp)) = obsTypesTemp;
                        end
                    end
                end
            end
        end
    end
end