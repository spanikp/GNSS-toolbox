classdef testReadGLAB < matlab.unittest.TestCase
    properties
    end
    methods (TestClassSetup)
        function setupPath(obj)
            addpath(genpath('../../../src'));
        end
    end
    methods (Test)
        function test_readGLABoutput_v5(obj)
            glabout_v5 = 'satpvt_orbits_v5.out';
            satpvt = readGLABoutput(glabout_v5);
            obj.assertEqual(size(satpvt),[135,11]);
            obj.assertEqual(satpvt.Year(end),2021);
            obj.assertEqual(satpvt.Doy(end),79);
            obj.assertEqual(satpvt.SecondOfDay(end),1200);
            obj.assertEqual(satpvt.GNSS{end},'C');
            obj.assertEqual(satpvt.PRN(end),46);
            obj.assertEqual(satpvt.X(end),-4039736.1129);
            obj.assertEqual(satpvt.Y(end),21072376.8833);
            obj.assertEqual(satpvt.Z(end),17823614.6301);
            obj.assertEqual(satpvt.VX(end),-950.4104);
            obj.assertEqual(satpvt.VY(end),-1806.0121);
            obj.assertEqual(satpvt.VZ(end),1923.1468);
        end
        function test_readGLABoutput_v6(obj)
            glabout_v6 = 'satpvt_orbits_v6.out';
            satpvt = readGLABoutput(glabout_v6);
            obj.assertEqual(size(satpvt),[2954,11]);
            obj.assertEqual(satpvt.Year(end),2020);
            obj.assertEqual(satpvt.Doy(end),183);
            obj.assertEqual(satpvt.SecondOfDay(end),84900);
            obj.assertEqual(satpvt.GNSS{end},'R');
            obj.assertEqual(satpvt.PRN(end),17);
            obj.assertEqual(satpvt.X(end),-8065468.1613);
            obj.assertEqual(satpvt.Y(end),-7779516.7825);
            obj.assertEqual(satpvt.Z(end),22912620.1108);
            obj.assertEqual(satpvt.VX(end),1183.7899);
            obj.assertEqual(satpvt.VY(end),-2909.1237);
            obj.assertEqual(satpvt.VZ(end),-574.5060);
        end
    end
end