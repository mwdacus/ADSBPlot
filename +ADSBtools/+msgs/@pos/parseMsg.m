function parseMsg(obj, pos_msg) 
    % DESCRIPTION:
    %   parse one ADS-B hexString airborne position message following rules
    %   from MOPs DO-260. 
    %   
    % INPUT:
    %   pos_msg - raw hexString of ADS-B airborne position message
    %  
    %             
    % OUTPUT:
    %   obj will have new decoded information from one selected message 
    %   inside itself, see below for details of decoded vars. Also this 
    %   book explains ADS-B quite well: https://mode-s.org/decode/



    %% Load Annex10, Volume 4
    % For airborne position message only:
    % obtain the table for 100ft altitude increment in Annex 10
    p = mfilename('fullpath');
    subfolders = find(p=='\');
    load(p(1:subfolders(end))+"sortedTable.mat");

    %% loop through all the messages and get the components of each message
    Nmsgs = length(pos_msg);
    tc_vec = zeros(1, Nmsgs)';
    ss_vec = zeros(1, Nmsgs)';
    alt_vec = zeros(1, Nmsgs)';
    nicsb_vec = zeros(1, Nmsgs)';
    t_vec = zeros(1, Nmsgs)';
    f_vec = zeros(1, Nmsgs)';
    latCPR_vec = zeros(1, Nmsgs)';
    lonCPR_vec = zeros(1, Nmsgs)';
    df_vec = zeros(1, Nmsgs)';
    nucp_vec = zeros(1, Nmsgs)';
    icao_vec = string(zeros(1,Nmsgs))';
    probInd = []; % save index information for nan message

    for i = 1:Nmsgs
        % convert to a binary string representation of the data
        binStr = num2str(hexToBinaryVector(pos_msg{i}));
        binStr = strrep(binStr, ' ', '');
    
    
        % Parse message bits by bits
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
        
        % get the type code from the data (airborne position type codes: 0, 9-18, 20-22)
        tc = bin2dec(msgDataBinStr(1:5)); 
        
        % do not decode messages that are corrupted 
        if df ~= 17 || ((tc < 9 || tc > 18) && ~ismember(tc, [0,20,21,22]))
            nucp = nan; ss = nan; nicsb = nan; alt = nan; t = nan;
            f = nan; latCPR = nan; lonCPR = nan; probInd = [probInd i];
            continue
        end
    
        % CRC
        % NOTE: will just be ignoring this value for now...
        crc = bin2dec(binStr(89:112));
    
        % altitude
        alt = msgDataBinStr(9:20);
        % 1) baro-altitude: barometric pressure altitude relative
        % 1013.25millibars (not baro-corrected altitude) [tc = 9:18]
        % 2) HAE: GNSS height above ellipsoid [tc = 20:22] 
        if string(alt) == "000000000000" % altitude data is not available
        alt = nan;
        elseif alt(8) == '1'
            %1: 25 ft
            dig = 25;
            alt = [alt(1:7), alt(9:end)];
            alt = bin2dec(alt)*dig-1000;
            alt = alt * 0.3048; % the altitude has the accuracy of +/- 25 ft, ft to m
        elseif alt(8) == '0'
            % 0: 100 ft
            alt = ADSBtools.msgs.pos.checkInAnnex10(alt, sortedTable);
        end


    
        % get nucp from tc value, applicable only to version 0 
        switch tc
            case 9
                nucp = 9;
            case 10
                nucp = 8;
            case 11
                nucp = 7;
            case 12
                nucp = 6;
            case 13
                nucp = 5;
            case 14
                nucp = 4;
            case 15
                nucp = 3;
            case 16
                nucp = 2;
            case 17
                nucp = 1;
            case 18
                nucp = 0;
            case 0
                nucp = 0;
            case 20
                nucp = 9;
            case 21
                nucp = 8;
            case 22
                nucp = 0;
        end
    
        % surveillance status (ss)
        ss = bin2dec(msgDataBinStr(6:7));
    
        % NIC supplement B
        nicsb = bin2dec(msgDataBinStr(8));
    
        % Time flag
        t = bin2dec(msgDataBinStr(21));
    
        % CPR odd/even frame flag
        f = bin2dec(msgDataBinStr(22));
    
        % Latitude in CPR format
        latCPR = bin2dec(msgDataBinStr(23:39));
    
        % Longitude in CPR format
        lonCPR = bin2dec(msgDataBinStr(40:56)); 



        % save decoded result to vector(speed up process than directly save to obj)
        tc_vec(i) = tc; ss_vec(i) = ss; alt_vec(i) = alt; nicsb_vec(i) = nicsb;
        t_vec(i) = t; f_vec(i) = f; latCPR_vec(i) = latCPR; lonCPR_vec(i) = lonCPR;
        df_vec(i) = df; nucp_vec(i) = nucp; icao_vec(i) = icao;


    end


    % save decoded information into struct
    obj.df = df_vec;
    obj.icao = icao_vec;
    obj.tc = tc_vec;
    obj.nucp = nucp_vec;
    obj.ss = ss_vec;
    obj.alt = alt_vec;
    obj.nicsb = nicsb_vec;
    obj.t = t_vec;
    obj.f = f_vec;
    obj.latCPR = latCPR_vec;
    obj.lonCPR = lonCPR_vec;


    % remove nan messages
    fn = properties(obj);
    for i = 1:1:length(fn)
        if ~isempty(obj.(fn{i})) 
            obj.(fn{i})(probInd) = [];
        end
    end



end
        