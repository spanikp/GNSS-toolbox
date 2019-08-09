classdef SP3
    properties
        fileList (1,1) fileList
        header (1,:) SP3header
        gnss
        interval (1,1) double = 900
        t (:,9) double
        sat
        pos
        clockData
        satTimeFlags
    end
    
    methods
        function obj = SP3(cellFilelist,interval)
            if nargin == 2
                assert(rem(interval,1)==0,'Input resampling interval has to be integer!');
                obj.interval = interval;
            end
            obj.fileList = fileList(cellFilelist,{'SP3','sp3','eph','EPH'});
            temp = struct('pos',[],'t',[],'sat',[],'clockData',[],'satTimeFlags',[]);
            for i = 1:numel(obj.fileList.fileNames)
                f = obj.fileList.fileNames{i};
                obj.header(i) = SP3header(f);
                if rem(obj.interval,obj.header(i).interval)~=0
                    error('Input file "%s" cannot be resampled: mismatch between SP3 interval (%ds) and user interval (%ds)!',...
                        obj.header(i).filename,obj.header(i).interval,obj.interval); 
                end
                [temp(i).pos,temp(i).t,temp(i).sat,temp(i).clockData,temp(i).satTimeFlags] = SP3.loadContent(f,obj.interval/obj.header(i).interval);
                if ~isequal(temp(i).sat,obj.header(i).sat)
                   warning('Inconsistency between HEADER and BODY satellite list for "%s" file!',obj.header(i).filename) 
                end
            end
            %[obj.pos, obj.t, obj.sat, obj.clockData, obj.satTimeFlags] = SP3.mergeContent(temp);
        end
%         function obj = resample(obj,everyNepoch)
% 
%         end
    end
    methods (Static)
        function [pos, t, sat, clockData, satTimeFlags] = loadContent(filename,downsampleFactor)
            if nargin == 1
                downsampleFactor = 1; % Load each epochs by default
            end
            validateattributes(filename,{'char'},{'size',[1,NaN]},1);
            validateattributes(downsampleFactor,{'double'},{'size',[1,1],'>=',1},2);
            assert(rem(downsampleFactor,1)==0,'Input value "downsampleFactor" has to be integer!');

            [~,f,fe] = fileparts(filename);
            fprintf('Loading content of SP3 file: %s ',[f,fe]);
            finp = fopen(filename,'r');
            raw = textscan(finp,'%s','Delimiter','\n','Whitespace', '');
            raw = raw{1};
            fclose(finp);
            
            % Get epochs
            totalEpochs = find(cellfun(@(x) strcmp(x(1),'*'),raw));
            selEpochs = totalEpochs(1:downsampleFactor:end);
            contentStartIdx = selEpochs(1);
            ymdhms = cell2mat(cellfun(@(x) sscanf(x(2:end),'%f')', raw(selEpochs),'UniformOutput',false));
            [gpsweek, tow, ~, ~] = greg2gps(ymdhms);
            t = [ymdhms, gpsweek, tow, datenum(ymdhms)];

            % Allocate structure fields for different systems
            satsys = cellfun(@(x) x(2),raw(contentStartIdx:end-1))';
            gnss = strtrim(unique(satsys));
            for i = 1:numel(gnss)
                selgnss = cellfun(@(x) strcmp(x(2),gnss(i)),raw);
                sat.(gnss(i)) = unique(cellfun(@(x) str2double(x(3:4)),raw(selgnss))');
                pos.(gnss(i)) = cell(1,numel(sat.(gnss(i))));
                pos.(gnss(i))(:) = {zeros(size(t,1),3)};
                clockData.(gnss(i)) = cell(1,numel(sat.(gnss(i))));
                clockData.(gnss(i))(:) = {NaN(size(t,1),1)};
                satTimeFlags.(gnss(i)) = false(size(t,1),numel(sat.(gnss(i))));
            end
            
            if downsampleFactor ~= 1
                fprintf('\nDownsampling content of "%s" to %d seconds ',[f,fe],mean(diff(tow)))
            end
            % Looping through the file
            idxEpoch = 0;
            skipEpoch = 0;
            for i = 1:numel(totalEpochs)
                if skipEpoch == 0
                	idxEpoch = idxEpoch + 1;
                    idxLine = totalEpochs(i)+1;
                    while 1
                        line = raw{idxLine};
                        idxLine = idxLine+1;
                        if strcmp(line(1),'P')
                            prn = sscanf(line(3:4),'%f');
                            xyzc = sscanf(line(5:60),'%f')';
                            idxSat = find(sat.(line(2)) == prn);
                            pos.(line(2)){idxSat}(idxEpoch,:) = xyzc(1:3)*1e3;
                            if round(xyzc(4)) ~= 1e6
                                clockData.(line(2)){idxSat}(idxEpoch,:) = xyzc(4);
                            end
                            satTimeFlags.(line(2))(idxEpoch,idxSat) = true;
%                         elseif strcmp(line(1),'*')
%                             skipEpoch = downsampleFactor - 1;
%                             break
                        else
                            skipEpoch = downsampleFactor - 1;
                            break
                        end
                    end
                else
                    skipEpoch = skipEpoch - 1;
                end
            end
            fprintf('[done]\n');
        end
        function [pos, t, sat, clockData, satTimeFlags] = mergeContent(contentStruct)
            diffFields = setdiff(fieldnames(contentStruct),{'pos','t','sat','clockData','satTimeFlags'}');
            if ~isempty(diffFields)
                error('Input content structure is missing fields: %s',strjoin(diffFields,','));
            else
                gnss = '';
                for i = 1:numel(contentStruct)
                    
                end
            end
        end
	end
end