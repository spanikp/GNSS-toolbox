classdef SNRCalibrationMode < int32
    enumeration
        ALL(0)
        BLOCK(1)
        INDIVIDUAL(2)      
    end
    methods
        function out = toString(obj)
            switch obj
                case SNRCalibrationMode.ALL
                    out = 'all';
                case SNRCalibrationMode.BLOCK
                    out = 'block';
                case SNRCalibrationMode.INDIVIDUAL
                    out = 'individual';
            end
        end
    end
end