classdef SATPOS
    properties
        gnss (1,:) char
        referencePoint (1,:) char {mustBeMember(referencePoint,{'APC','COM'})} = 'APC';
        ephType (1,:) char {mustBeMember(ephType,{'broadcast','precise'})} = 'broadcast';
        ephFolder
        ephList
        ECEF
        local
    end
    
    methods
        function obj = SATPOS(ephType,ephFolder,gpstime)
            %obj.ephType = ephType;
            
        end
    end
end