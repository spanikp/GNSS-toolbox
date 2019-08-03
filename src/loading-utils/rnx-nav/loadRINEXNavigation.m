function brdc = loadRINEXNavigation(satsys,fileList)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to load navigation message in RINEX v2 (GPS, GLONASS) or RINEX 
% v3 format (GALILEO, BEIDOU). 
%
% Usage: brdc = loadRINEXNavigation('G','brdc1160.18n');
%
% Input:  satsys - system identifier (e.g. 'G')
%         filename - filename of navigation message. Navigation message
%                    have to be stored in brdc folder!
%
% Output: brdc - structure with the following fields
%           .gnss - character defining constellation (e.g. 'R')
%           .hdr - contains records from header (differs for systems)
%           .sat - [1 x n] matrix containing satellite numbers
%           .eph - {1 x n} cell with columns contaning all ephemeris.
%
%
% brdc.eph{n} cell has the following rows:
%
% ----+----------------+----------------+----------------+----------------+
% row |      GPS       |      GLO       |      GAL       |      BDS       |
% ----+----------------+----------------+----------------+----------------+
%   1 |                                year                               |
%   2 |                               month                               |
%   3 |                                day                                |
%   4 |                                hour                               |
%   5 |                               minute                              |
%   6 |                               second                              |
%   7 |                              GPS week                             |
%   8 |                         GPS second of week                        |
%   9 |                             Day of year                           |
%  10 |                             Day of week                           |
%  11 |                         Matlab datenum time                       |
% ----+----------------+----------------+----------------+----------------+
%  12 |  clock bias    |  clock bias    |  clock bias    |  clock bias    |
%  13 |  clock drift   | rel. fr. bias  |  clock drift   |  clock drift   |
%  14 |  drift rate    | mess.fr. time  |  drift rate    |  drift rate    |
%  15 |     IODE       |     X (km)     |    IOD nav     |     AODE       |
%  16 |      CRS       |   V_X (km/s)   |      CRS       |      CRS       |
%  17 |    Delta n     |  ACC_X (km/s2) |    Delta n     |    Delta n     |
%  18 |      M0        |  health (0=OK) |      M0        |      M0        |
%  19 |      CUC       |     Y (km)     |      CUC       |      CUC       |
%  20 |  eccentricity  |   V_Y (km/s)   |  eccentricity  |  eccentricity  |
%  21 |      CUS       |  ACC_Y (km/s2) |      CUS       |      CUS       |
%  22 |     a (m)      |  freq. number  |     a (m)      |     a (m)      |
%  23 |      TOE       |     Z (km)     |  TOE (Galileo) |  TOE (Beidou)  |
%  24 |      CIC       |   V_Z (km/s)   |      CIC       |      CIC       | 
%  25 |     OMEGA      |  ACC_Z (km/s2) |    OMEGA0      |    OMEGA0      | 
%  26 |      CIS       |   age (days)   |      CIS       |      CIS       | 
%  27 |      i0        |   ----------   |      i0        |      i0        |
%  28 |      CRC       |   ----------   |      CRC       |      CRC       |
%  29 |     omega      |   ----------   |     omega      |     omega      |
%  30 |   OMEGA DOT    |   ----------   |   OMEGA DOT    |   OMEGA DOT    |
%  31 |     i DOT      |   ----------   |      i DOT     |      i DOT     |
%  32 |  Codes on L2   |   ----------   |   Data source  |     spare      |
%  33 |   GPS Week #   |   ----------   |   GAL Week #   | Beidou Week #  |
%  34 | L2 P data flag |   ----------   |     spare      |     spare      |
%  35 |  SV accuracy   |   ----------   |    SISA (m)    |  SV accuracy   |
%  36 |   SV health    |   ----------   |   SV health    |     SatH1      |
%  37 |   TGD (sec)    |   ----------   | BGD E5a/E1(sec)| TGD1 B1/B3(sec)|
%  38 |     IODC       |   ----------   | BGD E5b/E1(sec)| TGD1 B2/B3(sec)|
%  39 |  trans. time   |   ----------   |  trans. time   |  trans. time   |
%  40 |fit interval(hr)|   ----------   |     spare      |      AODC      |
%  41 |     spare      |   ----------   |     spare      |     spare      |
%  42 |     spare      |   ----------   |     spare      |     spare      |
% ----+----------------+----------------+----------------+----------------+
%
% Peter Spanik, 9.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check input type: for one input    -> 'filename', 
%                   for more inputs  -> {'filename1', 'filename2'}
if ischar(fileList)
    fileList = {fileList};
end

% Check the input system identifier
if ~contains('GREC',satsys)
    fprintf('System %s is not supported GNSS identifier, uese one of ("GREC")!',satsys);
    brdc = [];
    return
end

% Initialize brdc structure
brdc = struct('hdr', struct(), 'sat', 0, 'gnss', satsys);

% Merging content of all input files and return raw body part
[head, body, filesMerged] = mergeBroadcastMessages(fileList, 0);
brdc.hdr = head;
brdc.files = filesMerged;

% Replace character 'D' -> 'e'
bodyBuffer = cellfun(@(x) replace(x,'D','e'), body,'UniformOutput',false);

% Extract information about satellites
if brdc.hdr.version == 2
    bodyBufferSel = bodyBuffer(cellfun(@(x) ~strcmp(x(1:2),'  '), bodyBuffer));
    sats = cellfun(@(x) sscanf(x(1:2),'%f'), bodyBufferSel);
    no = 1:2;           year_idx = 4:5;        month_idx = 7:8;      day_idx = 10:11;
    hour_idx = 13:14;   min_idx = 16:17;       sec_idx = 19:22;      
    f1 = 1:22;          f2 = 23:41;            f3 = 42:60;           f4 = 61:79;
elseif brdc.hdr.version == 3
    bodyBufferSel = bodyBuffer(cellfun(@(x) ~strcmp(x(2:3),'  '), bodyBuffer));
    sats = cellfun(@(x) sscanf(x(2:3),'%f'), bodyBufferSel);
    no = 2:3;           year_idx = 5:8;        month_idx = 10:11;    day_idx = 13:14;
    hour_idx = 16:17;   min_idx = 19:20;       sec_idx = 22:23;      
    f1 = 2:23;          f2 = 24:42;            f3 = 43:61;           f4 = 62:80;
end
sats(isnan(sats)) = [];
counts = sum(sats == sats')';
[sats, unique_idx] = unique(sats);
sats_counts = counts(unique_idx);
brdc.sat = sats';

% Initialize eph cell
brdc.eph = cell(1,length(brdc.sat));
for i = 1:length(brdc.eph)
    if strcmp(satsys,'R')
        brdc.eph{i} = zeros(26,sats_counts(i));
    else
        brdc.eph{i} = zeros(42,sats_counts(i));
    end
end

% Looping over the concatenated content
fprintf('\n>>> Loading content of merged file >>>\n')
SEP = zeros(size(brdc.sat));
carriageReturn = 0;
if satsys == 'R'
    step = 4; % Number of lines for one block of data
    block_init = zeros(26,1); % Eph block has 26 rows for GLONASS
    for i = 1:length(bodyBuffer)/step
        li = (i-1)*step+1;
        prn = sscanf(bodyBuffer{li}(no),'%f');
        idx = find(prn == brdc.sat);
        SEP(idx) = SEP(idx) + 1;
        
        %%%% Line 1
        block = block_init;
        tt = zeros(6,1);
        tt(1) = sscanf(bodyBuffer{li}(year_idx),'%f');
        tt(2) = sscanf(bodyBuffer{li}(month_idx),'%f');
        tt(3) = sscanf(bodyBuffer{li}(day_idx),'%f');
        tt(4) = sscanf(bodyBuffer{li}(hour_idx),'%f');
        tt(5) = sscanf(bodyBuffer{li}(min_idx),'%f');
        tt(6) = sscanf(bodyBuffer{li}(sec_idx),'%f');
        
        % Skip record if there is non-zero number of seconds !!!
        if tt(6) ~= 0 || (tt(5) ~= 15 && tt(5) ~= 45) 
            continue;
        end
        
        if brdc.hdr.version == 2
            tt(1) = tt(1) + 2000;
        end
        
        [GPSWeekNo, GPSSecond, DOY, DOW] = greg2gps(tt');
        
        mTime = datenum(tt');
        block(1:11) = [tt; GPSWeekNo; GPSSecond; DOY; DOW; mTime];
        block(12:14) = [sscanf(bodyBuffer{li}(f2),'%f');
            sscanf(bodyBuffer{li}(f3),'%f');
            sscanf(bodyBuffer{li}(f4),'%f')];
        %%%% Line 2
        block(15:18) = [sscanf(bodyBuffer{li+1}(f1),'%f');
            sscanf(bodyBuffer{li+1}(f2),'%f');
            sscanf(bodyBuffer{li+1}(f3),'%f');
            sscanf(bodyBuffer{li+1}(f4),'%f')];
        %%%% Line 3
        block(19:22) = [sscanf(bodyBuffer{li+2}(f1),'%f');
            sscanf(bodyBuffer{li+2}(f2),'%f');
            sscanf(bodyBuffer{li+2}(f3),'%f');
            sscanf(bodyBuffer{li+2}(f4),'%f')];
        %%%% Line 4
        block(23:26) = [sscanf(bodyBuffer{li+3}(f1),'%f');
            sscanf(bodyBuffer{li+3}(f2),'%f');
            sscanf(bodyBuffer{li+3}(f3),'%f');
            sscanf(bodyBuffer{li+3}(f4),'%f')];
        
        % Fast version of text waitbar
        if rem((i/round(length(bodyBuffer)/step,-3)),0.01) == 0
            if carriageReturn == 0
                fprintf('Loading nav RINEX: %3.0f %%',(i/round(length(bodyBuffer)/step,-3))*100);
                carriageReturn = 1;
            else
                fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\bLoading nav RINEX: %3.0f %%',(i/(length(bodyBuffer)/step))*100);
            end
        end
        
        % Assign block of ephemeris to structure
        block(isnan(block)) = 0;
        brdc.eph{idx}(:,SEP(idx)) = block;
    end
    
else
    step = 8; % Number of lines for one block of data
    block_init = zeros(42,1); % Eph block has 42 rows for other GNSS
    for i = 1:length(bodyBuffer)/step
        li = (i-1)*step+1;
        prn = sscanf(bodyBuffer{li}(no),'%f');
        idx = find(prn == brdc.sat);
        SEP(idx) = SEP(idx) + 1;
        
        %%%% Line 1
        block = block_init;
        tt = zeros(6,1);
        tt(1) = sscanf(bodyBuffer{li}(year_idx),'%f');
        tt(2) = sscanf(bodyBuffer{li}(month_idx),'%f');
        tt(3) = sscanf(bodyBuffer{li}(day_idx),'%f');
        tt(4) = sscanf(bodyBuffer{li}(hour_idx),'%f');
        tt(5) = sscanf(bodyBuffer{li}(min_idx),'%f');
        tt(6) = sscanf(bodyBuffer{li}(sec_idx),'%f');
        
        % Skip record if there is number of minutes = 30 -> skip HH:30:00 records
        % which have big differences (up to 20 meters from precise ephemeris)
        if satsys == 'G'
            if tt(5) ~= 0 && tt(5) ~= 59
                continue;
            end
        end
        
        if brdc.hdr.version == 2
            tt(1) = tt(1) + 2000;
        end
        
        [GPSWeekNo, GPSSecond, DOY, DOW] = greg2gps(tt');
        
        mTime = datenum(tt');
        block(1:11) = [tt; GPSWeekNo; GPSSecond; DOY; DOW; mTime];
        block(12:14) = [sscanf(bodyBuffer{li}(f2),'%f');
            sscanf(bodyBuffer{li}(f3),'%f');
            sscanf(bodyBuffer{li}(f4),'%f')];
        %%%% Line 2
        block(15:18) = [sscanf(bodyBuffer{li+1}(f1),'%f');
            sscanf(bodyBuffer{li+1}(f2),'%f');
            sscanf(bodyBuffer{li+1}(f3),'%f');
            sscanf(bodyBuffer{li+1}(f4),'%f')];
        %%%% Line 3
        block(19:22) = [sscanf(bodyBuffer{li+2}(f1),'%f');
            sscanf(bodyBuffer{li+2}(f2),'%f');
            sscanf(bodyBuffer{li+2}(f3),'%f');
            sscanf(bodyBuffer{li+2}(f4),'%f')^2];
        %%%% Line 4
        block(23:26) = [sscanf(bodyBuffer{li+3}(f1),'%f');
            sscanf(bodyBuffer{li+3}(f2),'%f');
            sscanf(bodyBuffer{li+3}(f3),'%f');
            sscanf(bodyBuffer{li+3}(f4),'%f')];
        %%%% Line 5
        block(27:30) = [sscanf(bodyBuffer{li+4}(f1),'%f');
            sscanf(bodyBuffer{li+4}(f2),'%f');
            sscanf(bodyBuffer{li+4}(f3),'%f');
            sscanf(bodyBuffer{li+4}(f4),'%f')];
        %%%% Line 6
        block(31:34) = [sscanf(bodyBuffer{li+5}(f1),'%f');
            sscanf(bodyBuffer{li+5}(f2),'%f');
            sscanf(bodyBuffer{li+5}(f3),'%f');
            sscanf(bodyBuffer{li+5}(f4),'%f')];
        %%%% Line 7
        block(35:38) = [sscanf(bodyBuffer{li+6}(f1),'%f');
            sscanf(bodyBuffer{li+6}(f2),'%f');
            sscanf(bodyBuffer{li+6}(f3),'%f');
            sscanf(bodyBuffer{li+6}(f4),'%f')];
        %%%% Line 8
        block(39:42) = [str2double(bodyBuffer{li+7}(f1));
            str2double(bodyBuffer{li+7}(f2));
            str2double(bodyBuffer{li+7}(f3));
            str2double(bodyBuffer{li+7}(f4))]; 
        
        
        % Fast version of text waitbar
        if rem(round(i/(length(bodyBuffer)/step),-3),0.01) == 0
            if carriageReturn == 0
                fprintf('Loading nav RINEX: %3.0f %%',(i/(length(bodyBuffer)/step))*100);
                carriageReturn = 1;
            else
                fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\bLoading nav RINEX: %3.0f %%',(i/(length(bodyBuffer)/step))*100);
            end
        end
    
        % Assign block of ephemeris to structure
        block(isnan(block)) = 0;
        brdc.eph{idx}(:,SEP(idx)) = block;
    end
end

fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\bLoading nav RINEX: done!\n');
