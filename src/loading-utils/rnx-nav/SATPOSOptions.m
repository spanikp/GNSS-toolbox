classdef SATPOSOptions
    properties
        removeUnhealthySats (1,1) logical = true
        % By default computations with unhealthy satellites are skipped
        
        assumeEphemerisAge (1,1) logical = true
        % By default SATPOS calculation are performed only for ephemeris
        % blocks within some critical age, if this is set to false, then
        % critical ephemeris age is not taken into account
    
        criticalEphemerisAge (:,1) containers.Map
        % Define critical ephemeris age in days to be used when satellite
        % positions are computed from broadcast ephemeris.
        % See constructor for default values for all GNSS systems.
        
        brdcEphemerisComputationDirection (1,:) char {mustBeMember(brdcEphemerisComputationDirection,{'backward','forward','closest'})} = 'backward'
        % Flag to setup selection of GPS, Galileo and Beidou broadcast ephemeris
        % data block. Ephemeris blocks are selected as following:
        %
        %  'backward' - tk (time of ephemeris) will be always negative (tk < 0)
        %             - selected ephemeris reference time is after computation time
        %  'forward'  - tk will be always positive (tk > 0)
        %             - selected ephemeris reference time is before computation time
        %  'closest'  - tk can be positive or negative, depends on which ephemeris
        %               block is closer to given computation time
        %             - selected ephemeris reference time is closest to computation time
        %
        % According GPS-ICD we should always use ephemeris such that tk < 0
    end
    methods
        function obj = SATPOSOptions(obj)
            obj.criticalEphemerisAge = containers.Map({'G','R','E','C'},[2.1, 0.8, 1.5, 2.5]/24);
        end
    end
    methods (Static)
        function obj = fromStruct(s)
            validateattributes(s,{'struct'},{'size',[1,1]},1);
            obj = struct2obj(s,SATPOSOptions);
        end
    end
end