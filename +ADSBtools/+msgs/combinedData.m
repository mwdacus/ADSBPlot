classdef combinedData    
    properties
        time     % first time the message is received [UTC]
        lat      % deg
        lon      % deg
        alt      % baroaltitude [m]
        nic      % integrity level indicator, integers from 0 to 11
        nacp     % accuracy category of position, integers from 0 to 11
        SIL      % integrity level indicator, integers from 0 to 3
        nacv     % accuracy category of velocity, integers from 0 to 4
        icao string % aircaft ICAO number
        serial   % ADS-B ground receiver number in OpenSky Network
        numReceiver % for each unique message, how many numbers of receivers have received that same message
    end





    
    methods
        function obj = combinedData(posData, velData, operData, varargin)
            % combinedData 
            % 
            % DESCRIPTION:
            %   function to generate a struct data, which combines airborne
            %   position message, airborne velocity message, and operational
            %   status message 
            %   
            %
            % INPUT:
            %   pos     -   struct data, class pos 
            %   vel     -   struct data, class vel
            %   oper    -   struct data, class oper
            %                   
            %                   
            % OUTPUT:
            %   form obj with properties above

            %% Parse inputs
            p = inputParser;
            validationFcn_pos = @(x) isa(x, 'ADSBtools.msgs.pos');
            validationFcn_vel = @(x) isa(x, 'ADSBtools.msgs.vel');
            validationFcn_oper = @(x) isa(x, 'ADSBtools.msgs.oper');

            addRequired(p,'posData', validationFcn_pos)
            addRequired(p,'velData', validationFcn_vel)
            addRequired(p,'operData', validationFcn_oper)
            addOptional(p,'outputPath','',@isfolder)
            addOptional(p,'filename','',@isstring)
            parse(p, posData, velData, operData, varargin{:});
            res = p.Results;
            outputPath = res.outputPath;
            filename = res.filename;


            %% Obtain all data information
            % time stamp
            pos_time = datetime(strip(posData.mintime,'both','"'),'Format', 'yyyy-MM-dd  HH:mm:ss.SSSSSS');
            vel_time = datetime(strip(velData.mintime,'both','"'),'Format', 'yyyy-MM-dd  HH:mm:ss.SSSSSS');
            oper_time = datetime(strip(operData.mintime,'both','"'),'Format', 'yyyy-MM-dd  HH:mm:ss.SSSSSS');

            % ground receiver
            pos_serial = posData.serial;
            vel_serial = velData.serial;
            oper_serial = operData.serial;
            allReceivers = unique([pos_serial; vel_serial; oper_serial]);

            % aircraft
            pos_icao = posData.icao;
            vel_icao = velData.icao;
            oper_icao = operData.icao;
            

            % parameters to add
            lat = posData.lat;
            lon = posData.lon;
            alt = posData.alt;
            nic = double(string(strip(posData.nic, 'both', '"')));
            nacp = operData.nacp;
            SIL = operData.SIL;
            nacv = velData.nacv;
            SDif = velData.SDif;  % Sign bit for GNSS and Baro altitudes difference
            dAlt = velData.dAlt;  % Difference between GNSS and Baro altitudes 
            numReceiver = posData.numReceiver;

            % temporary array to save output result
            results_time = []; results_lat = []; results_lon = [];
            results_alt = []; results_nic = [];  results_nacp = [];
            results_SIL = []; results_nacv = []; results_icao = [];  
            results_serial = [];  results_numReceiver = [];
            results_SDif = []; results_dAlt = []; 

            
            %% Within each receiver
            for receiverInd = 1:length(allReceivers)
                receiver = allReceivers(receiverInd);

                posInd = pos_serial==receiver;
                velInd = vel_serial==receiver;
                operInd = oper_serial==receiver;
                if sum(posInd) < 10 || sum(velInd)<10 || sum(operInd)<10
                    % skip current receiver if only few points were received
                    continue
                end

                % data from current receiver 
                pos_time_sub = pos_time(posInd); vel_time_sub = vel_time(velInd); 
                oper_time_sub = oper_time(operInd); 
    
                % ground receiver
                pos_serial_sub = pos_serial(posInd); 
    
                % aircraft
                pos_icao_sub = pos_icao(posInd); vel_icao_sub = vel_icao(velInd); 
                oper_icao_sub = oper_icao(operInd); 
                
                % parameters to add
                lat_sub = lat(posInd); lon_sub = lon(posInd); alt_sub = alt(posInd); 
                nic_sub = nic(posInd); nacp_sub = nacp(operInd); SIL_sub = SIL(operInd); 
                nacv_sub = nacv(velInd); SDif_sub = SDif(velInd); dAlt_sub = dAlt(velInd); 
                numReceiver_sub = numReceiver(posInd);



                % within each aircraft
                aircraft = unique(pos_icao_sub);                
                for icaoInd = 1:length(aircraft)
                    currIcao = aircraft(icaoInd);
                    % find index of icao in each data class
                    pos_icaoInd = pos_icao_sub == currIcao;
                    vel_icaoInd = vel_icao_sub == currIcao;
                    oper_icaoInd = oper_icao_sub == currIcao;

                    % skip aircraft without all three messages
                    if sum(vel_icaoInd) == 0 || sum(oper_icaoInd) == 0
                        continue
                    end

                    % use timestamp in pos message as "time"
                    timestamp = pos_time_sub(pos_icaoInd);
                    timestamp_vel = vel_time_sub(vel_icaoInd);
                    timestamp_oper = oper_time_sub(oper_icaoInd);


                    % align vel time with pos time
                    posvel_diff = abs(repmat(timestamp,1,length(timestamp_vel)) - repmat(timestamp_vel',length(timestamp),1));
                    [~,posvel_diffTag]=min(posvel_diff,[],1);

                    expanded_nacv = NaN(size(timestamp));
                    expanded_nacv(posvel_diffTag) = nacv_sub(vel_icaoInd);
                    expanded_nacv = fillmissing(expanded_nacv,'previous');
                    if sum(isnan(expanded_nacv)) > 0
                        expanded_nacv = fillmissing(expanded_nacv,'next');
                    end

                    expanded_SDif = NaN(size(timestamp));
                    expanded_SDif(posvel_diffTag) = SDif_sub(vel_icaoInd);
                    expanded_SDif = fillmissing(expanded_SDif,'previous');
                    if sum(isnan(expanded_SDif)) > 0
                        expanded_SDif = fillmissing(expanded_SDif,'next');
                    end

                    expanded_dAlt = NaN(size(timestamp));
                    expanded_dAlt(posvel_diffTag) = dAlt_sub(vel_icaoInd);
                    expanded_dAlt = fillmissing(expanded_dAlt,'previous');
                    if sum(isnan(expanded_dAlt)) > 0
                        expanded_dAlt = fillmissing(expanded_dAlt,'next');
                    end




                    % align oper time with pos time
                    posoper_diff = abs(repmat(timestamp,1,length(timestamp_oper)) - repmat(timestamp_oper',length(timestamp),1));
                    [~,posoper_diffTag]=min(posoper_diff,[],1);

                    expanded_nacp = NaN(size(timestamp));
                    expanded_nacp(posoper_diffTag) = nacp_sub(oper_icaoInd);
                    expanded_nacp = fillmissing(expanded_nacp,'previous');
                    if sum(isnan(expanded_nacp)) > 0
                        expanded_nacp = fillmissing(expanded_nacp,'next');
                    end
                    expanded_SIL = NaN(size(timestamp));
                    expanded_SIL(posoper_diffTag) = SIL_sub(oper_icaoInd);
                    expanded_SIL = fillmissing(expanded_SIL,'previous');
                    if sum(isnan(expanded_SIL)) > 0
                        expanded_SIL = fillmissing(expanded_SIL,'next');
                    end
                    

  
                    % add to a temporary struct to save obj properties
                    results_time = [results_time; timestamp];
                    results_lat = [results_lat; lat_sub(pos_icaoInd)];   
                    results_lon = [results_lon; lon_sub(pos_icaoInd)];
                    results_alt = [results_alt; alt_sub(pos_icaoInd)];     
                    results_nic = [results_nic; nic_sub(pos_icaoInd)];  
                    results_nacp = [results_nacp; expanded_nacp];
                    results_SIL = [results_SIL; expanded_SIL];
                    results_nacv = [results_nacv; expanded_nacv];
                    results_icao = [results_icao; pos_icao_sub(pos_icaoInd)];  
                    results_serial = [results_serial; pos_serial_sub(pos_icaoInd)];  
                    results_numReceiver = [results_numReceiver; numReceiver_sub(pos_icaoInd)];
                    results_SDif = [results_SDif; expanded_SDif];
                    results_dAlt = [results_dAlt; expanded_dAlt]; 
                end

            end

            %% modify baroaltitude to GNSS HAE
            results_SDif(results_SDif == 1) = -1; %1: GNSS alt below Baro alt
            results_SDif(results_SDif == 0) = 1; %0: GNSS alt above Baro alt

            alt_diff = results_SDif.*(results_dAlt-1)*25; % Alt difference = (dAlt-1)*25ft
            alt_diff = alt_diff*0.3048; % ft to m


            %% save results to obj
            obj.time = results_time;
            obj.lat = results_lat;
            obj.lon = results_lon;
            obj.alt = results_alt + alt_diff;
            obj.nic = results_nic;
            obj.nacp = results_nacp;
            obj.SIL = results_SIL;
            obj.nacv = results_nacv;
            obj.icao = results_icao;
            obj.serial = results_serial;
            obj.numReceiver = results_numReceiver;




            %% save combined data into csv file upon request
            if nargin == 5
                outputFile = outputPath+'\'+filename;
                warning('off')
                writetable(struct2table(struct(obj)), outputFile)
                warning('on')
            end

        end

    end






end

