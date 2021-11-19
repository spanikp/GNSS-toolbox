function dop_table = computeDOP(input_file, rec_pos)
    validateattributes(input_file,{'char'},{'size',[1,nan]},1);
    validateattributes(rec_pos,{'double'},{'size',[1,3]},2);
    assert(exist(input_file,'file'));
    
    GNSS = {'G','R','E','C'};
    nGNSS = length(GNSS);
    
    [fi,la,~] = ecef2geodetic(rec_pos(1),rec_pos(2),rec_pos(3),referenceEllipsoid('wgs84'));
    R_xyz_enu = [-sin(la),  -sin(fi)*cos(la),  cos(fi)*cos(la);...
                  cos(la),  -sin(fi)*sin(la),  cos(fi)*sin(la);...
                  0,         cos(fi),          sin(fi)];
    
    d = readtable(input_file);
    d.t = datetime(d.t,'ConvertFrom','posixtime');
    d.gnss = cellfun(@(x) x(1), d.SatID);
    
    tUnique = unique(d.t);
    nEpochs = length(tUnique);
    
    % Initialize output
    pdop = nan(nEpochs,1);
    hdop = nan(nEpochs,1);
    vdop = nan(nEpochs,1);
    gdop = nan(nEpochs,1);
    tdop = nan(nEpochs,nGNSS+1);
    
    for i = 1:nEpochs
        tc = tUnique(i);
        sel = d.t == tc;
        if nnz(sel) < 4, continue; end
        G = zeros(nnz(sel),nGNSS+3);
        
        % Fill geometry part of G
        XYZ = [d.X(sel),d.Y(sel),d.Z(sel)];
        r = sqrt(sum((XYZ - rec_pos).^2,2));
        G(:,1:3) = XYZ./r;
        G_all = [XYZ./r, -ones(nnz(sel),1)];
        
        % Fill time part of G
        for iSatsys = 1:nGNSS
            sel_gnss = d.gnss(sel)==GNSS{iSatsys};
            if nnz(sel_gnss) >= 4
                G = G_all(sel_gnss,:);
                Q = inv(G'*G);
                tdop(i,iSatsys+1) = sqrt(Q(4,4));
            end
        end
        
        Q_all = inv(G_all'*G_all);
        Q_enu = R_xyz_enu'*Q_all(1:3,1:3)*R_xyz_enu;
        pdop(i) = sqrt(sum(trace(Q_all(1:3,1:3))));
        hdop(i) = sqrt(Q_enu(1,1) + Q_enu(2,2));
        vdop(i) = sqrt(Q_enu(3,3));
        tdop(i,1) = sqrt(Q_all(4,4));
        gdop(i) = sqrt(sum(trace(Q_all)));
    end
    
    dop_table = table(posixtime(tUnique),pdop,hdop,vdop,gdop,tdop(:,1),tdop(:,2),...
        tdop(:,3),tdop(:,4),tdop(:,5),'VariableNames',...
        {'t','PDOP','HDOP','VDOP','GDOP','TDOP','TDOP_G','TDOP_R','TDOP_E','TDOP_C'});
end

