function [hdr, endOfHeaderIndex] = getNavigationHeader(raw)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to read header of RINEX navigation message. Function return
% header structure with the field according to satellite system. 
%
% Input:  raw - is cell {n x 1} of raw navigation message text loaded by 
%               textscan function (n is number of all lines in RINEX 
%               navigation file).
%
% Output: hdr - header structure with various fields according to satellite
%               system. Field "version" is common for all messages and
%               refer to RINEX file version.
%
%         endOfHeaderIndex - index of line containing "END OF HEADER"
%
% Usage:  finp = fopen('brdc1160.18n','r');
%         raw  = textscan(finp, '%s', 'Delimiter', '\n', 'Whitespace', '');
%         raw = raw{1};
%         [hdr, endOfHeaderIndex] = getNavigationHeader(raw); 
%
% Peter Spanik, 10.5.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Parsing header
lineIndex = 0;
while 1
    lineIndex = lineIndex + 1;
    line = raw{lineIndex};
    
    % Get version information
    if contains(line,'RINEX VERSION / TYPE')
        hdr.version = round(str2double(line(1:20)));
    end   
    
    % Get leap seconds information from header
    if contains(line,'LEAP SECONDS')
        hdr.leapSeconds = str2double(line(1:20));
    end 
    
    if contains(line,'ION ALPHA')
        hdr.ionoAlpha = cell2mat(textscan(line(1:60),'%f %f %f %f'));
    end   
    
    if contains(line,'ION BETA')
        hdr.ionoBeta = cell2mat(textscan(line(1:60),'%f %f %f %f'));
    end  
    
    if contains(line,'CORR TO SYSTEM TIME')
        hdr.timeCorr = sscanf(line(1:60),'%f');
    end  
    
    % Breaks if lineIndex reaches 'END OF HEADER'
    if contains(line,'END OF HEADER')
        break
    end
end

% Assign endOfHeaderIndex variable
endOfHeaderIndex = lineIndex;
