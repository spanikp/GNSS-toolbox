classdef OBSRNXOptions
    properties
        filtergnss (1,:) char {mustBeMember(filtergnss,'GREC')} = 'GREC'
        samplingDecimation (1,1) double {mustBeInteger, mustBePositive} = 1
        parseQualityIndicator (1,1) logical = false
    end
    methods (Static)
        function obj = fromStruct(paramStruct)
            validateattributes(paramStruct,{'struct'},{'size',[1,1]},1);
            obj = struct2obj(paramStruct,OBSRNXOptions);
        end
    end
end