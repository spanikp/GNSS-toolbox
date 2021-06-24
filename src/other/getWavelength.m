function lam = getWavelength(GNSS,frequencyBand,PRN)

c = 2.99792458e8;

switch GNSS
    %%%%% GPS SYSTEM 
    case 'G'
       switch frequencyBand
           case 1   % GPS L1
               f = 1575.42e6;
           case 2   % GPS L2
               f = 1227.60e6;
           case 5   % GPS L5
               f = 1176.45e6;
           otherwise
               error(['There is no ', frequencyBand, ' measurement defined for GPS in RINEX !!!']);
       end  
       
    %%%%% GLONASS SYSTEM 
    case 'R'
       FCH = [1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24
              1  -4   5   6   1  -4   5   6  -6  -7   0  -1  -2  -7   0  -1   4  -3   3   2   4  -3   3   2]; 
       
       switch frequencyBand
           case 1   % GLONASS G1 (FDMA)
               f0 = 1602e6;
               Df = 562.5e3;
           case 2   % GLONASS G2 (FDMA)
               f0 = 1246e6;
               Df = 437.5e3;
           case 3   % GLONASS G3 (CDMA) 
               f0 = 1202.025e6;
               Df = 0;
           otherwise
               error(['There is no ', frequencyBand, ' measurement defined for GLONASS in RINEX !!!']);
       end
       
       CHN = NaN(size(PRN));
       for i = 1:length(PRN)
           CHN(i) = FCH(2,PRN(i) == FCH(1,:));
       end
       f = f0 + Df*CHN;
       
    %%%%% GALILEO SYSTEM   
    case 'E'
       switch frequencyBand
           case 1   % GALILEO E1
               f = 1575.420e6;
           case 5   % GALILEO E5a
               f = 1176.450e6;
           case 7   % GALILEO E5b
               f = 1207.140e6;
           case 8   % GALILEO E5 (E5a+E5b)
               f = 1191.795e6;
           case 6   % GALILEO E6
               f = 1278.750e6;
           otherwise
               error(['There is no ', type, ' measurement defined for Galileo in RINEX !!!']);
       end 
       
    %%%%% BEIDOU SYSTEM   
    case 'C'
       switch frequencyBand
           case 1   % BEIDOU B1
               f = 1575.42e6;
           case 2   % BEIDOU B1-2
               f = 1561.098e6;
           case 5   % BEIDOU B2a
               f = 1176.45e6;
           case 6   % BEIDOU B3
               f = 1268.52e6;
           case 7   % BEIDOU B2b
               f = 1207.140e6;
           case 8   % BEIDOU B2(B2a+B2b)
               f = 1191.795e6;
           otherwise
               error(['There is no ', type, ' measurement defined for Beidou in RINEX !!!']);
       end 
end

lam = c./f;
