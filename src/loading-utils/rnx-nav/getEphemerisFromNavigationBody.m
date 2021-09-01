function [eph,sats] = getEphemerisFromNavigationBody(body,satsys,brdcVersion)

validateattributes(body,{'cell'},{'size',[nan,1]},1);
validateattributes(satsys,{'char'},{'size',[1,1]},2);
mustBeMember(satsys,'GREC');
validateattributes(brdcVersion,{'double'},{'size',[1,1]},3);
mustBeMember(brdcVersion,[2,3]);


% Replace character 'D' -> 'e'
bodyBuffer = cellfun(@(x) replace(x,'D','e'), body,'UniformOutput',false);

% Extract information about satellites
if brdcVersion == 2
    bodyBufferSel = bodyBuffer(cellfun(@(x) ~strcmp(x(1:2),'  '), bodyBuffer));
    sats = cellfun(@(x) sscanf(x(1:2),'%f'), bodyBufferSel);
    no = 1:2;           year_idx = 4:5;        month_idx = 7:8;      day_idx = 10:11;
    hour_idx = 13:14;   min_idx = 16:17;       sec_idx = 19:22;      
    f1 = 1:22;          f2 = 23:41;            f3 = 42:60;           f4 = 61:79;
elseif brdcVersion == 3
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
sats = sats';

% Initialize eph cell
eph = cell(1,length(sats));
for i = 1:length(eph)
    if strcmp(satsys,'R')
        eph{i} = zeros(26,sats_counts(i));
    else
        eph{i} = zeros(42,sats_counts(i));
    end
end

% Looping over the concatenated content
fprintf('\n>>> Loading content of merged file >>>\n')
SEP = zeros(size(sats));
carriageReturn = 0;
if satsys == 'R'
    step = 4; % Number of lines for one block of data
    block_init = zeros(26,1); % Eph block has 26 rows for GLONASS
    for i = 1:length(bodyBuffer)/step
        li = (i-1)*step+1;
        prn = sscanf(bodyBuffer{li}(no),'%f');
        idx = find(prn == sats);
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
        %if tt(6) ~= 0 || (tt(5) ~= 15 && tt(5) ~= 45) 
        %    continue;
        %end
        
        if brdcVersion == 2
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
        eph{idx}(:,SEP(idx)) = block;
    end
    
else
    step = 8; % Number of lines for one block of data
    block_init = zeros(42,1); % Eph block has 42 rows for other GNSS
    for i = 1:length(bodyBuffer)/step
        li = (i-1)*step+1;
        prn = sscanf(bodyBuffer{li}(no),'%f');
        idx = find(prn == sats);
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
        
        if brdcVersion == 2
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
        bodyBuffer{li+5} = pad(bodyBuffer{li+5},80);
        if strcmp(bodyBuffer{li+5}(f2),'                   '), bodyBuffer{li+5}(f2) = ' 0.000000000000e+00'; end
        if strcmp(bodyBuffer{li+5}(f4),'                   '), bodyBuffer{li+5}(f4) = ' 0.000000000000e+00'; end
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
        nFieldsLine8 = round((length(bodyBuffer{li+7})-4)/19);
        if nFieldsLine8 == 4
            block(39:42) = [str2double(bodyBuffer{li+7}(f1));
                str2double(bodyBuffer{li+7}(f2));
                str2double(bodyBuffer{li+7}(f3));
                str2double(bodyBuffer{li+7}(f4))];
        elseif nFieldsLine8 == 3
            block(39:42) = [str2double(bodyBuffer{li+7}(f1));
                str2double(bodyBuffer{li+7}(f2));
                str2double(bodyBuffer{li+7}(f3)); 0];
        elseif nFieldsLine8 == 2
            block(39:42) = [str2double(bodyBuffer{li+7}(f1));
                str2double(bodyBuffer{li+7}(f2)); 0; 0];
        elseif nFieldsLine8 == 1
            block(39:42) = [str2double(bodyBuffer{li+7}(f1)); 0; 0; 0];
        else 
            error('Not valid navigation RINEX format!');
        end
        
        
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
        eph{idx}(:,SEP(idx)) = block;
    end
end

fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\bLoading nav RINEX: done!\n');