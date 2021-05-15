classdef OBSRNXOptions
    properties
        filtergnss (1,:) char {mustBeMember(filtergnss,'GREC')} = 'GREC'
        samplingDecimation (1,1) double {mustBeInteger, mustBePositive} = 1
        parseQualityIndicator (1,1) logical = false
    end
    methods (Static)
        function obj = fromStruct(paramStruct)
            validateattributes(paramStruct,{'struct'},{'size',[1,1]},1);
            inNames = fieldnames(paramStruct);
            reqNames = properties(OBSRNXOptions);
            selValidNames = ismember(inNames,reqNames);
            notValidFields = inNames(~selValidNames);
            assert(isempty(notValidFields),sprintf('Not valid fieldnames: %s!',strjoin(notValidFields,', ')));
            
            notProvidedProps = setdiff(reqNames,inNames);
            if ~isempty(notProvidedProps)
                warning('Following properties not available in provided struct:\n\n  %s\n\nDefault values will be used instead!\n',strjoin(notProvidedProps,'\n'));
            end
            
            % Setting properties
            obj = OBSRNXOptions();
            for i = 1:length(inNames)
                propertyName = inNames{i};
                assert(isa(paramStruct.(propertyName),class(obj.(propertyName))),...
                    sprintf('Variable type error for property "%s": "%s" is given, but "%s" is required!',propertyName,class(paramStruct.(propertyName)),class(obj.(propertyName))));
                obj.(propertyName) = unique(paramStruct.(propertyName));
            end
        end
    end
end