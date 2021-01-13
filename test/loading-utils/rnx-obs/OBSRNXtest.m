classdef OBSRNXtest < matlab.unittest.TestCase
    properties
        obsrnx
        obsrnxSatpos
        obsrnxqi
        antex
    end
    properties (TestParameter)
        % ts - test scenarios
        ts = {...
            {'G', 6,'C1C',  1, 25083226.133,' 6'};...
            {'G',10,'C2W',  1, 24493175.922,' 4'};...
            {'G',20,'L1C',  3,132267380.462,' 5'};...
            {'E',24,'C6X',  1, 21970068.082,' 8'};...
            {'C', 5,'C6I',  2, 39425319.414,' 6'};...
            {'C',05,'C2I',120, 39386539.219,' 6'};...
            {'C',08,'C2I',120, 38647743.266,' 6'};...
            {'C',26,'C2I',120, 22683220.930,' 8'};...
            {'C',29,'C2I',120, 22324835.641,' 8'};...
            {'C',30,'C2I',120, 24845596.305,' 7'};...
            {'E',02,'C1X',120, 26367452.125,' 7'};...
            {'E',03,'C1X',120, 26128050.578,' 7'};...
            {'E',24,'C1X',120, 22961005.094,' 8'};...
            {'E',25,'C1X',120, 22833748.602,' 8'};...
            {'E',36,'C1X',120, 28479993.398,' 6'};...
            {'G',02,'C1C',120, 24112060.641,' 7'};...
            {'G',06,'C1C',120, 23280674.828,' 7'};...
            {'G',24,'C1C',120, 20459277.734,' 8'};...
            {'G',25,'C1C',120, 22670106.602,' 7'};...
            {'G',32,'C1C',120, 23580804.664,' 7'};...
            {'R',05,'C1C',120, 22327635.805,' 7'};...
            {'R',06,'C1C',120, 22535240.086,' 6'};...
            {'R',13,'C1C',120, 23688968.953,' 5'};...
            {'R',23,'C1C',120, 21897345.828,' 7'};...
            {'R',24,'C1C',120, 20009300.430,' 7'};...
        };
        gnss = {'G','R','E','C'};
    end
    methods (TestClassSetup)
        function setupTest(obj)
            addpath(genpath('../../../src'));
            obj.obsrnx = OBSRNX('../../data/JAB1080M.19o');
            obj.antex = ANTEX('../../data/JABO_TRM55971.00_NONE_1440932194.atx');
            
            param = OBSRNX.getDefaults();
            param.parseQualityIndicator = true;
            obj.obsrnxqi = OBSRNX('../../data/JAB1080M.19o',param);
        end
    end
    methods (TestClassTeardown)
        function teardownTests(obj)
            close all
        end
    end
    methods (Test)
        function testConstructor(obj)
            obj.verifyEqual(size(obj.obsrnx.t,1),120);
        end
        function testHeaderParsing(obj)
            obj.verifyInstanceOf(obj.obsrnx.header,'OBSRNXheader')
        end
        function testObsTypesReading(obj)
            obj.verifyEqual(fieldnames(obj.obsrnx.header.obsTypes),cellstr(('CEGIRS')'))
            obj.verifyEqual(fieldnames(obj.obsrnx.obsTypes),cellstr(('CEGR')'))
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
        function testMakeSkyplotAssert(obj)
            % Method 'makeSkyplot' should raise assertion if 'satpos' element is empty
            % (no satellite positions are available)
            obj.verifyError(@() obj.obsrnx.makeSkyplot(),'ValidationError:SatellitePostionsNotAvailable')
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
                gnss_ = o.gnss(i);
                for j = 1:numel(o.sat.(gnss_))
                    prn = o.sat.(gnss_)(j);
                    [elev,azi,r] = o.getLocal(gnss_,prn);
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
            gnss_ = 'G';
            satNo = 13;
            obsType = 'L1C';
            pcvCorrType = 'PCV+PCO';
            
            % Sample data reading
        	o = OBSRNX('../../data/JABOtestAntennaCorrUnderHorizon.19o');
            o = o.computeSatPosition('broadcast','../../data/brdc');
            elev = o.getLocal(gnss_,satNo);
            underHorizonSel = elev < 0;
            
            % Apply PCV correction on measurements
            beforeCorr = o.getObservation(gnss_,satNo,obsType);
            o = o.correctAntennaVariation(obj.antex,pcvCorrType);
            afterCorr = o.getObservation(gnss_,satNo,obsType);
            
            obj.verifyNotEqual(beforeCorr,afterCorr);
            obj.verifyEqual(afterCorr(underHorizonSel),zeros(nnz(underHorizonSel),1))
        end
        function testPCVCorrectionApplication(obj)
            gnss_ = 'G';
            satNo = 12;
            obsType = 'L1C';
            pcvCorrType = 'PCV+PCO';
            
            % Sample data reading
        	o = OBSRNX('../../data/JABOtestAntennaCorr.19o');
            o = o.computeSatPosition('precise','../../data/eph');
            beforeRemoval = o.getObservation(gnss_,satNo,obsType);
            [elev,azi,~] = o.getLocal(gnss_,satNo);
            
            % Compute correction manually
            pcvCorrInMeters = obj.antex.getCorrection(gnss_,str2double(obsType(2)),[elev,azi],pcvCorrType);
            pcvCorrInCycles = pcvCorrInMeters/getWavelength(gnss_,str2double(obsType(2)),satNo);
            o = o.correctAntennaVariation(obj.antex,pcvCorrType);
            afterRemoval = o.getObservation(gnss_,satNo,obsType);
            obj.verifyEqual(afterRemoval-beforeRemoval,pcvCorrInCycles,'AbsTol',1e-5)
        end
        function testSaveToMAT(obj)
            o = OBSRNX('../../data/JABOtestAntennaCorrUnderHorizon.19o');
            o.recpos = [100,100,100];
            o = o.computeSatPosition('broadcast','../../data/brdc');
            o.saveToMAT('temp.mat');
            oMAT = OBSRNX.loadFromMAT('temp.mat');
            
            obj.verifyEqual(o.header,oMAT.header)
            obj.verifyEqual(o.t,oMAT.t)
            obj.verifyEqual(o.satpos,oMAT.satpos)
            obj.verifyEqual(o.obs,oMAT.obs)
            obj.verifyEqual(o.recpos,oMAT.recpos)
            
            % Cleanup
            if exist('temp.mat','file')
               delete temp.mat 
            end
        end
        function testRepairCycleSlip(obj)
            o = obj.obsrnx.computeSatPosition('broadcast','../../data/brdc');
            o = o.repairCycleSlips();
        end
        function testApplyCorrectionMap_NoCorrection(obj)
            corrMap = CorrectionMap.getZeroMap('G','L1C');
            obsrnxCorrected = obj.obsrnx.computeSatPosition('broadcast','../../data/brdc');
            origObs = obsrnxCorrected.getObservation('G',1,{'L1C'});
            obsrnxCorrected = obsrnxCorrected.applyCorrectionMap(corrMap);
            correctedObs = obsrnxCorrected.getObservation('G',1,{'L1C'});
            obj.verifyEqual(origObs,correctedObs);
        end
        function testApplyCorrectionMap_ConstantCorrection(obj)
            constantCorrection = 0.01; % Value in meters
            lam = 2.99792458e8/1575.42e6;
            corrMap = CorrectionMap.getConstantMap('G','L1C',constantCorrection);
            obsrnxCorrected = obj.obsrnx.computeSatPosition('broadcast','../../data/brdc');
            origObs = obsrnxCorrected.getObservation('G',1,{'L1C'});
            obsrnxCorrected = obsrnxCorrected.applyCorrectionMap(corrMap);
            correctedObs = obsrnxCorrected.getObservation('G',1,{'L1C'});
            correctedObs(correctedObs~=0) = correctedObs(correctedObs~=0) + constantCorrection/lam;
            obj.verifyEqual(origObs,correctedObs);
        end
        function testExportToFile(obj)
            gnsses = 'CEGR';
            decimate = 1;
            writeReceiverOffset = true;
            obj.obsrnx.exportToFile(fullfile(pwd(),'testOut.rnx'),gnsses,decimate,false);
            obj.obsrnx.exportToFile(fullfile(pwd(),'testOutWithOffsets.rnx'),gnsses,decimate,writeReceiverOffset);
            obj.obsrnxqi.exportToFile(fullfile(pwd(),'testOutWithQualityIndicators.rnx'));
        end
        function testMakeSkyplot(obj)
            backgroundFile = fullfile(pwd(),'../../other/skyplotTestBackground.png');
            transparency = 85;
            gnssSelection = 'GR';
            o = obj.obsrnx.computeSatPosition('broadcast','../../data/brdc');
            %o.saveToMAT(fullfile(pwd(),'testOut.mat'));
            %o = OBSRNX.loadFromMAT(fullfile(pwd(),'testOut.mat'));
            skyplot1 = o.makeSkyplot(); legend off;
            skyplot2 = o.makeSkyplot(gnssSelection); legend off;
            skyplot3 = o.makeSkyplot(gnssSelection,backgroundFile); legend off;
            skyplot4 = o.makeSkyplot(gnssSelection,backgroundFile,transparency); legend off;
            %skyplot3.exportToFile('c:\Users\petos\Documents\ST3_PhD\xxx.png','png',300)
        end
        function testMakeLocalSelection(obj)
            %o = obj.obsrnx.computeSatPosition('broadcast','../../data/brdc');
            %o.saveToMAT(fullfile(pwd(),'testOut.mat'));
            o = OBSRNX.loadFromMAT(fullfile(pwd(),'testOut.mat'));
            skyplot = o.makeSkyplot('G');
            regionElevation = [10 50 50 10 10];
            regionAzimuth = [90 90 180 180 90];
            %skyplot = skyplot.plotRegion(regionElevation,regionAzimuth);
            [satsNo,~] = o.getSatsInRegion('G',regionElevation,regionAzimuth);
            obj.assertEqual(satsNo,[2,6,13]);
        end
    end
    methods (Test, ParameterCombination='sequential')
        function testGetObservation(obj,ts)
            refVal = ts{5};
            actualVal = obj.obsrnx.getObservation(ts{1},ts{2},ts{3},ts{4});
            obj.verifyEqual(refVal,actualVal);
        end
        function testQualityIndicator(obj,ts)
            gnss_ = ts{1};
            prn_ = ts{2};
            prnIdx = find(obj.obsrnxqi.sat.(gnss_) == prn_);
            obsType_ = ts{3};
            obsTypeIdx = find(cellfun(@(x) strcmp(x,obsType_),obj.obsrnxqi.obsTypes.(gnss_)));
            obsTypeIdx = [2*obsTypeIdx-1, 2*obsTypeIdx];
            epoch_ = ts{4};
            
            testVal = obj.obsrnxqi.obsqi.(gnss_){prnIdx}(epoch_,obsTypeIdx);
            refVal = ts{6};
            obj.verifyEqual(testVal,refVal);
        end
        function testRemoveGNSS(obj,gnss)
            o = obj.obsrnx.removeGNSSs(gnss);
            refVal = obj.obsrnx.gnss;
            refVal = refVal(refVal ~= gnss);
            obj.verifyEqual(o.gnss,refVal);
        end
        function testRemoveSat(obj,ts)
            gnss_ = ts{1};
            prn_ = ts{2};
            satListRef = obj.obsrnx.sat.(gnss_)(obj.obsrnx.sat.(gnss_) ~= prn_);
            o = obj.obsrnx.removeSats(gnss_,prn_);
            obj.verifyEqual(o.sat.(gnss_),satListRef);
            
            oqi = obj.obsrnxqi.removeSats(gnss_,prn_);
            obj.verifyEqual(oqi.sat.(gnss_),satListRef);
        end
        function testRemoveObsType(obj,ts)
            gnss_ = ts{1};
            obsType_ = ts{3};
            obsTypesRef = obj.obsrnx.obsTypes.(gnss_)(cellfun(@(x) ~strcmp(x,obsType_),obj.obsrnx.obsTypes.(gnss_)));
            o = obj.obsrnx.removeObsTypes(gnss_,{obsType_});
            obj.verifyEqual(o.obsTypes.(gnss_),obsTypesRef);
            
            oqi = obj.obsrnxqi.removeObsTypes(gnss_,{obsType_});
            obj.verifyEqual(oqi.obsTypes.(gnss_),obsTypesRef);
        end
    end
end