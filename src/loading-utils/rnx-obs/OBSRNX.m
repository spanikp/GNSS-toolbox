classdef OBSRNX
	properties
		header
        path (1,:) char
        filename (1,:) char
        gnss (1,:) char
        t (:,9) double
        obs
        obsqi
        satTimeFlags
        sat
        satblock
		satpos (1,:) SATPOS
	end
	
	methods 
		function obj = OBSRNX(filepath,param)
            if nargin == 1
				param = OBSRNX.getDefaults();
            end
            hdr = OBSRNXheader(filepath);
            validateattributes(hdr,{'OBSRNXheader'},{})
            obj.header = hdr;
            obj.path = obj.header.path;
            obj.filename = obj.header.filename;
            obj = obj.loadRNXobservation(param);
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
                obj.obs = struct();
                
                % Find time moments
                fprintf('Resolving measurement''s epochs ... ')
                timeSelection = cellfun(@(x) strcmp(x(1),'>'), bodyBuffer);
                gregTime = cell2mat(cellfun(@(x) sscanf(x,'> %f %f %f %f %f %f')',...
                    bodyBuffer(timeSelection),'UniformOutput',false));
                [GPSWeek, GPSSecond, ~, ~] = greg2gps(gregTime);
                obj.t = [gregTime, GPSWeek, GPSSecond, datenum(gregTime)];
                
                % Allocating cells for satellites
                noRows = size(obj.t,1);
                for i = 1:length(obj.gnss)
                    s = obj.gnss(i);
                    noCols = obj.header.noObsTypes(obj.header.gnss == s);
                    obj.obs.(s) = cell(1,50);
                    obj.obs.(s)(:) = {zeros(noRows,noCols)};
                    
                    % Quality flags as array of chars
                    obj.obsqi.(s) = cell(1,50);
                    obj.obsqi.(s)(:) = {repmat(' ',[noRows,noCols*2])};
                end
                
                fprintf('[done]\n')
                fprintf('Totally %d epochs will be loaded.\n\n',size(obj.t,1));
                
                % Reading body part line by line
                carriageReturn = 0;
                idxt = 0;
                for i = 1:length(bodyBuffer)
                    line = bodyBuffer{i};
                    
                    if strcmp(line(1),'>')
                        idxt = idxt + 1;
                    else
                        sys = line(1);
                        sysidx = find(sys == obj.header.gnss);
                        if ~isempty(find(sys == obj.gnss,1))
                            prn = str2double(line(2:3));
                            lineLength = obj.header.noObsTypes(sysidx)*16;
                            line = pad(line(4:end),lineLength);
                            qi1 = 15:16:lineLength;
                            qi2 = 16:16:lineLength;
                            
                            % Quality info as chars
                            colqi = line(sort([qi1, qi2]));
                            
                            % Erase quality flags and convert code,phase,snr to numeric values
                            line([qi1, qi2]) = [];
                            line(11:14:(lineLength-obj.header.noObsTypes(sysidx)*2)) = '.';
                            col = sscanf(replace(line,' .   ','0.000'),'%f')';
                            obj.obs.(sys){1,prn}(idxt,:) = col;
                            obj.obsqi.(sys){1,prn}(idxt,:) = colqi;
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
                fprintf(' [done]\n');
                
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
                    obj.obsqi.(s)(~satSel) = [];
                    obj.satTimeFlags.(s) = false(size(obj.t,1),nnz(satSel));
                    for j = 1:numel(obj.sat.(s))
                        obj.satTimeFlags.(s)(:,j) = sum(obj.obs.(s){j},2) ~= 0;
                    end
                end
            end
        end
        function obj = computeSatPosition(obj,ephType)
            validateattributes(ephType,{'char'},{})
            assert(ismember(ephType,{'broadcast','precise'}),'Input "ephType" can be set to "broadcast" or "precise" only!')
            
            switch ephType
                case 'broadcast'
                    f = 'brdc';
                case 'precise'
                    f = 'eph';
            end
            navFolder = fullfile(obj.path,f);
            for i = 1:numel(obj.gnss)
                s = obj.gnss(i);
                recpos = obj.header.approxPos;
                satList = obj.sat.(s);
                satFlags = obj.satTimeFlags.(s);
                obj.satpos(i) = SATPOS(s,satList,ephType,navFolder,obj.t(:,7:8),recpos,satFlags);
            end
        end
        function saveToMAT(obj,outMatFullFileName)
            if nargin == 1
                [~,filenameOut,~] = fileparts(fullfile(obj.path, obj.filename));
                outMatFileName = [filenameOut '.mat'];
                outMatFullFileName = fullfile(obj.path, outMatFileName);
            end
            outMatFileName = strsplit(outMatFullFileName,{'/','\'});
            outMatFileName = outMatFileName{end};
            fprintf('Saving RINEX "%s" to "%s" ...',obj.filename,outMatFileName);
            save(outMatFullFileName,'obj');
            fprintf(' [done]\n')
        end
	end
	
	methods (Static)
        function obj = loadFromMAT(filepath)
            xobj = load(filepath);
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
        end
    end
end

