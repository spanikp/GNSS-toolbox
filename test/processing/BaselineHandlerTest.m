classdef BaselineHandlerTest < matlab.unittest.TestCase
    properties
        oBase
        oRover
        bh
        
        oBaseEph
        oRoverEph
        bhEph
        dd_res_cycles
        dd_res_meters
        ddrd % Double difference residual data
    end
    properties (TestParameter)
        ts = {...
            {1,10,{'L1C'}, 106377941.101, 128712465.729, 106377734.694, 128711924.194};... %epoch,slaveSat,obsType,baseRef,baseSlave,roverRef,roverSlave
            {1,10,{'L2W'},  82891926.559, 100295458.132,  82891788.043, 100295081.531};...
            {1, 6,{'L1C'}, 106377941.101, 131813231.844, 106377734.694, 131813681.019};...
            {1, 6,{'L2W'},  82891926.559,           nan,  82891788.043, 102711948.435};...
            {1, 6,{'L2W','L1C'}, [82891926.559,106377941.101], [nan,131813231.844], [82891788.043,106377734.694], [102711948.435,131813681.019]};...
        }
    end
    methods (TestClassSetup)
        function setupTest(obj)
            addpath(genpath('../../src'));
            obj.oBase = OBSRNX('../data/base080G_30s_15min.19o');
            obj.oBase = obj.oBase.computeSatPosition('broadcast','../data/brdc');
            obj.oRover = OBSRNX('../data/rover080G_30s_15min.19o');
            obj.oRover = obj.oRover.computeSatPosition('broadcast','../data/brdc');
            obj.bh = BaselineHandler([obj.oBase; obj.oRover],'G');
            
            % Get new OBSRNX object with precise ephemeris computed
            obj.oBaseEph = obj.oBase;
            obj.oBaseEph = obj.oBaseEph.computeSatPosition('precise','../data/eph/gfz');
            obj.oRoverEph = obj.oRover;
            obj.oRoverEph = obj.oRoverEph.computeSatPosition('precise','../data/eph/gfz');
            obj.bhEph = BaselineHandler([obj.oBaseEph; obj.oRoverEph],'G');
            obj.dd_res_cycles = obj.bhEph.getDDres({'L1C','L2W'},'cycles');
            obj.dd_res_meters = obj.bhEph.getDDres({'L1C','L2W'},'meters');
            
            % Create table for testing DDres
            f = fopen('dd_res_data.txt','r');
            header_line = fgetl(f); var_names = strsplit(header_line);
            d = textscan(f,'%s%f%f%f%f%f%f%f%f%f%f%f%f%f');
            fclose(f);
            t = [cell2table(d{1},'VariableNames',{'SatNo'}), array2table(cell2mat(d(2:end)))];
            t.Properties.VariableNames = var_names;
            obj.ddrd = t;
        end
    end
    methods (Test)
        function testConstructorFail(obj)
            o1 = OBSRNX('../data/base080G_30s_15min.19o');
            o2 = OBSRNX('../data/rover080G_30s_15min.19o');
		    obj.verifyError(@() BaselineHandler([o1; o2],'G'),'ValidationError:NotValidObservationStruct')
        end
        function testGetDD(obj)
            epochNo = 1;
            slaveSat = 10;
            obsType = {'L1C'};
            oBaseRef = 106377941.101;
            oRoverRef = 106377734.694;
            oBaseSlave = 128712465.729;
            oRoverSlave = 128711924.194;
            
            valRef = (oRoverSlave - oBaseSlave) - (oRoverRef - oBaseRef);
            dd1 = obj.bh.getDD(obsType);
            valActualCycles = cellfun(@(x) x(epochNo,slaveSat),dd1);
            obj.verifyEqual(valActualCycles,valRef,'AbsTol',1e-7)
            
            dd2 = obj.bh.getDD(obsType,'meters');
            valActualMeters = cellfun(@(x) x(epochNo,slaveSat),dd2);
            f = cellfun(@(x) getWavelength('G',str2double(x(2))),obsType);
            obj.verifyEqual(valActualMeters,valRef.*f,'AbsTol',1e-5)
        end
    end
    methods (Test, ParameterCombination='sequential')
        function testGetDDMoreTypes(obj, ts)
            epochNo = ts{1};
            slaveSat = ts{2};
            obsType = ts{3};
            oBaseRef = ts{4};
            oRoverRef = ts{6};
            oBaseSlave = ts{5};
            oRoverSlave = ts{7};
            
            valRef = (oRoverSlave - oBaseSlave) - (oRoverRef - oBaseRef);
            dd1 = obj.bh.getDD(obsType);
            valActualCycles = cellfun(@(x) x(epochNo,slaveSat),dd1);
            obj.verifyEqual(valActualCycles,valRef,'AbsTol',1e-7)
            
            dd2 = obj.bh.getDD(obsType,'meters');
            valActualMeters = cellfun(@(x) x(epochNo,slaveSat),dd2);
            f = cellfun(@(x) getWavelength('G',str2double(x(2))),obsType);
            obj.verifyEqual(valActualMeters,valRef.*f,'AbsTol',1e-5)
            
        end
        function testGetDDres(obj)
            ref_sat = 24;
            sel_ref = cellfun(@(x) strcmp(x,sprintf('G%02d',ref_sat)), obj.ddrd.SAT);
            obj.assertEqual(obj.bhEph.sessions.refSat,ref_sat);
            
            slave_sats = cellfun(@(x) str2num(x(2:3)), obj.ddrd.SAT);
            slave_sats = setdiff(slave_sats,ref_sat);
            epoch_idx = 11; % Data in file dd_res_data.txt are in epoch 12:05:00, it is index 11 in input RINEXes
            
            phases = {'L1C','L2W'};
            lambdas = [0.190293672798365, 0.244210213424568];
            
            % Get distances to satellites
            xs = obj.ddrd.X_SAT*1e3; ys = obj.ddrd.Y_SAT*1e3; zs = obj.ddrd.Z_SAT*1e3;
            xb = obj.ddrd.X_BASE; yb = obj.ddrd.Y_BASE; zb = obj.ddrd.Z_BASE;
            xr = obj.ddrd.X_ROVER; yr = obj.ddrd.Y_ROVER; zr = obj.ddrd.Z_ROVER;
            
            r_base = sqrt((xs - xb).^2 + (ys - yb).^2 + (zs - zb).^2);
            r_rover = sqrt((xs - xr).^2 + (ys - yr).^2 + (zs - zr).^2);
            
            r_sd_base = r_base(~sel_ref) - r_base(sel_ref);
            r_sd_rover = r_rover(~sel_ref) - r_rover(sel_ref);
            r_dd = r_sd_rover - r_sd_base;

            for i = 1:2
                phase = phases{i};
                lam = lambdas(i);
                
                % Reference sat observations
                obs_base_ref_cycles = obj.ddrd.(sprintf('BASE_%s',phase))(sel_ref);
                obs_base_ref_meters = obj.ddrd.(sprintf('BASE_%s',phase))(sel_ref)*lam;
                obs_rover_ref_cycles = obj.ddrd.(sprintf('ROVER_%s',phase))(sel_ref);
                obs_rover_ref_meters = obj.ddrd.(sprintf('ROVER_%s',phase))(sel_ref)*lam;
                
                % Slave sats observations
                obs_base_slave_cycles = obj.ddrd.(sprintf('BASE_%s',phase))(~sel_ref);
                obs_base_slave_meters = obj.ddrd.(sprintf('BASE_%s',phase))(~sel_ref)*lam;
                obs_rover_slave_cycles = obj.ddrd.(sprintf('ROVER_%s',phase))(~sel_ref);
                obs_rover_slave_meters = obj.ddrd.(sprintf('ROVER_%s',phase))(~sel_ref)*lam;
                
                obs_sd_base_cycles = obs_base_slave_cycles - obs_base_ref_cycles;
                obs_sd_rover_cycles = obs_rover_slave_cycles - obs_rover_ref_cycles;
                obs_dd_cycles = obs_sd_rover_cycles - obs_sd_base_cycles;
                ref_val_dd_res_cycles = obs_dd_cycles - r_dd/lam;
                
                dd_test = obj.bhEph.getDD({phase});
                %dd_test{1}(epoch_idx,slaveSat)
                
                obs_sd_base_meters = obs_base_slave_meters - obs_base_ref_meters;
                obs_sd_rover_meters = obs_rover_slave_meters - obs_rover_ref_meters;
                obs_dd_meters = obs_sd_rover_meters - obs_sd_base_meters;
                ref_val_dd_res_meters = obs_dd_meters - r_dd;
                
                for j = 1:numel(slave_sats)
                    slaveSat = slave_sats(j);
                    obj.assertEqual(obs_dd_cycles(j),dd_test{1}(epoch_idx,slaveSat),'AbsTol',1e-5);
                    obj.assertEqual(ref_val_dd_res_cycles(j),obj.dd_res_cycles{i}(epoch_idx,slaveSat),'AbsTol',1e-5);
                    obj.assertEqual(ref_val_dd_res_meters(j),obj.dd_res_meters{i}(epoch_idx,slaveSat),'AbsTol',1e-5);
                end
            end
        end
    end
end