function parseMsg(obj, vel_msg) 
    % DESCRIPTION:
    %   parse one ADS-B hexString airborne velocity message following rules
    %   from MOPs DO-260. 
    %   
    % INPUT:
    %   vel_msg - raw hexString of ADS-B airborne velocity message
    %  
    %             
    % OUTPUT:
    %   obj will have new decoded information from one selected message 
    %   inside itself, see below for details of decoded vars. Also this 
    %   book explains ADS-B quite well: https://mode-s.org/decode/




    %% loop through all the messages and get the components of each message
    Nmsgs = length(vel_msg);
    tc_vec = zeros(1, Nmsgs)';
    st_vec = zeros(1, Nmsgs)';
    nacv_vec = zeros(1, Nmsgs)';
    df_vec = zeros(1, Nmsgs)';
    icao_vec = string(zeros(1,Nmsgs))';
    SDif_vec = zeros(1, Nmsgs)';
    dAlt_vec = zeros(1, Nmsgs)';
    groundV_vec = zeros(1, Nmsgs)';
    groundVAngle_vec = zeros(1, Nmsgs)';
    airspeedV_vec = zeros(1, Nmsgs)';
    airspeedVAngle_vec = zeros(1, Nmsgs)';


    for i = 1:Nmsgs
        % convert to a binary string representation of the data
        binStr = num2str(hexToBinaryVector(vel_msg{i}));
        binStr = strrep(binStr, ' ', '');


        % get the downlink format (df) (should = 17 for ADS-B with Mode S transponder,
        % = 18 for ADS-B without Mode S but also for all TIS-B)
        df = bin2dec(binStr(1:5));
    
        % get the capability (CA) -> not sure what this is
        ca = bin2dec(binStr(6:8));
    
        % ICAO aircraft address
        % going to represent this as a hex string
        icao = dec2hex(bin2dec(binStr(9:32)));
    
        % get the data
        msgDataBinStr = binStr(33:88);
    
        % CRC
        %
        % NOTE: will just be ignoring this value for now...
        crc = bin2dec(binStr(89:112));
    
        % Parse Data
        %
        % need to get the type code first, and then handle the message based on the
        % type code
    
        % get the type code from the data
        tc = bin2dec(msgDataBinStr(1:5));
        
        
        if tc == 19  % airborne velocity type codes
            % subtype (st) [st=1 for ground speed, st=3 for airspeed]
            % [Reporting of airspeed occurs when aircraft position can not be determined based on the GNSS system]
            st = bin2dec(msgDataBinStr(6:8));
    
            % intent change flag
            ic = bin2dec(msgDataBinStr(9));
            
            % IFR capability flag
            ifr = bin2dec(msgDataBinStr(10));
            
            % Navigation uncertainty category for velocity [0-4]
            nacv = bin2dec(msgDataBinStr(11:13));
            
            
            
            % Dew: direction bit E/W [0: from West to East.  1: from East to West]
            % SH: Heading Status bit [0: not available.  1: available]
            if ismember(st,[1,2])
                Dew = bin2dec(msgDataBinStr(14));
                SH = nan;
            else
                Dew = nan;
                SH = bin2dec(msgDataBinStr(14));
            end
            
            
            
            if ismember(st,[1,2])
                % E/W velocity
                Vew = bin2dec(msgDataBinStr(15:24));
                if st == 1
                    Vew = Vew - 1;
                elseif st == 2
                    Vew = 4 * (Vew - 1);
                end
                HDG = nan;
            else
                % Magnetic heading (deg)
                HDG = bin2dec(msgDataBinStr(15:24));
                HDG = HDG * 360 / 1024;
                Vew = nan;
            end
            
            
            % Dns: direction bit N/S [0: from South to North.  1: from North to South]
            % T: Airspeed type [0: Indicated airspeed (IAS).  1: True airspeed (TAS)]
            if ismember(st,[1,2])
                Dns = bin2dec(msgDataBinStr(25));
                T = nan;
            else
                Dns = nan;
                T = bin2dec(msgDataBinStr(14));
            end


            if ismember(st,[1,2])
                % N/S velocity
                Vns = bin2dec(msgDataBinStr(26:35));
                if st == 1
                    Vns = Vns - 1;
                elseif st == 2
                    Vns = 4 * (Vns - 1);
                end
                AS = nan;
            else
                % Airspeed [knots] (All zeros: no information available)
                AS = bin2dec(msgDataBinStr(26:35));
                if st == 3
                    AS = AS - 1;
                elseif st == 4
                    AS = 4 * (AS - 1);
                end
                Vns = nan;
            end
            
            
            
            %%%%Calculate ground speed or airspeed based on decoded info
            if ismember(st,[1,2])
                if st == 1
                    Vx = (-2*Dew + 1) * (Vew - 1);
                    Vy = (-2*Dns + 1) * (Vns - 1);
                else
                    Vx = 4*(-2*Dew + 1) * (Vew - 1);
                    Vy = 4*(-2*Dns + 1) * (Vns - 1);
                end
                groundV = sqrt(Vx^2 + Vy^2);
                groundVAngle = atan2(Vx, Vy)* 180/(pi);
                groundVAngle = mod(groundVAngle, 360);
            else
                groundV = nan;
                groundVAngle = nan;
            end
            airspeedV = AS;
            airspeedVAngle = HDG;
            
            %Source bit for vertical rate [0-GNSS, 1-Barometer]
            vrSrc = bin2dec(msgDataBinStr(36));
            
            % Sign bit for vertical rate 0-Up, 1-Down]
            svr = bin2dec(msgDataBinStr(37));
            
            % Vertical rate
            vr = bin2dec(msgDataBinStr(38:46));
    
    
            % reserved_B
            % omitting
            
            
            % Sign bit for GNSS and Baro altitudes difference 
            %  [0: GNSS alt above Baro alt, 1: GNSS alt below Baro alt]
            SDif = bin2dec(msgDataBinStr(49));
    
            
            % Difference between GNSS and Baro altitudes = (dAlt-1)*25ft 	
            dAlt = bin2dec(msgDataBinStr(50:56));
        end


        % save decoded result to vector(speed up process than directly save to obj)
        tc_vec(i) = tc; st_vec(i) = st; nacv_vec(i) = nacv; df_vec(i) = df;
        icao_vec(i) = icao; SDif_vec(i) = SDif; dAlt_vec(i) = dAlt;
        groundV_vec(i) = groundV; groundVAngle_vec(i) = groundVAngle;
        airspeedV_vec(i) = airspeedV; airspeedVAngle_vec(i) = airspeedVAngle;

    end


    % save decoded information into struct
    obj.tc = tc_vec;
    obj.st = st_vec;
    obj.nacv = nacv_vec;
    obj.df = df_vec;
    obj.icao = icao_vec;
    obj.SDif = SDif_vec;
    obj.dAlt = dAlt_vec;
    obj.groundV = groundV_vec;
    obj.groundVAngle = groundVAngle_vec;
    obj.airspeedV = airspeedV_vec;
    obj.airspeedVAngle = airspeedVAngle_vec; 



end