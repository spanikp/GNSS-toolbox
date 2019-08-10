function validateFieldnames(inputStruct,requiredFieldnames)
currentlyAre = fieldnames(inputStruct);
diffFieldnames = setdiff(requiredFieldnames,currentlyAre);

if ~isempty(diffFieldnames)
    s = '';
    for i = 1:numel(diffFieldnames)
        s = [s, sprintf('Field "%s" not exist in input structure!\n',diffFieldnames{i})];
    end
    error(s);
end