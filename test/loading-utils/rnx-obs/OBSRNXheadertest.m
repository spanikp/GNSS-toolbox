classdef OBSRNXheadertest < matlab.unittest.TestCase
    properties
        hdr
    end
    methods (TestClassSetup)
        function obj = setupPath(obj)
			addpath(genpath('../../../src'));
            obj.hdr = OBSRNXheader('../../data/JAB1080M.19o');
        end
    end
    methods (Test)
        function obj = testConstructor(obj)
            obj.verifyInstanceOf(obj.hdr,'OBSRNXheader');
        end
        function obj = testObsTypes(obj)
            refObsTypes.C = {'C2I','C6I','C7I','L2I','L6I','L7I','S2I','S6I','S7I'};
            refObsTypes.E = {'C1X','C5X','C6X','C7X','C8X','L1X','L5X','L6X','L7X','L8X','S1X','S5X','S6X','S7X','S8X'};
            refObsTypes.G = {'C1C','C2W','C2X','C5X','L1C','L2W','L2X','L5X','S1C','S2W','S2X','S5X'};
            refObsTypes.I = {'C5A','L5A','S5A'};
            refObsTypes.R = {'C1C','C1P','C2C','C2P','L1C','L1P','L2C','L2P','S1C','S1P','S2C','S2P'};
            refObsTypes.S = {'C1C','C5I','L1C','L5I','S1C','S5I'};
            obj.verifyEqual(refObsTypes,obj.hdr.obsTypes);
            obj.verifyEqual(obj.hdr.gnss,'CEGIRS');
            obj.verifyEqual(obj.hdr.noObsTypes,[9,15,12,3,12,6]);
        end
        function testHeaderConstants(obj)
            obj.verifyEqual(obj.hdr.version,'3.04');
            obj.verifyEqual(obj.hdr.leapSeconds,18);
            obj.verifyEqual(obj.hdr.interval,30);
        end
        function testReceiverInfo(obj)
            recSerial = '5448R50048';
            recName = 'TRIMBLE NETR9';
            recFirmware = '5.37';
            clockOffsetApp = false;
            obj.verifyEqual(recSerial,obj.hdr.receiver.serialnumber);
            obj.verifyEqual(recName,obj.hdr.receiver.type);
            obj.verifyEqual(recFirmware,obj.hdr.receiver.version);
            obj.verifyEqual(clockOffsetApp,obj.hdr.receiver.clockOffsetApplied);
        end
        function testAntennaInfo(obj)
            ARPpos = [4035921.4204  1285355.7843  4752936.8469];
            ARPoffset = [0.2800; -0.1990; 0.8700];
            antennaSerial = '12118048';
            antennaType = 'TRM57971.00     NONE';
            obj.verifyEqual(obj.hdr.approxPos,ARPpos);
            obj.verifyEqual(obj.hdr.antenna.offset,ARPoffset);
            obj.verifyEqual(obj.hdr.antenna.serialnumber,antennaSerial);
            obj.verifyEqual(obj.hdr.antenna.type,antennaType);
            obj.verifyEqual(obj.hdr.antenna.offsetType,'H/E/N');
        end
        function testMarkerInfo(obj)
            obj.verifyEqual(obj.hdr.marker.name,'JAB1');
            obj.verifyEqual(obj.hdr.marker.number,'1');
            obj.verifyEqual(obj.hdr.marker.type,'GEODETIC');
        end
        function testObserverAgency(obj)
            obj.verifyEqual(obj.hdr.observer,'spanikp');
            obj.verifyEqual(obj.hdr.agency,'SUT');
        end
	end
end