classdef ANTEXset
    properties
        filename (1,:) char
        path (1,:) char
        PCVtype (1,1) char {mustBeMember(PCVtype,{'A','R'})} = 'A'
        version (1,:) char
        antennas (1,:) ANTEX
        id (1,:) cell
    end
    methods
        function obj = ANTEXset(filename)
            if nargin > 0
                fileList.checkExistence({filename});
                [folderPath,plainFileName,ext] = fileparts(filename);
                obj.path = fullpath(folderPath);
                obj.filename = [plainFileName, ext];
                
                finp = fopen(fullfile(obj.path, obj.filename),'r');
                raw = textscan(finp,'%s','Delimiter','\n','whitespace','');
                raw = raw{1};
                fclose(finp);
                
                versionRowIdx = find(cellfun(@(x) contains(x,'ANTEX VERSION / SYST'),raw));
                antexTypeRowIdx = find(cellfun(@(x) contains(x,'PCV TYPE / REFANT'),raw));
                if numel(versionRowIdx) > 1 || numel(antexTypeRowIdx) > 1
                    error('Invalid ANTEX file: more than 1 "ANTEX VERSION" or "PCV TYPE" rows!');
                else
                    obj.version = strtrim(raw{versionRowIdx}(1:8));
                    obj.PCVtype = raw{antexTypeRowIdx}(1);
                    startAnt = find(cellfun(@(x) contains(x,'START OF ANTENNA'),raw));
                    endAnt = find(cellfun(@(x) contains(x,'END OF ANTENNA'),raw));
                    assert(numel(startAnt)==numel(endAnt),'No match between number of "START OF ANTENNA" and "END OF ANTENNA" elements for file "%s"!',obj.filename); 
                    for i = 1:numel(startAnt)
                        rawAnt = raw(startAnt(i):endAnt(i));
                        obj.antennas(i) = ANTEX.parseFromTextCells(rawAnt);
                        obj.antennas(i).version = obj.version;
                        obj.antennas(i).PCVtype = obj.PCVtype;
                    end
                end
            end
        end
    end
    methods (Static)
        
    end
end