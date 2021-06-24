function checkGivenObservationType(rinexVersion,obsType,obsCode)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to validate if observation is valid observation code 
% Valid observation IDs for pseudorange and for SNR are taken from RINEX
% specification documents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

assert(ismember(obsType(1),{'C','S'}),...
    sprintf('Not valid observation category "%s": Only "C" (pseudorange) or "S" (SNR) available!',obsType(1)));

switch rinexVersion
    case 2
        requiredObsCodeLength = 2;
        validPseudorangeIDs = {'C1','P1','C2','P2','C5','C6','C7','C8'};
        validSNRIDs = {'S1','S2','S5','S6','S7','S8'};
    case 3
        requiredObsCodeLength = 3;
        validPseudorangeIDs = {'C1C','C1P','C1S','C1X','C1P','C1W','C1Y',...
            'C1M','C2C','C2D','C2S','C2L','C2X','C2P','C2W','C2Y','C2M',...
            'C5I','C5Q','C5X','C4A','C4B','C4X','C6A','C6B','C6X','C3I',...
            'C3Q','C3X','C1A','C1B','C1Z','C7I','C7Q','C7X','C8I','C8Q',...
            'C8X','C6C','C6X','C6Z','C1L','C5D','C5P','C5Z','C6S','C6L',...
            'C6E','C2I','C2Q','C1D','C1P','C7D','C7P','C7Z','C8D','C8P',...
            'C6I','C6Q','C6D','C6P','C5A','C5B','C5C','C9A','C9B','C9C','C9X'};
        validSNRIDs = cellfun(@(x) ['S',x(2:3)],validPseudorangeIDs,'UniformOutput',false);
end

assert(length(obsCode)==requiredObsCodeLength,'Invalid observation code "%s" for RINEX v%d (%d characters identifier needed)!',...
    obsCode,rinexVersion,requiredObsCodeLength);

switch obsType
    case 'C'
        assert(ismember(obsCode,validPseudorangeIDs),'Not valid pseudorange observation code "%s" for RINEX v%d!',obsCode,rinexVersion);
    case 'S'
        assert(ismember(obsCode,validSNRIDs),'Not valid SNR observation code "%s" for RINEX v%d!',obsCode,rinexVersion);
end


