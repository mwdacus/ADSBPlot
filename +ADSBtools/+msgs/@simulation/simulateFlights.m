function simulateFlights(obj, numOfFlights, max_Alt, step_size, ...
    lon_edge, lat_edge, numlostarea, lost_center_lat, lost_center_lon, lost_R)
    % simulateFlights 
    % 
    % DESCRIPTION:
    %   function to generate simulated ADS-B data. This includes 
    %   simulated aircraft trajectory latitude, longitude, NIC,
    %   altitude[m], flight number. Depends on user's request,
    %   it can have different traffic volumes. 
    %   
    %
    % INPUT:
    %   numOfFlights - numbers of flights in current airspace
    %   max_Alt      - [m] maximum altitude that can be reached for each aircraft
    %   step_size    - [deg] averaged position point step size of each aircraft
    %   lon_range    - [deg] longitude range of the airspace: [west east]
    %   lat_range    - [deg] latitude range of the airspace: [south north]
    %   numlostarea  - positive integer value, numbers of area with no data received
    %   due to non-coverage of ground receiver     
    %                   
    %                   
    % OUTPUT:
    %   update the obj with information from simulated flights: lat, lon,
    %   alt, nic, icao
    %



    for j = 1:1:numOfFlights   
        %% Design starting point and ending point of the flight path
        option = randperm(2,1);
        if option == 1
            % Type 1: flying pass the airspace 
            flight = flight_passing_airspace(lon_edge, lat_edge); %lon, lat
        else
            % Type 2: Taking off/landing at airports within airspace
            flight = flight_takingoff_landing(lon_edge, lat_edge);  %lon, lat
            % the first row is a point within the airspace [landed or took-off point]
            % the second row is a point on the edge of airspace
        end
    
    
        %% Design average altitude of the flight
        flight_mean_alt = max_Alt*rand(1,1);
    
    
    
        %% Design position points along the entire flight
        if flight(1,1) < flight(2,1)
            lon_step = flight(1,1):step_size:flight(2,1);
        else
            lon_step = flight(1,1):-step_size:flight(2,1);
        end
    
        if flight(1,2) < flight(2,2)
            lat_step = flight(1,2):step_size:flight(2,2);
        else
            lat_step = flight(1,2):-step_size:flight(2,2);
        end
        n = max(length(lat_step), length(lon_step));
    
    
        if option == 1
            % Altitude variation for flight pasing airspace
            alt = 100*rand(1,n) + flight_mean_alt;
        else
            % Altitude variation for flight taking off or landing
            mid_pt_percentage = 0.15;
            mid_pt_option = floor(n/2+n*mid_pt_percentage):n;
            mid_pt = mid_pt_option(randi(length(mid_pt_option),1)); % point when aircraft leveled off or start descending
            % because the first row in variable 'flight' is always the point
            % within the airspace, therefore, alt for that point should always
            % be 0
            alt_1 = linspace(0, flight_mean_alt, mid_pt);
            alt_2 = linspace(flight_mean_alt, flight_mean_alt, n-mid_pt);
            alt = [alt_1 alt_2];
        end
    
        if length(lat_step) < length(lon_step)
            lat_step = linspace(flight(1,2), flight(2,2), n);
        else
            lon_step = linspace(flight(1,1), flight(2,1), n);
        end
        




        
        %% Add gaps inside flight paths
        % 1) the case where random drop of data point caused by receiver 
        prob_1 = sum(rand >= cumsum([0,0.1])); 
        % rand generates number from 0 to 1, [0, 0.2] is the size of
        % segment that returns number 1, [0.2, 1] is the size of segment
        % that returns number 2. Therefore, 20% probability of number 1 and 80%
        % probability of number 2.
        if prob_1 == 1
            total_num_pt = length(lon_step);
            rnd_ind = randperm(total_num_pt);
            drop_prob = 0.3; % 0.1 -> ten percent of the data points are lost
            rnd_drop_ind = rnd_ind(1:floor(total_num_pt*drop_prob)); 
            lon_step(rnd_drop_ind) = [];
            lat_step(rnd_drop_ind) = [];
            alt(rnd_drop_ind) = [];
        end
        
        % 2) lost of data point due to non-coverage of ground receiver
        if numlostarea ~= 0
            lost_Ind = [];
            for k =1:1:length(lost_R)
                % lat,lon boundary of non-covered area
                [pt_nw_lost, pt_ne_lost, pt_se_lost, pt_sw_lost] = ...
                ADSBtools.util.airspace([lost_center_lat(k) lost_center_lon(k)], km2nm(lost_R(k)));
                % Find latitude and longitude points within the edges of lost area 
                lon_lost_ind = find(lon_step>pt_nw_lost.Longitude & lon_step<pt_ne_lost.Longitude); %>W, <E
                lat_lost_ind = find(lat_step>pt_sw_lost.Latitude & lat_step<pt_nw_lost.Latitude); %>S, <N
                all_lost_ind = intersect(lon_lost_ind,lat_lost_ind);
                lost_Ind = union(lost_Ind, all_lost_ind);
            end
            lon_step(lost_Ind) = [];
            lat_step(lost_Ind) = [];
            alt(lost_Ind) = [];
        end





        %% Add NIC values with noise
        nic = 7*ones(size(alt));

        % 1) the case where all NIC == 0 caused by on-broad sensor problem
        prob_1 = sum(rand >= cumsum([0,0.005])); %0.5 percent probability of encountering this flight
        if prob_1 == 1
            nic = zeros(size(alt));
        end
    
        % 2) the case where NIC == 6,7,8 can be jumping back and forth
        prob_2 = sum(rand >= cumsum([0,0.1])); % 10 percent probability of having this effect
        if prob_2 == 1
            target_ind = find(ismember(nic,7));
            target_noise_nic = nic(target_ind);
            radn_ind = randperm(length(target_noise_nic));
            target_noise_nic(radn_ind(1:round(length(radn_ind)/2))) = ...
                target_noise_nic(radn_ind(1:round(length(radn_ind)/2))) + 1; 
            % add gaussian noise to nic=[6,7,8] with mean 0 and var 0.1
            nic_wnoise = floor(target_noise_nic + 0.1*randn(size(target_noise_nic)));
            nic(target_ind) = nic_wnoise;
        end
    
    

       
    
    
        %% save simulated result to obj
        local_n = length(lon_step);
        obj.lon(end+1:end+local_n, 1) = lon_step';
        obj.lat(end+1:end+local_n, 1) = lat_step';
        obj.alt(end+1:end+local_n, 1) = alt';
        obj.icao(end+1:end+local_n, 1) = "flight_"+num2str(j);   
        obj.nic(end+1:end+local_n, 1) = nic';


    
     end
    
       

end








    %% HELPER FUNCTIONS
    function flight = flight_takingoff_landing(lon_edge, lat_edge)
        % One point is anywhere in the airspace, Another point is anywhere on edge
    
        % Randomly select points within range of lon_edge/ lat_edge
        randLon = (lon_edge(2)-lon_edge(1))*rand(2,1) + lon_edge(1); 
        randLat = (lat_edge(2)-lat_edge(1))*rand(2,1) + lat_edge(1);
        Point1 = [randLon(1) randLat(1)]; %Lon Lat
    
        % 2 options
        % 1) Point on west or east edge
        All_type.type_1 = [lon_edge(randperm(2,1)) randLat(2)]; % Lon Lat
        % 2) Point on north or south edge
        All_type.type_2 = [randLon(2) lat_edge(randperm(2,1))]; % Lon Lat
    
        option = randperm(2,1);
        type_name = strcat('type_',num2str(option));
        Point2 = All_type.(type_name);
    
        flight = [Point1; Point2];
    
    end
    
    
    
    
    
    
    function flight = flight_passing_airspace(lon_edge, lat_edge)
        % Input: The latitude and longitude information of edges 
        % Output: The starting and ending point of the flight
    
        % Randomly select points within range of lon_edge/ lat_edge
        randLon = (lon_edge(2)-lon_edge(1))*rand(2,1) + lon_edge(1); 
        randLat = (lat_edge(2)-lat_edge(1))*rand(2,1) + lat_edge(1);
    
        % 3 options
        % 1) Flight crossing airspace between west and east
        All_type.type_1 = [lon_edge' randLat]; % Lon Lat
        % 2) Flight crossing airspace between north and south
        All_type.type_2 = [randLon lat_edge']; % Lon Lat
        % 3) Flight crossing airspace by cutting corner 
        All_type.type_3 = [[lon_edge(randperm(2,1)); randLon(1)], ...
            [randLat(1); lat_edge(randperm(2,1))]]; % Lon Lat
    
        option = randperm(3,1);
        type_name = strcat('type_',num2str(option));
        flight = All_type.(type_name);
    end
