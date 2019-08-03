function GNScell = findGNSTypes(data)

% Selection criteria
sel = cellfun(@(c) strcmp('=GNSSYS',c(1:7)), data);

% Extract GNS names based on selection
selText = cellfun(@(c) c(37:end), data(sel), 'UniformOutput', 0);
GNScell = strsplit(selText{1},' ');






