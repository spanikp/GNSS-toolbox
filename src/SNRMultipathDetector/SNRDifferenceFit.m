classdef SNRDifferenceFit
    properties (SetAccess = protected)
        C12 (1,:) double
        C15 (1,:) double
        S (1,:) double
    end
    methods
        function obj = SNRDifferenceFit(C12,C15,S)
            validateattributes(C12,{'double'},{'size',[1,nan]},1);
            validateattributes(C15,{'double'},{'size',[1,nan]},2);
            validateattributes(S,{'double'},{'size',[1,nan]},3);
            obj.C12 = C12;
            obj.C15 = C15;
            obj.S = S;
        end
    end 
end