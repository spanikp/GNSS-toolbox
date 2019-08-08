classdef SP3
    properties
        fileList (1,1) fileList
        header (1,:) SP3header
        gnss
        t (:,9) double
        sat
        pos
        clockData
        satTimeFlags
    end
    
    methods
        function obj = SP3(cellFilelist)
            obj.fileList = fileList(cellFilelist,{'SP3','sp3','eph','EPH'});
            temp = struct('pos',[],'t',[],'sat',[],'clockData',[],'satTimeFlags',[]);
            for i = 1:numel(obj.fileList.fileNames)
                f = obj.fileList.fileNames{i};
                obj.header(i) = SP3header(f);
                [temp(i).pos,temp(i).t,temp(i).sat,temp(i).clockData,temp(i).satTimeFlags] = SP3.loadContent(f);
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
        function [pos, t, sat, clockData, satTimeFlags] = loadContent(filename)
            validateattributes(filename,{'char'},{'size',[1,NaN]},1);
            finp = fopen(filename,'r');
            raw = textscan(finp,'%s','Delimiter','\n','Whitespace', '');
            raw = raw{1};
            fclose(finp);
            
            % Get epochs
            selEpochs = cellfun(@(x) strcmp(x(1),'*'),raw);
            contenStartIdx = find(selEpochs);
            contenStartIdx = contenStartIdx(1);
            ymdhms = cell2mat(cellfun(@(x) sscanf(x(2:end),'%f')', raw(selEpochs),'UniformOutput',false));
            [gpsweek, tow, ~, ~] = greg2gps(ymdhms);
            t = [ymdhms, gpsweek, tow, datenum(ymdhms)];
            raw = raw(contenStartIdx:end);
            
            % Allocate structure fields for different systems
            satsys = cellfun(@(x) x(2),raw(1:end-1))';
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
            
            % Looping through the file
            idxEpoch = 0;
            for i = 1:length(raw)
                line = raw{i};
                if strcmp(line(1),'*')
                    idxEpoch = idxEpoch + 1;
                elseif strcmp(line(1),'P')
                    prn = sscanf(line(3:4),'%f');
                    xyzc = sscanf(line(5:60),'%f')';
                    idxSat = find(sat.(line(2)) == prn);
                    pos.(line(2)){idxSat}(idxEpoch,:) = xyzc(1:3)*1e3;
                    if round(xyzc(4)) ~= 1e6
                        clockData.(line(2)){idxSat}(idxEpoch,:) = xyzc(4);
                    end
                    satTimeFlags.(line(2))(idxEpoch,idxSat) = true;
                else
                    continue
                end
            end
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