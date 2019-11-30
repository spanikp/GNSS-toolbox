# GNSS-toolbox
GNSSS-toolbox is a set of useful functions and classes written in MATLAB to help with processing of GNSS datasets. You can load your data from RINEX v3 files to MAT files.

Reading files:

* Multi-GNSS RINEX v3 observation files (can handle only GPS, GLONASS, Galileo and Beidou, other satellite systems will be neglected)
* GPS, GLONASS, Galileo and Beidou RINEX v2 or v3 navigation messages
* Multi-GNSS SP3 files

Computation of satellite positions:

* from broadcast navigation messages (according the Interface Control Documents for given satellite system)
* from SP3 files (using 10th order Lagrange interpolation)

## RINEX v3 loading
For example see script [testRinexLoadObsPos.m](https://github.com/spanikp/GNSS-toolbox/blob/master/scripts/testRinexLoadObsPos.m) which will load example RINEX observation file.

## Development
Latest functionality is tracked in `dev` branch
