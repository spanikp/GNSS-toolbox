function satpvt = readGLABoutput(filepath)
    validateattributes(filepath,{'char'},{'size',[1,nan]},1);
    assert(isfile(filepath));
    
    % Define constants
    GNSS_char_map = containers.Map({'GPS','GLO','GAL','BDS'},{'G','R','E','C'});
    
    % Initialize output
    satpvt = [];
    
    % Open file for reading
    fid = fopen(filepath,'r');
    lines = textscan(fid,'%s','Delimiter','\n','Whitespace','');
    lines = lines{1};
    fclose(fid);    
    
    % Parse header (determine which version of gLAB was used to create file)
    infoLines = lines(cellfun(@(x) startsWith(x,'INFO'),lines));
    if isempty(infoLines), error('Not possible to determine gLAB output file format version!'); end
    glab_version = [];
    for i = 1:length(infoLines)
        ver_idx = strfind(infoLines{i},'INFO gLAB version v');
        if ~isempty(ver_idx)
            glab_version = str2double(infoLines{i}(20));
            break; 
        end 
    end
    assert(ismember(glab_version,[5,6]),'Not supported gLAB output version!');
    
    satpvt_columns = {'Year','Doy','SecondOfDay','GNSS','PRN','X','Y','Z','VX','VY','VZ'};
    switch glab_version
        case 5
            format_str = '%s %f %f %f %s %f %f %f %f %f %f %f %f';
            data_map = containers.Map(satpvt_columns,{2,3,4,5,6,7,8,9,10,11,12});
        case 6
            format_str = '%s %f %f %f %s %s %f %s %f %f %f %f %f %f %f %f %f %f %f %f %f %s %f %s';
            data_map = containers.Map(satpvt_columns,{2,3,4,6,7,12,13,14,15,16,17});
    end
    
    % Extract satpvt lines
    satpvtLines = lines(cellfun(@(x) startsWith(x,'SATPVT'),lines));
    if ~isempty(satpvtLines)
        tmp_satpvt_file = tempname();
        fout = fopen(tmp_satpvt_file,'w');
        cellfun(@(x) fprintf(fout,'%s\n',x),satpvtLines);
        fclose(fout);
        f2 = fopen(tmp_satpvt_file,'r');
        tmp = textscan(f2,format_str);
        fclose(f2);
        
        % Cut not needed satellite systems
        selValid_gnss = ismember(tmp{data_map('GNSS')},GNSS_char_map.keys);
        for i = 1:length(data_map)
            satpvt_column = satpvt_columns{i};
            if strcmp(satpvt_column,'GNSS')
                satpvt.(satpvt_column) = cellfun(@(x) {GNSS_char_map(x)},tmp{data_map(satpvt_column)}(selValid_gnss));
            else
                satpvt.(satpvt_column) = tmp{data_map(satpvt_column)}(selValid_gnss);
            end
        end
        
        % Convert output struct to table
        satpvt = struct2table(satpvt);
    end
end

