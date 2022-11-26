function parseMsg(obj, oper_msg) 
    % DESCRIPTION:
    %   parse one ADS-B hexString operational status message following rules
    %   from MOPs DO-260. 
    %   
    % INPUT:
    %   oper_msg - raw hexString of ADS-B operational status message
    %  
    %             
    % OUTPUT:
    %   obj will have new decoded information from one selected message 
    %   inside itself, see below for details of decoded vars. Also this 
    %   book explains ADS-B quite well: https://mode-s.org/decode/



    %% loop through all the messages and get the components of each message
    Nmsgs = length(oper_msg);
    tc_vec = zeros(1, Nmsgs)';
    sc_vec = zeros(1, Nmsgs)';
    version_vec = zeros(1, Nmsgs)';
    nicsa_vec = zeros(1, Nmsgs)';
    nacp_vec = zeros(1, Nmsgs)';
    nicbaro_vec = zeros(1, Nmsgs)';
    SIL_vec = zeros(1, Nmsgs)';
    SILsb_vec = zeros(1, Nmsgs)';
    df_vec = zeros(1, Nmsgs)';
    icao_vec = string(zeros(1,Nmsgs))';


    for i = 1:Nmsgs
        % convert to a binary string representation of the data
        binStr = num2str(hexToBinaryVector(oper_msg{i}));
        binStr = strrep(binStr, ' ', '');

        % get the downlink format (df) (should = 17 for ADS-B with Mode S transponder,
        % = 18 for ADS-B without Mode S but also for all TIS-B)
        df = bin2dec(binStr(1:5));
    
        % Capacity class codes
        ca = bin2dec(binStr(6:8));
    
        % ICAO aircraft address
        % going to represent this as a hex string
        icao = dec2hex(bin2dec(binStr(9:32)));
    
        % get the data
        msgDataBinStr = binStr(33:88);
    
    
        % Parse Data
        %
        % need to get the type code first, and then handle the message based on the
        % type code
    
        % get the type code from the data
        tc = bin2dec(msgDataBinStr(1:5));
    
        if tc == 31  % operational message
            % subtype code
            sc = bin2dec(msgDataBinStr(6:8)); %sc=0 airborne, sc=1 surface
    
            % airborne capacity class codes
            % omitting for now
    
    
            % operational mode code
            % omitting for now
    
            % ads-b version number
            version = bin2dec(msgDataBinStr(41:43));
    
            % nic supplement bit - a
            nicsa = bin2dec(msgDataBinStr(44));
    
            % NACp
            nacp = bin2dec(msgDataBinStr(45:48));
    
            % GVA
            % omitting
    
            % SIL - surveillance integrity level
            SIL = bin2dec(msgDataBinStr(51:52));
    
            % NIC-BARO [ST=0: Barometric altitude integrity, ST=1: Track angle or heading]
            nicbaro = bin2dec(msgDataBinStr(53));
    
            % HRD
            % omitting
    
            % SIL supplement bit
            SILsb = bin2dec(msgDataBinStr(55));
            
            % reserved
            % omitting
        end


        % save decoded result to vector(speed up process than directly save to obj)
        tc_vec(i) = tc; sc_vec(i) = sc; version_vec(i) = version;
        nicsa_vec(i) = nicsa; nacp_vec(i) = nacp; nicbaro_vec(i) = nicbaro;
        SIL_vec(i) = SIL; SILsb_vec(i) = SILsb; df_vec(i) = df;
        icao_vec(i) = icao;  
    
    end
    % save decoded information into struct
    obj.tc = tc_vec;
    obj.sc = sc_vec;
    obj.version = version_vec;
    obj.nicsa = nicsa_vec;
    obj.nacp = nacp_vec;
    obj.nicbaro = nicbaro_vec;
    obj.SIL = SIL_vec;
    obj.SILsb = SILsb_vec;
    obj.df = df_vec;
    obj.icao = icao_vec;

    
end
