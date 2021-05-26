function obj = struct2obj(inputStruct,requiredClass,verbose)
if nargin < 3, verbose = true; end
validateattributes(inputStruct,{'struct'},{'size',[1,1]},1);
assert(numel(requiredClass) == 1);
validateattributes(verbose,{'logical'},{'size',[1,1]},3);

inNames = fieldnames(inputStruct);
reqNames = properties(requiredClass);
selValidNames = ismember(inNames,reqNames);
notValidFields = inNames(~selValidNames);
assert(isempty(notValidFields),sprintf('Not valid fieldnames: %s!',strjoin(notValidFields,', ')));

% Raise warning that not provided properties will be used from class definition
if verbose
    notProvidedProps = setdiff(reqNames,inNames);
    if ~isempty(notProvidedProps)
        warning('Following properties not available in provided struct:\n\n%s\n\nDefault values will be used instead!\n',strjoin(notProvidedProps,'\n'));
    end
end

% Map given structure to required object
obj = requiredClass;
for i = 1:length(inNames)
    propertyName = inNames{i};
    assert(isa(inputStruct.(propertyName),class(obj.(propertyName))),...
        sprintf('Variable type error for property "%s": "%s" is given, but "%s" is required!',propertyName,class(inputStruct.(propertyName)),class(obj.(propertyName))));
    if isa(obj.(propertyName),'containers.Map')
        % Only update map, not fully replace it
        givenKeys = inputStruct.(propertyName).keys;
        requiredKeys = obj.(propertyName).keys;
        notValidKeys = setdiff(givenKeys(~ismember(givenKeys,requiredKeys)),requiredKeys);
        assert(isempty(notValidKeys),sprintf('Not valid keys in map: %s',strjoin(notValidKeys,', ')));
        for j = 1:length(givenKeys)
            key = givenKeys{j};
            givenTypeProperty = class(inputStruct.(propertyName)(key));
            requiredTypeProperty = class(obj.(propertyName)(key));
            assert(isa(inputStruct.(propertyName)(key),requiredTypeProperty),...
                sprintf('Variable type error for property "%s"(''%s''): "%s" is given, but "%s" is required!',propertyName,key,givenTypeProperty,requiredTypeProperty));
            obj.(propertyName)(key) = inputStruct.(propertyName)(key);
        end
    elseif isa(obj.(propertyName),'char')
        obj.(propertyName) = inputStruct.(propertyName);
    else
        obj.(propertyName) = unique(inputStruct.(propertyName));
    end
end