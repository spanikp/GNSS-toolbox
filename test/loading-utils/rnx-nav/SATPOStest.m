classdef SATPOStest < matlab.unittest.TestCase
    properties (TestParameter)
        gnss = {'G','R','E','C'};
        ephRefSats = {1,1,1,6};
        ephRefPos = {...
             [ 21205.926710  11935.849328  10843.520838]*1e3,...
             [ 15869.795086 -19561.833554  -3964.297825]*1e3,...
             [ 15082.943039  13716.981791 -21463.750213]*1e3,...
             [-23389.162333  26622.342618  22879.979580]*1e3};
        ephTypeAndFolder = {...
            {'broadcast','../../data/brdc'};
            {'precise',  '../../data/eph'}};
    end
    methods (TestClassSetup)
        function setupPath(obj)
			addpath(genpath('../../../src'));
        end
    end
    methods (Test, ParameterCombination='exhaustive')
        function testConstructorBasic(obj,gnss,ephTypeAndFolder)
            [GPS1w,GPS1s] = greg2gps([2019,3,21,2,15,18]);
            [GPS2w,GPS2s] = greg2gps([2019,3,21,4,15,18]);
            GPSTimeFrame = [GPS1w,GPS1s; GPS2w,GPS2s];
            [gpsWeek,gpsSecond] = getGPSTimeBetween(GPSTimeFrame,1800);
            SATPOS(gnss,1,ephTypeAndFolder{1},ephTypeAndFolder{2},[gpsWeek,gpsSecond]);
        end
    end 
    methods (Test, ParameterCombination='sequential')
        function testPreciseWithVerify(obj,gnss,ephRefSats,ephRefPos)
            [GPS1w,GPS1s] = greg2gps([2019,3,21,2,0,0]);
            [GPS2w,GPS2s] = greg2gps([2019,3,21,4,0,0]);
            GPSTimeFrame = [GPS1w,GPS1s; GPS2w,GPS2s];
            [gpsWeek,gpsSecond] = getGPSTimeBetween(GPSTimeFrame,100);
            satpos = SATPOS(gnss,ephRefSats,'precise','../../data/eph',[gpsWeek,gpsSecond]);
            [x,y,z] = satpos.getECEF(ephRefSats);
            obj.verifyEqual([x(1),y(1),z(1)],ephRefPos);
        end
    end
    methods (Test)
        function testComputeLocal(obj)
            ephType = 'broadcast';
            ephFolder = '../../data/brdc';
            [GPSweek,GPSsec] = greg2gps([2019,3,21,2,15,18]);
            ell = referenceEllipsoid('wgs84');
            satpos = SATPOS('G',1,ephType,ephFolder,[GPSweek,GPSsec],[ell.SemimajorAxis,0,0]);
            us = satpos.ECEF{1}(1) - ell.SemimajorAxis;
            ns = satpos.ECEF{1}(3);
            es = satpos.ECEF{1}(2);
            elevs = atan2d(us,sqrt(es.^2 + ns.^2));
            azis = rem(atan2d(es,ns)+360,360);
            rs = sqrt(us.^2 + ns.^2 + es.^2);
            obj.verifyEqual(elevs,satpos.local{1}(:,1),'RelTol',1e-14);
            obj.verifyEqual(azis,satpos.local{1}(:,2),'RelTol',1e-14);
            obj.verifyEqual(rs,satpos.local{1}(:,3),'RelTol',1e-14);
        end
        function testNotComputeLocal(obj)
            [GPSweek,GPSsec] = greg2gps([2019,3,21,2,15,18]);
            s = SATPOS('G',[1,2,80],'broadcast','../../data/brdc',[GPSweek,GPSsec]);
            obj.verifyEqual(s.satList,[1,2])
            obj.verifyEmpty(s.local)
        end
        function testLoadMultiGNSSbroadcastFile(obj)
            f = '../../data/multiGNSSbrdc/BRDC00GOP_R_20141740000_01D_MN.rnx'; % Multi-GNSS navigation RINEX file
            [gpstWeek,gpstSecond] = getGPSTimeBetween([1798,86400;1798,172800],300); % Define timestamps where to compute satellite positions
            satpos = SATPOS.fromMultiNavRINEX(f,[gpstWeek,gpstSecond],'GEC');
            
            % How to get ECEF corrdinates
            gnssIdx = 1; % satpos is array of elements gnssIdx: 1='G', 2='E', 3='C'
            satNo = 1;   % Specify sat. number you want to get coordinates
            [x,y,z] = satpos(gnssIdx).getECEF(satNo);
        end
    end
end