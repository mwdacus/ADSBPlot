function decodeLatLon(obj, rowNums, ref_pt)
    % DESCRIPTION:
    %   decode physical meaning values of latitude and longitude from ADS-B
    %   built-in latCPR and lonCPR values. Function follows the rules from
    %   MOPs DO-260.
    %   
    % INPUT:
    %   rowNums      - row indices of the current decoding pos_msgs in obj
    %                  (usually should be messages from same flight)
    %   ref_pt      - reference location for decoding latitude and longitude 
    %             
    % OUTPUT:
    %   obj will have new decoded latitude[deg] and longitude[deg] values for
    %   selected message, which is contained inside obj itself.

    
    % load useful information
    latCPR = obj.latCPR(rowNums); 
    lonCPR = obj.lonCPR(rowNums); 
    oddEvenFlag = obj.f(rowNums);
        

    decodedLat = NaN(length(oddEvenFlag),1);
    decodedLon = NaN(length(oddEvenFlag),1);
    NZ = 15;
    for j = 1:1:length(oddEvenFlag)
        %calculate lat
        if oddEvenFlag(j) == 1 || oddEvenFlag(j) == 0
            dlat = 360 / (4*NZ - oddEvenFlag(j));
        else 
            continue
        end
        indj = floor(ref_pt(1)/dlat) + floor(mod(ref_pt(1), dlat)/dlat - latCPR(j)/2^(17) + 1/2); 
        lat = dlat * (indj + latCPR(j)/2^(17));
        decodedLat(j) = lat;
        
        %calculate NL
        if lat == 0
            NL = 59;
        elseif abs(lat) == 87
            NL = 2;
        elseif abs(lat) > 87
            NL = 1;
        elseif abs(lat) < 87
            NL = floor(2*pi/acos(1-(1-cos(pi/2/NZ))/(cos(pi/180*lat)^2)));
        end
        
        %calculate lon
        if oddEvenFlag(j) == 1
            NL = NL -1;
        end
        
        if NL > 0
            dlon = 360/NL;
        elseif NL == 0
            dlon = 360;
        end
        indm = floor(ref_pt(2)/dlon) + floor(mod(ref_pt(2), dlon)/dlon - lonCPR(j)/2^(17) + 1/2);
        lon = dlon * (indm + lonCPR(j)/2^(17));
        decodedLon(j) = lon;
        
        ref_pt = [lat, lon];

    end
    
    % assign decoded latitude and longitude value to obj
    obj.lat(rowNums) = decodedLat;  obj.lon(rowNums) = decodedLon;
    
end