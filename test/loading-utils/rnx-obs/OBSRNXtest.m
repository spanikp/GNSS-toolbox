classdef OBSRNXtest < matlab.unittest.TestCase
    properties
        obsrnx
    end
    methods (TestClassSetup)
        function setupPath(obj)
			addpath(genpath('../../../src'));
            obj.obsrnx = OBSRNX('../../data/JAB1080M.19o');
        end
    end
    methods (Test)
        function testConstructor(obj)
            obj.verifyEqual(size(obj.obsrnx.t,1),120);
        end
        function testHeaderParsing(obj)
            obj.verifyInstanceOf(obj.obsrnx.header,'OBSRNXheader')
        end
        function testGetObservation(obj)
            data = obj.obsrnx.getObservation('G',6,'L1C');
            obj.verifyEqual(data(1),131813231.844);
        end
        function testUpdateRecPosDxyz(obj)
            oldRecPos = obj.obsrnx.recpos;
            obj.obsrnx = obj.obsrnx.updateRecposWithIncrement([1,1,1],'dxyz');
            obj.verifyEqual(oldRecPos+[1,1,1],obj.obsrnx.recpos);
        end
        function testUpdateRecPosDenu(obj)
            oldRecPos = obj.obsrnx.recpos;
            dH = 100;
            obj.obsrnx = obj.obsrnx.updateRecposWithIncrement([0,0,dH],'denu');
            ell = referenceEllipsoid('wgs84');
            [lat,lon,~] = ecef2geodetic(oldRecPos(1),oldRecPos(2),oldRecPos(3),ell,'degrees');
            obj.verifyEqual(oldRecPos(1)+dH*cosd(lat)*cosd(lon),obj.obsrnx.recpos(1),'Abstol',1e-10);
            obj.verifyEqual(oldRecPos(2)+dH*cosd(lat)*sind(lon),obj.obsrnx.recpos(2),'Abstol',1e-10);
            obj.verifyEqual(oldRecPos(3)+dH*sind(lat),obj.obsrnx.recpos(3),'Abstol',1e-10);
        end
        function testComputeBrdc(obj)
            obj.obsrnx = obj.obsrnx.computeSatPosition('broadcast','../../data/brdc');
            obj.verifyInstanceOf(obj.obsrnx.satpos,'SATPOS');
        end
        function testComputePrecise(obj)
            obj.obsrnx = obj.obsrnx.computeSatPosition('precise','../../data/eph');
            obj.verifyInstanceOf(obj.obsrnx.satpos,'SATPOS');
        end
	end
end