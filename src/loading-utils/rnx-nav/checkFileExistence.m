function file_exist = checkFileExistence(filenames,list)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to chceck existence of given files (cell filenames) according to
% listing of files in folder (cell list);
%
% Example: filenames = {'a.txt', 'b.txt', 'd.txt'} <-- what I want
%          list = {'a.txt', 'b.txt', 'c.txt'}      <-- what is in directory
%
%          file_exist = checkFileExistence(filenames,list)
%          file_exist = [true, true, false]
%
% Peter Spanik, 9.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Print info
fprintf('\n>>> Controlling if files exist in brdc folder >>>\n');

% Initialize output
file_exist = false(size(filenames));

% If file list is empty return 
if isempty(list)
    for i = 1:length(filenames)
        fprintf('File: %s not exist in brdc.\n', filenames{i}); 
    end
    
else
    % Checking files individually
    for i = 1:length(filenames)
        if ismember(filenames{i},list)
            file_exist(i) = true;
            fprintf('File: %s exist in brdc.\n', filenames{i});
        else
            fprintf('File: %s not exist in brdc.\n', filenames{i});
        end
    end
end

fprintf('Control done: %d files will be downloaded.\n',sum(~file_exist));





