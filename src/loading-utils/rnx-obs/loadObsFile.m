function obsData = loadObsFile(filepath,satsys,saving)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to load observation data in Matlab MAT or text RINEX format.
%
% Input:
% filepath - path to RINEX/MAT files
% satsys - sat. system to load (default is 'GREC')
% saving - true/false flag to loaded file in MAT format (default true)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set defaults
if nargin == 1
    satsys = 'GREC';
    saving = true;
elseif nargin == 2
    saving = true;
end

% Split the filename and extract extension
[splitted,filename,ext] = fileparts(filepath);

% Decide if load Matlab MAT file or text RINEX file
if strcmpi(ext,'.mat')
    obsData = load(filepath);
    obsData = obsData.obsData;
    fprintf('MAT file "%s" loaded.\n',filepath);
    
elseif regexp(lower(ext),'.[0-9][0-9][oO]')
    obsData = loadRINEXObservation(filepath,satsys);
    obsData = getBroadcastPosition(obsData);
    fprintf('RINEX file "%s" loaded.\n',filepath);
    
    % Save loaded file as MAT file
    if saving
        outMatFileName = fullfile(splitted,[filename '.mat']);
        fprintf('\nSaving MAT file to "%s"\n',outMatFileName);
        save(outMatFileName,'obsData');
    end
end
