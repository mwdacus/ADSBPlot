classdef oper < handle   
    properties
        % most commonly used parameters
        mintime   % first time the message is received [UTC]
        nacp      % accuracy category of position, integers from 0 to 11
        SIL       % integrity level indicator, integers from 0 to 3
        icao      % aircaft ICAO number
        serial    % ADS-B ground receiver number in OpenSky Network


        % parameters mainly used for decoding or referencing
        tc        % type code for the data (operational status type code: 31)
        sc        % subtype code: sc=0 airborne, sc=1 surface
        version   % ads-b version number
        nicsa     % nic supplement bit - a
        nicbaro   % NIC-BARO [ST=0: Barometric altitude integrity, ST=1: Track angle or heading]
        SILsb     % SIL supplement bit
        df        % downlink format (df) (= 17 for ADS-B with Mode S transponder) 
        rawmsg    % hexstring form of 112-bits message
        maxtime   % last time the message is received [UTC]
        numReceiver % for each unique message, how many numbers of receivers have received that same message
    end
    
    methods
        function parseData(obj, inputFile, varargin) 
            % parse 
            % 
            % DESCRIPTION:
            %   Class to handle ADS-B operational status information. This
            %   includes aircraft NACp, SIL, ICAO number. Depends on the data
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
            %                   decoded operational status ADS-B data
            %                   
            % OUTPUT:
            %   obj - a struct of the decoded operational status data
            %


            %% Parse inputs
            p = inputParser;
            addRequired(p,'inputFile',@isfile);
            addOptional(p,'outputPath','',@isfolder)
            parse(p, inputFile, varargin{:});
            res = p.Results;
            outputPath = res.outputPath;





            %% Load operational status message from folder
            oper_type = '%*s%s%s%s%s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%s%*s%*s%*s%*s%*s%*s%*s%*s%s%*s%*s%[^\n\r]';

            % Open the file.
            fileID = fopen(inputFile,'r');
            % Read columns of data according to the format.
            startRow = 2; endRow = inf; delimiter = ',';
            dataArray = textscan(fileID, oper_type, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', startRow(1)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
            for block=2:length(startRow)
                frewind(fileID);
                dataArrayBlock = textscan(fileID, oper_type, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', startRow(block)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
                dataArray{1} = [dataArray{1};dataArrayBlock{1}];
            end
            % Close the  file.
            fclose(fileID);            
            % Create output variable
            rawMsgData = [dataArray{1:end-1}];






            %% add extra information from OpenSky which do not need to be decoded
            obj.rawmsg = rawMsgData(:,1);
            obj.mintime = rawMsgData(:,3); 
            obj.maxtime = rawMsgData(:,4); 
            obj.serial = rawMsgData(:,6);
            obj.numReceiver = ones(size(obj.rawmsg));




            %% collapse data into one union clock and remove repeated messages
            obj.collapseData();




            %% Parse hexstring of 112-bits ADS-B operational status message  
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
        % parse one ADS-B hexString operational status message
        parseMsg(obj, oper_msg);

        % combine oper data into one union time clock
        collapseData(obj) 
    end




end

