function file_list = download_brdc_IGS(year_start,month_start,day_start,year_end,month_end,day_end,mode)
% Function to download broadcast ephemeris of GPS satelittes
% Parameters: year_start,month_start,day_start - specify start day
%             year_end,month_end,day_end - specify end day 
%             mode - one of the following options:
%                 'mget' - native MATLAB FTP client
%                 'wget' - download using wget utility (has to be installed
%                          previously and available in PATH variable)
%                 'urlwrite' - download using MATLAB urlwrite function
%
% Note: check if executable gzip ii in your system PATH variable
%       gzip can be downloaded from: http://www.gzip.org/#exe  
%
% Author: Peter Spanik, 18.2.2016
%
% Updates: 15.2.2018 - add mode option to set alternative ways for downloading
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

JD_start = juliandate(year_start,month_start,day_start);
JD_end = juliandate(year_end,month_end,day_end);
date_today = clock;
JD_today = juliandate(date_today(1),date_today(2),date_today(3));

% Check internet connection
[~,flag] = urlread('http://google.com');
if flag == 0
   disp('You are not connected to the internet !!!')
else
   servername = 'cddis.gsfc.nasa.gov';
   for JD = JD_start:JD_end
       if JD >= JD_today
          disp('You cannot download broadcast ephemeris data from the future!!!')
          break
       else
          year = julian2greg(JD);
          year_str = num2str(year);
	      doy = JD - juliandate(year,1,1) + 1;
          doy_str = sprintf('%03d', doy);
       
          path = ['gps/data/daily/', year_str, '/', doy_str, '/', year_str(end-1:end), 'n'];
          name = ['brdc', doy_str, '0.', year_str(end-1:end), 'n.Z'];

          disp([year_str, '-', doy_str, ': Downloading ephemeris file: ', name])

          switch mode
              case 'mget'
                  % Downloading via FTP protocol
                  server = ftp(servername);   % Open FTP server
                  cd(server, path);           % Change directory at FTP server
                  mget(server, name);         % Downloads file

             case 'wget'
                  % wget utility has to be installed
                  link = ['ftp://', servername, '/', path, '/', name];
                  unix(['wget ', link])
                 
             case 'urlwrite'
                  link = ['ftp://', servername, '/', path, '/', name];
                  urlwrite(link, name);    
          end
  
          % Check existence of downloaded file
          if exist(name, 'file')
             disp(['          Extracting ephemeris file: ', name])
             unix(['gzip -d -f ', name]);
          else
             disp(['File', name, 'was not downloaded !!!']) 
          end
          
          if JD == JD_end
             if strcmp(mode,'mget')  
                close(server)   % Close connection to FTP server
             end
          end
          disp('------------------------------------------------------------')
       end
   end
end
