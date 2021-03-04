classdef SNRFitParameters
    properties (SetAccess = protected)
        fitC12 (1,:) double
        fitC15 (1,:) double
        fitS (1,:) double
        
        sigmaC12 (1,1) double
        sigmaC15 (1,1) double
        sigmaS (1,1) double
    end
    methods
        function obj = SNRDifferenceFit(fitC12,fitC15,fitS,sigmaC12,sigmaC15,sigmaS)
            validateattributes(fitC12,{'double'},{'size',[1,nan]},1);
            validateattributes(fitC15,{'double'},{'size',[1,nan]},2);
            validateattributes(fitS,{'double'},{'size',[1,nan]},3);
            obj.fitC12 = fitC12;
            obj.fitC15 = fitC15;
            obj.fitS = fitS;
            
            obj.sigmaC12 = sigmaC12;
            obj.sigmaC15 = sigmaC15;
            obj.sigmaS = sigmaS;
        end
    end 
end