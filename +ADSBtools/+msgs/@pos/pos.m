classdef pos < handle    
    properties
        % most commonly used parameters
        mintime  % first time the message is received [UTC]
        lat      % deg
        lon      % deg
        alt      % baroaltitude [m]
        nic      % integrity level indicator, integers from 0 to 11
        icao string % aircaft ICAO number
        serial   % ADS-B ground receiver number in OpenSky Network

        % parameters mainly used for decoding or referencing 
        df       % downlink format (df) (= 17 for ADS-B with Mode S transponder) 
        tc       % type code from the data (airborne position type codes: 0, 9-18, 20-22)
        ss       % surveillance status (ss)
        nicsb    % NIC supplement B
        t        % Time flag (0 or 1)
        f        % CPR odd/even frame flag
        latCPR   % Latitude in CPR format 
        lonCPR   % Longitude in CPR format
        nucp     % similar to NIC but used for ADS-B version 1     
        rawmsg   % hexstring form of 112-bits message
        maxtime  % last time the message is received [UTC]
        msgcount % total numbers of times this message has been received 
        numReceiver % for each unique message, how many numbers of receivers have received that same message
    end
    


    methods  
        function parseData(obj, inputFile, varargin)
            % parseData 
            % 
            % DESCRIPTION:
            %   Class to handle ADS-B airborne position information. This
            %   includes aircraft latitude, longitude, altitude[m], NIC,
            %   ICAO number. Depends on the data source, it also contains
            %   OpenSky's ground receiver serial number. This includes
            %   functionality to perform sanity check on OpenSky data as
            %   well as decoding raw 112-bits ADS-B messages.
            %   
            % INPUT:
            %   inputFile - The filename including path to the folder.
            %               Input file should contain ADS-B data quried
            %               from OpenSky Network. File type should be csv. 
            %               (https://opensky-network.org/data/impala)
            %               
            %                   
            % OPTIONAL INPUT:
            %   outputPath - The path to a folder for saving the
            %                   decoded airborne position ADS-B data
            %                   
            % OUTPUT:
            %   obj - a struct of the decoded airborne position data
            %
        
        
            %% Parse inputs
            p = inputParser;
            addRequired(p,'inputFile',@isfile);
            addOptional(p,'outputPath','',@isfolder)
            parse(p, inputFile, varargin{:});
            res = p.Results;
            outputPath = res.outputPath;
        
        
        
            %% Load airborne position message from folder
            pos_type = '%*s%s%s%s%s%*s%*s%*s%*s%*s%*s%*s%*s%s%s%s%*s%*s%*s%*s%*s%*s%*s%s%*s%*s%[^\n\r]'; %'*' means ignoring that column
            % Open the file.
            fileID = fopen(inputFile,'r');
            % Read columns of data according to the format.
            startRow = 2; endRow = inf; delimiter = ',';
            dataArray = textscan(fileID, pos_type, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', startRow(1)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
            for block=2:length(startRow)
                frewind(fileID);
                dataArrayBlock = textscan(fileID, pos_type, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', startRow(block)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
                dataArray{1} = [dataArray{1};dataArrayBlock{1}];
            end
            % Close the  file.
            fclose(fileID);            
            % Create output variable
            rawMsgData = [dataArray{1:end-1}];
        
        
        
        


            %% add extra information from OpenSky which do not need to be decoded
            obj.rawmsg = rawMsgData(:,1);
            obj.mintime = rawMsgData(:,2); 
            obj.maxtime = rawMsgData(:,3); 
            obj.msgcount = rawMsgData(:,4);
            obj.serial = rawMsgData(:,8);
            obj.numReceiver = ones(size(obj.rawmsg));



            

            %% collapse data into one union clock and remove repeately received messages
            obj.collapseData();




            %% Parse 112-bits ADS-B airborne position message  
            originalMsg = obj.rawmsg;           
            obj.parseMsg(originalMsg);
            
        
        
        
        
            %% decode latitude and longitude 
            obj.lat = nan*obj.f; obj.lon = nan*obj.f;
            icaos = unique(obj.icao);
            for i=1:1:length(icaos)
                ind = find(ismember(obj.icao, icaos(i)));

                % assign initial value using OpenSky decoded (lat,lon). Update
                % inside the loop on each step with previously decoded (lat, lon)
                reference_point = [nan nan];
                for j = 1:1:length(ind)
                    if ~isnan(str2double(rawMsgData(ind(j),5))) && ~isnan(str2double(rawMsgData(ind(j),6)))
                        reference_point = [nanmean(str2double(rawMsgData(ind(j),5))), nanmean(str2double(rawMsgData(ind(j),6)))];
                        break
                    end
                end
                if isnan(reference_point(1)) || isnan(reference_point(2))
                    continue
                end
                
                obj.decodeLatLon(ind, reference_point);
            end      
        
        
        

            %% decode nic value
            obj.addNic();



            %% keep only odd flag (due to locally unambiguous position decoding)
            oddEvenFlag = obj.f;
            oddFlagInd = oddEvenFlag == 1;
            name = fieldnames(obj);
            for i = 1:length(name)
                obj.(name{i}) = obj.(name{i})(oddFlagInd);
            end
            
        
        
            %% save decoded data into csv file upon request
            if nargin == 3
                inputFile_char = char(inputFile);
                subpaths = find(inputFile_char == '\');
                name = inputFile_char(subpaths(end)+1:end);
                outputFile = string(outputPath)+'\'+name(1:end-4) + '-Raw-Message.csv';
                warning('off')
                writetable(struct2table(struct(obj)), outputFile)
                warning('on')
            end
        
        end
    end


    methods 
        % parse one ADS-B hexString airborne position message
        parseMsg(obj, pos_msg);
       
        % decode latitude and longitude  
        decodeLatLon(obj, rowNums, ref_pt);

        % decode nic value
        addNic(obj);

        % combine pos data into one union time clock
        collapseData(obj); 
    end

    methods (Static)
        % read 100ft increment baroaltitude from Annex10
        resultAlt = checkInAnnex10(inputAlt, sortedTable);
    end


end

