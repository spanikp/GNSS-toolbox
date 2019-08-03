function [head, body, listMerged] = mergeBroadcastMessages(fileList,folderEph,writeMerged)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to merge several navigation files defined in fileList which are
% stored in folder brdc! Function check for version of files (not merge
% files of different format v2 <-> v3 or GNSS system). If flag writeMerged
% is set to true then merged plain text file will be stored in cwd.
%
% Input:  fileList - list of RINEX nav. messages to merge:
%                    e.g. {'brdc1160.17n', 'brdc1170.17n'}
%                  - files have to be stored in brdc folder !
%  
%         writeMerged - flag to save merged content to file (true/false)
%
% Output: body - {N x 1} cell consisting of sum of all body lines in 
%                input files.
% 
%         head - contain header structure of first message
%
%         listMerged - cell contaning filenames of concenated files
%
% Peter Spanik, 10.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Print info
fprintf('\n>>> Merging files >>>\n')

% Initialize cells
merged_raw = cell(length(fileList),1);
listMerged = cell(length(fileList),1);

% Looping over input file list
for i = 1:length(fileList)
    filename = fileList{i};
    finp = fopen(fullfile(folderEph,filename),'r');
    raw = textscan(finp, '%s', 'Delimiter', '\n', 'Whitespace', '');
    raw = raw{1};
    [hdr, endOfHeaderIndex] = getNavigationHeader(raw);
    
    % First file determine format version and GNSS system
    if i == 1
        head = hdr;
        formatVersion = hdr.version; 
        GNSS = upper(filename(end));
        fprintf('Output body:   RNX v%d, "%s" navigation message\n', formatVersion, GNSS);
        fprintf('Merging file:  %s --> body\n', filename);
        merged_raw(i) = {raw(endOfHeaderIndex+1:end)};
        listMerged{i} = filename;
  
    else
        
        % Save to common structure only if the version is the same
        if hdr.version == formatVersion
            % Chceck if files are from the same system
            if upper(filename(end)) == GNSS
                fprintf('Merging file:  %s --> body\n', filename);
                merged_raw(i) = {raw(endOfHeaderIndex+1:end)};
                listMerged{i} = filename;
            else
                fprintf('Warning:       %s not "%s" message -> skipped!\n', filename, GNSS);
            end
        else
            fprintf('Warning:       %s not in RNX v%d format -> skipped!\n', filename, formatVersion);
        end
    end
    
    fclose(finp);
end

% Concatenate all files
body = vertcat(merged_raw{:});
listMerged(cellfun(@(x) isempty(x), listMerged)) = [];
fprintf('%s\nFiles merged:  %s\n',repmat('-',[1 72]),strjoin(listMerged,', '));

% If writeMerged flag is set
if writeMerged

    % Filename according to current time
    filenameOut = ['merged', datestr(now,'HHMMSS'), '.brdc'];
    
    % Write simple header
    fout = fopen(fullfile(folderEph,filenameOut),'w');
    fprintf(fout,'                 MERGED NEVIGATION MESSAGE                  COMMENT             \n');
    fprintf(fout,'MATLAB "mergeBroadcastMessage.m"        %20sPGM / RUN BY / DATE \n',datestr(now,'dd-mmm-yy HH:MM     '));
    fprintf(fout,'                                                            END OF HEADER       \n');
    
    % Writing every line of merged file
    for i = 1:length(merged_raw)
        fprintf(fout,'%s\n',body{i});
    end

    fclose(fout);
    fprintf('Merged file:   %s\n', filenameOut);

end