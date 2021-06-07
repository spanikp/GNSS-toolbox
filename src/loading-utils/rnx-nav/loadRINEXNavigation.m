function brdc = loadRINEXNavigation(satsys,folderEph,fileList)
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
[head, body, filesMerged] = mergeBroadcastMessages(fileList,folderEph,0);
brdc.hdr = head;
brdc.files = filesMerged;

% Parse actual content of RINEX navigation file
[brdc.eph, brdc.sat] = getEphemerisFromNavigationBody(body,satsys,brdc.hdr.version);

