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