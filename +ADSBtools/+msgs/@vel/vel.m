classdef vel < handle    
    properties
        % most commonly used parameters
        mintime         % first time the message is received [UTC]
        nacv            % accuracy category of velocity, integers from 0 to 4
        icao            % aircaft ICAO number
        serial          % ADS-B ground receiver number in OpenSky Network
        
        % parameters mainly used for decoding or referencing 
        tc              % type code from the data (airborne velocity type codes: 19)
        st              % subtype (st) [st=1 for ground speed, st=3 for airspeed]
        df              % downlink format (df) (= 17 for ADS-B with Mode S transponder) 
        SDif            % Sign bit for GNSS and Baro altitudes difference
        dAlt            % Difference between GNSS and Baro altitudes 	
        groundV         % ground speed [knots]
        groundVAngle    % heading angle[deg], clockwise from true north
        airspeedV       % airspeed[knots] (All zeros: no information available)
        airspeedVAngle  % heading angle[deg], clockwise from magnetic north
        rawmsg          % hexstring form of 112-bits message
        maxtime         % last time the message is received [UTC]
        msgcount        % total numbers of times this message has been received 
        vr              % Vertical rate [ft/min]
        numReceiver % for each unique message, how many numbers of receivers have received that same message
    end
    

    methods

        function parseData(obj, inputFile, varargin)
            % parse 
            % 
            % DESCRIPTION:
            %   Class to handle ADS-B airborne velocity information. This
            %   includes aircraft NACv, ICAO number. Depends on the data
            %   source, it also contains OpenSky's ground receiver serial
            %   number. This includes functionality to perform sanity check
            %   on OpenSky data as well as decoding raw 112-bits ADS-B messages.
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
            %                   decoded airborne velocity ADS-B data
            %                   
            % OUTPUT:
            %   obj - a struct of the decoded airborne velocity data
            %


            %% Parse inputs
            p = inputParser;
            addRequired(p,'inputFile',@isfile);
            addOptional(p,'outputPath','',@isfolder)
            parse(p, inputFile, varargin{:});
            res = p.Results;
            outputPath = res.outputPath;





            %% Load airborne Velocity message from folder
            vel_type = '%*s%s%s%s%s%s%*s%*s%*s%*s%*s%*s%*s%s%*s%*s%*s%*s%s%*s%*s%[^\n\r]'; %'*' means ignoring that column
            % Open the file.
            fileID = fopen(inputFile,'r');
            % Read columns of data according to the format.
            startRow = 2; endRow = inf; delimiter = ',';
            dataArray = textscan(fileID, vel_type, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', startRow(1)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
            for block=2:length(startRow)
                frewind(fileID);
                dataArrayBlock = textscan(fileID, vel_type, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', startRow(block)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
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
            obj.vr = rawMsgData(:,6);
            obj.serial = rawMsgData(:,7);
            obj.numReceiver = ones(size(obj.rawmsg));



            %% collapse data into one union clock and remove repeated messages
            obj.collapseData();




            %% Parse hexstring of 112-bits ADS-B airborne velocity message  
            originalMsg = obj.rawmsg;           
            obj.parseMsg(originalMsg);




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
        % parse one ADS-B hexString airborne velocity message
        parseMsg(obj, vel_msg);

        % combine vel data into one union time clock
        collapseData(obj); 
    end

end

