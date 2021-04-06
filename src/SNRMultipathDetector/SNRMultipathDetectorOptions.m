classdef SNRMultipathDetectorOptions
    properties
        gnss (1,1) char {mustBeMember(gnss,{'G','R','E','C'})} = 'G'
        snrIdentifiers (1,:) cell = {'S1C','S2W','S5X'}
        fitByOptimization (1,1) logical = false
        polyOrders (1,3) double {mustBePositive, mustBeInteger} = [3,3,3]
        funcs (1,3) cell = {...
            @(x,p) p(1)*x.^3 + p(2)*x.^2 + p(3)*x.^3 + p(4),...
            @(x,p) p(1)*x.^3 + p(2)*x.^2 + p(3)*x.^3 + p(4),...
            @(x,p) p(1)*x.^3 + p(2)*x.^2 + p(3)*x.^3 + p(4)}
        snrDifferenceSmoothing (1,3) double {mustBePositive, mustBeInteger} = [1,1,1]
        elevBinsMinimal (1,3) double {mustBePositive, mustBeInteger} = [10,10,20]
        coeffEnoughFitData (1,1) double {mustBePositive, mustBeInteger} = 1
        verbosity (1,1) double {mustBePositive, mustBeInteger} = 1
    end
    methods
        function obj = set.funcs(obj,funcs)
            validateattributes(funcs,{'cell'},{'size',[1,3]},2);
            for i = 1:3
                assert(isa(funcs{i},'function_handle'),'Input cell has to contains function handles!');
                assert(startsWith(func2str(funcs{i}),'@(x,p)'),'Incorrect function handle definition, has to match pattern: "@(x,p)"!');
            end
            obj.funcs = funcs;
        end
        function obj = set.snrIdentifiers(obj,snrIdentifiers)
            assert(ismember(size(snrIdentifiers,2),[2,3]),'SNR identifiers can be (1,2) or (1,3) cell of chars!');
            assert(length(unique(snrIdentifiers))==length(snrIdentifiers),'SNR identifiers have to be unique!');
            assert(all(cellfun(@(x) length(x)==3,snrIdentifiers)),'Not valid SNR identifier!');
            assert(all(cellfun(@(x) x(1)=='S' & isstrprop(x(2),'digit') & isstrprop(x(3),'alpha'),...
                snrIdentifiers)),'Not valid SNR identifier!');
            obj.snrIdentifiers = snrIdentifiers;
        end
    end
end