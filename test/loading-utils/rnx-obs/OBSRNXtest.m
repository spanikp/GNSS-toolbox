classdef OBSRNXtest < matlab.unittest.TestCase
    properties
        obsrnx
        antex
    end
    properties (TestParameter)
        % ts - test scenarios
        ts = {...
            {'G', 6,'C1C',1, 25083226.133};...
            {'G',10,'C2W',1, 24493175.922};...
            {'G',20,'L1C',3,132267380.462};...
            {'E',24,'C6X',1, 21970068.082};...
            {'C', 5,'C6I',2, 39425319.414};...
            {'C', 5,'C6I',2, 39425319.414};...
            {'C',05,'C2I',120,39386539.219};...
            {'C',08,'C2I',120,38647743.266};...
            {'C',13,'C2I',120,38403790.992};...
            {'C',14,'C2I',120,25646728.430};...
            {'C',24,'C2I',120,27062087.508};...
            {'C',26,'C2I',120,22683220.930};...
            {'C',29,'C2I',120,22324835.641};...
            {'C',30,'C2I',120,24845596.305};...
            {'E',02,'C1X',120,26367452.125};...
            {'E',03,'C1X',120,26128050.578};...
            {'E',05,'C1X',120,28223616.586};...
            {'E',08,'C1X',120,24563714.656};...
            {'E',11,'C1X',120,23864323.914};...
            {'E',12,'C1X',120,23357469.023};...
            {'E',18,'C1X',120,25250264.586};...
            {'E',24,'C1X',120,22961005.094};...
            {'E',25,'C1X',120,22833748.602};...
            {'E',33,'C1X',120,27751938.227};...
            {'E',36,'C1X',120,28479993.398};...
            {'G',02,'C1C',120,24112060.641};...
            {'G',06,'C1C',120,23280674.828};...
            {'G',12,'C1C',120,20243669.383};...
            {'G',14,'C1C',120,24925886.742};...
            {'G',15,'C1C',120,24844654.125};...
            {'G',17,'C1C',120,24037134.602};...
            {'G',19,'C1C',120,21799689.602};...
            {'G',24,'C1C',120,20459277.734};...
            {'G',25,'C1C',120,22670106.602};...
            {'G',29,'C1C',120,25193805.266};...
            {'G',32,'C1C',120,23580804.664};...
            {'R',05,'C1C',120,22327635.805};...
            {'R',06,'C1C',120,22535240.086};...
            {'R',13,'C1C',120,23688968.953};...
            {'R',14,'C1C',120,19972205.289};...
            {'R',15,'C1C',120,19994336.336};...
            {'R',16,'C1C',120,23843795.922};...
            {'R',17,'C1C',120,21287218.898};...
            {'R',23,'C1C',120,21897345.828};...
            {'R',24,'C1C',120,20009300.430};...
        };
    end
    methods (TestClassSetup)
        function setupTest(obj)
            addpath(genpath('../../../src'));
            obj.obsrnx = OBSRNX('../../data/JAB1080M.19o');
            obj.antex = ANTEX('../../data/JABO_TRM55971.00_NONE_1440932194.atx');
        end
    end
    methods (Test)
        function testConstructor(obj)
            obj.verifyEqual(size(obj.obsrnx.t,1),120);
        end
        function testHeaderParsing(obj)
            obj.verifyInstanceOf(obj.obsrnx.header,'OBSRNXheader')
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
        function testGetLocalNotSatposComputed(obj)
            [elev,azi,r] = obj.obsrnx.getLocal('G',1);
            obj.verifyEmpty(elev)
            obj.verifyEmpty(azi)
            obj.verifyEmpty(r)
        end
        function testGetLocal(obj)
            % Compute satellite positions
            ell = referenceEllipsoid('wgs84');
            o = obj.obsrnx;
            o.recpos = [ell.SemimajorAxis,0,0];
            o = o.computeSatPosition('broadcast','../../data/brdc');
            
            % Verify that invalid satNo or GNSS throws error
            obj.verifyError(@()o.getLocal('G',100),'MATLAB:validators:mustBeMember')
            obj.verifyError(@()o.getLocal('X',1),'MATLAB:unrecognizedStringChoice')
            
            % Proper value testing
            for i = 1:numel(o.gnss)
                gnss = o.gnss(i);
                for j = 1:numel(o.sat.(gnss))
                    prn = o.sat.(gnss)(j);
                    [elev,azi,r] = o.getLocal(gnss,prn);
                    if ~isempty(elev)
                        [x,y,z] = o.satpos(i).getECEF(prn);
                        sel = sum([x,y,z],2) ~= 0;
                        us = x(sel) - o.recpos(1);
                        ns = z(sel);
                        es = y(sel);
                        elevRef = atan2d(us,sqrt(es.^2 + ns.^2));
                        aziRef = rem(atan2d(es,ns)+360,360);
                        rRef = sqrt(us.^2 + ns.^2 + es.^2);
                        obj.verifyEqual(elevRef,elev(sel),'AbsTol',1e-5);
                        obj.verifyEqual(aziRef,azi(sel),'AbsTol',1e-5);
                        obj.verifyEqual(rRef,r(sel),'AbsTol',1e-5);
                    end
                end
            end
        end
        function testNoLocalCoordinationComputationTriggered(obj)
            o = obj.obsrnx;
            hdrRecpos = o.header.approxPos;
            o.recpos = [0,0,6378000]; % Any point on Z-axis is invalid recpos point
            
            % Invalid change of recpos should not change recpos property
            obj.verifyEqual(o.recpos,hdrRecpos)
        end
        function testPCVCorrectionApplicationUnderHorizon(obj)
            gnss = 'G';
            satNo = 13;
            obsType = 'L1C';
            pcvCorrType = 'PCV+PCO';
            
            % Sample data reading
        	o = OBSRNX('../../data/JABOtestAntennaCorrUnderHorizon.19o');
            o = o.computeSatPosition('broadcast','../../data/brdc');
            elev = o.getLocal(gnss,satNo);
            underHorizonSel = elev < 0;
            
            % Apply PCV correction on measurements
            beforeCorr = o.getObservation(gnss,satNo,obsType);
            o = o.correctAntennaVariation(obj.antex,'PCV+PCO');
            afterCorr = o.getObservation(gnss,satNo,obsType);
            
            obj.verifyNotEqual(beforeCorr,afterCorr);
            obj.verifyEqual(afterCorr(underHorizonSel),zeros(nnz(underHorizonSel),1))
        end
        function testPCVCorrectionApplication(obj)
            gnss = 'G';
            satNo = 12;
            obsType = 'L1C';
            pcvCorrType = 'PCV+PCO';
            
            % Sample data reading
        	o = OBSRNX('../../data/JABOtestAntennaCorr.19o');
            o = o.computeSatPosition('precise','../../data/eph');
            beforeRemoval = o.getObservation(gnss,satNo,obsType);
            [elev,azi,~] = o.getLocal(gnss,satNo);
            
            % Compute correction manually
            pcvCorr = obj.antex.getCorrection(gnss,str2double(obsType(2)),[elev,azi],pcvCorrType);
            o = o.correctAntennaVariation(obj.antex,pcvCorrType);
            afterRemoval = o.getObservation(gnss,satNo,obsType);
            obj.verifyEqual(afterRemoval-beforeRemoval,pcvCorr,'AbsTol',1e-5)
        end
    end
    methods (Test, ParameterCombination='sequential')
        function testGetObservation(obj,ts)
            refVal = ts{5};
            actualVal = obj.obsrnx.getObservation(ts{1},ts{2},ts{3},ts{4});
            obj.verifyEqual(refVal,actualVal);
        end
    end
end