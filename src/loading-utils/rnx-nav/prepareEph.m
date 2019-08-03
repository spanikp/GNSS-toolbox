function prepareEph(gnss,ephType,folderEph,timeFrame)
    for i = 1:numel(gnss)
        s = gnss(i);
        switch ephType
            case 'broadcast'
                navMessageList.(s) = downloadBroadcastData(s,timeFrame,folderEph);
                      
                % Load RINEX message to Matlab and check for duplicity
                brdc(i) = loadRINEXNavigation(s,folderEph,navMessageList.(s));
                brdc(i) = checkEphStatus(brdc(i));

            case 'precise'
                
        end
    end
    a = 1;
end