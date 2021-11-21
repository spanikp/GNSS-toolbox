function dop_table = computeDOP_enu(input_file, rec_pos)
    validateattributes(input_file,{'char'},{'size',[1,nan]},1);
    validateattributes(rec_pos,{'double'},{'size',[1,3]},2);
    assert(exist(input_file,'file'));
    
    GNSS = {'G','R','E','C'};
    nGNSS = length(GNSS);
    
    d = readtable(input_file);
    d.t = datetime(d.t,'ConvertFrom','posixtime');
    d.gnss = cellfun(@(x) x(1), d.SatID);
    
    ell = referenceEllipsoid('wgs84');
    [lat0,lon0,h0] = ecef2geodetic(rec_pos(1),rec_pos(2),rec_pos(3),ell,'degrees');
    [d.E,d.N,d.U] = ecef2enu(d.X,d.Y,d.Z,lat0,lon0,h0,ell,'degrees');
    d.r = sqrt(sum([d.E,d.N,d.U].^2,2));
    %d.Enorm = d.E./d.r;
    %d.Nnorm = d.N./d.r;
    %d.Unorm = d.U./d.r;
    %[d.azimuth,d.elevation,~] = ecef2aer(d.X,d.Y,d.Z,lat0,lon0,h0,ell,'degrees');
    
    % Remove satellites under horizon
    d = d(d.U >= 0,:);
    
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
        nMinimumSats = 3 + length(unique(d.gnss(sel)));
        if nnz(sel) < nMinimumSats, continue; end 
        G = zeros(nnz(sel),nGNSS+3);
        
        % Fill geometry part of G
        ENUnorm = [d.E(sel),d.N(sel),d.U(sel)]./d.r(sel);
        G(:,1:3) = ENUnorm;
        G_all = [ENUnorm, ones(nnz(sel),1)];
        %G(:,4) = ones(nnz(sel),1);
        
        % Fill time part of G
        for iSatsys = 1:nGNSS
            sel_gnss = d.gnss(sel) == GNSS{iSatsys};
            G(sel_gnss,3+iSatsys) = ones(nnz(sel_gnss),1);
            %if nnz(sel_gnss) >= 4
            %    G = G_all(sel_gnss,:);
            %    Q = inv(G'*G);
            %    tdop(i,iSatsys+1) = sqrt(Q(4,4));
            %end
        end
        
        % Remove empty columns
        empty_gnss = find(all(G == 0)) - 3;
        G(:,all(G == 0)) = [];
        
        Q = inv(G'*G);
        Q_all = inv(G_all'*G_all);
        pdop(i) = sqrt(sum(trace(Q(1:3,1:3))));
        hdop(i) = sqrt(Q(1,1) + Q(2,2));
        vdop(i) = sqrt(Q(3,3));
        tdop(i,1) = sqrt(Q_all(4,4)); 
        tdop(i,1+setdiff(1:4,empty_gnss)) = sqrt(diag(Q(4:end,4:end)));
        gdop(i) = sqrt(sum(trace(Q_all)));
    end
    
    dop_table = table(posixtime(tUnique),pdop,hdop,vdop,gdop,tdop(:,1),tdop(:,2),...
        tdop(:,3),tdop(:,4),tdop(:,5),'VariableNames',...
        {'t','PDOP','HDOP','VDOP','GDOP','TDOP','TDOP_G','TDOP_R','TDOP_E','TDOP_C'});
end

