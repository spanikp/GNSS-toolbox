classdef SP3header
    properties
        version (1,1) char
        gnss (1,:) char
        dateStart (1,8) double
        noEpochs (1,1) double
        noSats (1,1) double
        dataUsed (1,:) char
        coordSystem (1,:) char
        timeSystem (1,:) char
        orbitType (1,:) char {mustBeMember(orbitType,{'   ','FIT','EXT','BCT','HLM'})} = '   '
        agency (1,:) char
        type (1,1) char {mustBeMember(type,{'P'})} = 'P'
        path (1,:) char
        filename (1,:) char
    	interval (1,1) double
        headerSize (1,1) double
        PCV (1,:) char
        sat
        satAccuracy
    end
    methods
        function obj = SP3header(filename)
            [p,f,ext] = fileparts(filename);
            s = what(p);
            obj.path = s.path;
            obj.filename = [f ext];
            absFilePath = fullfile(obj.path,obj.filename);
            
            fprintf('Reading header of SP3 file: %s ',obj.filename);
            finp = fopen(absFilePath,'r');
            fileBuffer = textscan(finp, '%s', 'Delimiter', '\n', 'whitespace', '');
            fileBuffer = fileBuffer{1};
            fclose(finp);
            
            lineIndex = 0;
            satRecords = '';
            satAccExponent = [];
            while 1
                lineIndex = lineIndex + 1;
                line = fileBuffer{lineIndex};
                if regexp(line(1:2),'#[c|d]','once')
                   obj.version = line(2);
                   obj.dateStart(1:6) = sscanf(line(4:31),'%f')';
                   obj.noEpochs = str2double(line(33:39));
                   obj.dataUsed = strtrim(line(41:45));
                   obj.coordSystem = strtrim(line(47:51));
                   obj.orbitType = strtrim(line(53:55));
                   obj.agency = strtrim(line(57:60));
                end
                if strcmp(line(1:2),'##')
                    x = sscanf(line(3:end),'%f')';
                    obj.dateStart(7:8) = x(1:2);
                    obj.interval = x(3);
                end
                if strcmp(line(1:2),'+ ')
                    noSats = str2double(line(4:6));
                    if ~isnan(noSats)
                        obj.noSats = noSats;
                    end
                    satRecords = [satRecords, strtrim(line(10:end))];
                end
                if strcmp(line(1:2),'++')
                    satAccExponent = [satAccExponent, str2num(line(10:end))];
                end
                if contains(line,'PCV:')
                    match = regexp(line,'PCV:.{1,10}','match');
                    x = strsplit(match{1},':');
                    obj.PCV = strtrim(x{2});
                end
                if strcmp(line(1:2),'%c') && ~strcmp(line(4:5),'cc')
                    obj.timeSystem = line(10:12);
                end
                if line(1) == '*'
                    obj.headerSize = lineIndex;
                    break
                end
            end
            obj.gnss = strrep(unique(satRecords(1:3:end)),' ','');
            [obj.sat, satSum] = SP3header.parseSP3Sats(satRecords);
            if satSum ~= obj.noSats
                obj.noSats = satSum;
                warning('Mismatch of satellite number available in file!');
            end
            obj.satAccuracy = SP3header.parseSP3Accuracy(satRecords,satAccExponent);
            fprintf('[done]\n')
        end
    end
    methods (Static)
        function [sat, satSum] = parseSP3Sats(satIdstring)
            sat = struct();
            satSum = 0;
            gnss = strtrim(unique(satIdstring(1:3:end)));
            for i = 1:numel(gnss)
                s = gnss(i);
                sats = repmat(' ',size(satIdstring));
                idxNeeded = [find(satIdstring == s)+1, find(satIdstring == s)+2];
                sats(idxNeeded) = satIdstring(idxNeeded);
                sat.(s) = str2num(sats);
                satSum = satSum + numel(sat.(s));
            end
        end
        function satAccuracy = parseSP3Accuracy(satIdstring,satAccExponent)
            satAccExponent(satAccExponent == 0) = NaN;
            ids = cellstr([satIdstring(1:3:end)', satIdstring(2:3:end)', satIdstring(3:3:end)']);
        	gnss = strtrim(unique(satIdstring(1:3:end)));
            for i = 1:numel(gnss)
                selgnss = cellfun(@(x) strcmp(x(1),gnss(i)),ids);
                satAccuracy.(gnss(i)) = (2.^satAccExponent(selgnss))*1e-3;
            end
        end
    end
end