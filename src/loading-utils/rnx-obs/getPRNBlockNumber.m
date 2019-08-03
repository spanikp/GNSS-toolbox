function sat_block = getPRNBlockNumber(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to assign block number/orbit type to given PRN according to 
% table from ftp://ftp.aiub.unibe.ch/BSWUSER52/GEN/SATELLIT.I14. Before use
% it is highly recommended to look on the source table and resolve 
% possible difference issues !!! 
%
% Last revision: 29.5.2018
%
% For GALILEO satellites information is combined with:
% https://www.gsc-europa.eu/system-status/Constellation-Information
%
% For BEIDOU, information from IGS website were used:
% http://mgex.igs.org/IGS_MGEX_Status_BDS.php
% 
% Usage: BlockNumber = getPRNBlockNumber(18)      <- default use without specification of satellite system (GPS)
%                    = getPRNBlockNumber(18,'R')  <- specification of satellite system (one of 'GREC')
%
% Input:  satsys - GNSS system identifier (one of 'GREC')
%         prn    - [1 x n] array of satellite PRN numbers from RINEX
%
% Output: sat_block - [1 x n] array initialized to NaN (in case PRN number
%                  is not listed in any of the satellite blocks).
%                - values differs according to satellite systems:
%  
% GPS:      1: BLOCK I
%           2: BLOCK II
%           3: BLOCK IIA
%           4: BLOCK IIR
%           5: BLOCK IIR-A
%           6: BLOCK IIR-B
%           7: BLOCK IIR-M
%           8: BLOCK IIF
%
% GLONASS:  101: GLONASS
%           102: GLONASS-M
%           103: GLONASS-K1
% 
% GALILEO:  201: MEO, Plane A
%           202: MEO, Plane C
%           203: MEO, Plane B
%           299: Inclined orbits (E14,E18)
%
% BEIDOU:   401: MEO
%           402: IGSO
%           403: GEO
%
% Peter Spanik, 29.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Resolve number of inputs
if nargin == 1
    prn = varargin{1};
    satsys = 'G';
elseif nargin == 2
    prn = varargin{1};
    satsys = varargin{2};
end

% Initialize output
sat_block = nan(size(prn));

% Switch according to satellite system
switch satsys
    %%%%% GPS satellite blocks
    case 'G'
        sat_blocks = {[];                                   % 1: BLOCK I
            [];                                             % 2: BLOCK II
            [18];                                           % 3: BLOCK IIA
            [];                                             % 4: BLOCK IIR
            [11, 13, 14, 16, 20, 21, 28];                   % 5: BLOCK IIR-A
            [2, 19, 22, 23];                                % 6: BLOCK IIR-B
            [4, 5, 7, 15, 17, 29, 31];                      % 7: BLOCK IIR-M
            [1, 3, 6, 8, 9, 10, 12, 24, 25, 26, 27, 30, 32] % 8: BLOCK IIF
            };
        block_numbers = 1:8;
        
    %%%%% GLONASS satellite blocks
    case 'R'
        sat_blocks = {[];                                                           % 101: GLONASS
            [1, 2, 3, 4, 5, 6,7,8,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24];    % 102: GLONASS-M
            [9,26];                                                                 % 103: GLONASS-K1
            };
        block_numbers = [101, 102, 103];
    
    %%%%% GALILEO Plane numbers    
    case 'E'
        sat_blocks = {
            [1,2,21,24,25,27,30,31];      % 201: MEO, Plane A
            [3,4,5,7,8,9,19,20];          % 202: MEO, Plane C
            [11,12,22,26];                % 203: MEO, Plane B
            [14,18];                      % 299: Inclined orbits (E14,E18)
            };
        block_numbers = [201, 202, 203, 299];
        
    %%%%% BEIDOU Plane numbers / orbit types   
    case 'C'
        sat_blocks = {
            [10:32];      % 401: MEO
            [6:9];        % 402: IGSO
            [1:5];        % 403: GEO
            };
        block_numbers = [401, 402, 403];
    
    otherwise
        return;
end

% Looping throught the satellites in input array
for p = 1:length(prn)
    for i = 1:length(sat_blocks)
        if ismember(prn(p),sat_blocks{i})
            sat_block(p) = block_numbers(i);
        end
    end
end