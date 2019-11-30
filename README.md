# GNSS-toolbox
GNSSS-toolbox is a set of functions and classes written in MATLAB language to load data from various formats used in GNSS data processing. Toolbox also provides functions to automatically download broadcast or precise ephemeris data and compute satellite positions for given observation periods. Also some visualization functions are provided in the toolbox.

* Reading files
  * Multi-GNSS RINEX v3 observation files (can handle only GPS, GLONASS, Galileo and Beidou, other satellite systems are neglected in current version)
  * GPS, GLONASS, Galileo and Beidou RINEX v2 or v3 navigation messages
  * Multi-GNSS SP3 satellite position files
  * ANTEX files for phase center correction

* Compute satellite positions
  * using broadcast ephemeris (according the Interface Control Documents for given satellite system)
  * using SP3 product files (using 10th order Lagrange interpolation)
  * satellite positions can be computed in ECEF or in local horizontal frame. Cartesian coordinates X, Y, Z are used for ECEF reference frame, while spherical coordinates elevation, azimuth and slant range is used for local reference frame
  * also satellite clock correction is computed in both cases (relativistic correction is accounted only in case of broadcast ephemeris)

* Visualization functions:
  * visualize XTR output files from [G-NUT/anubis application](https://www.pecny.cz/GOP/index.php/gnss/sw/anubis) 
  * this functions has its own [README](src/xtr-utils/README.md) file with examples

## Requirements
* Toolbox was developed and tested in MATLAB R2019b
* For unpacking files downloaded from GNSS datacenters [7-zip](https://www.7-zip.org/download.html) application is used, so executable has to be added in system PATH variable

## Examples
See `examples` folder with script to load RINEX observation file and computation of satellite positions in ECEF and local reference frame [testRinexLoadObsPos.m](examples/testRinexLoadObsPos.m). 

## Development
Latest functionality is tracked in `dev` branch.