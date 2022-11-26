classdef simulation < ADSBtools.msgs.pos    
    properties
        Pr          % jamming power received on the aircraft [dBW]
        jammerLat   % jammer latitude [deg]
        jammerLon   % jammer longitude [deg]
        Pt          % jammer transmitted power [W]
        numJammers  % numbers of jammers [positive integer]
    end
    

    methods
        function simulatedData(obj, varargin)
            % simulatedADSBdata 
            % 
            % DESCRIPTION:
            %   function to generate simulated ADS-B data. This includes 
            %   simulated aircraft trajectory latitude, longitude, NIC,
            %   altitude[m], flight number. Depends on user's request,
            %   it can have different traffic volumes. 
            %   
            %
            % OPTIONAL INPUT:
            %   numOfFlights - numbers of flights in current airspace
            %   max_Alt      - [m] maximum altitude that can be reached for each aircraft
            %   step_size    - [deg] averaged position point step size of each aircraft
            %   lat_range    - [deg] latitude range of the airspace: [south north]
            %   lon_range    - [deg] longitude range of the airspace: [west east]
            %   numlostarea  - positive integer value, numbers of area with no data received
            %   due to non-coverage of ground receiver     
            %                   
            %                   
            % OUTPUT:
            %   simulated_data - a struct of simulated ADS-B data 
            %



            %% Parse inputs
            p = inputParser;
            addParameter(p,'numOfFlights',round((200-50).*rand(1) + 50),@(x)validateattributes(x,{'numeric'},{'integer','nonnegative'}))
            addParameter(p,'max_Alt',14000,@(x)validateattributes(x,{'numeric'},{'>',2000,'<',20000}))
            addParameter(p,'step_size',0.03,@(x)validateattributes(x,{'numeric'},{'>',0,'<',0.1}))
            addParameter(p,'lat_range',[31.13 37.07],@(x)validateattributes(x,{'numeric'},{'nondecreasing'}))
            addParameter(p,'lon_range',[29.97 37.49],@(x)validateattributes(x,{'numeric'},{'nondecreasing'}))
            addParameter(p,'numlostarea',0,@(x)validateattributes(x,{'numeric'},{'integer','nonnegative'}))

            parse(p, varargin{:});
            res = p.Results;
            numOfFlights = res.numOfFlights;
            max_Alt = res.max_Alt;
            step_size = res.step_size;
            lat_range = res.lat_range;
            lon_range = res.lon_range;
            numlostarea = res.numlostarea;





            %% Design airspace 
            % design area in the airspace where no information will be received
            % (simulating lost of data point due to non-coverage of ground receiver)
            if numlostarea ~= 0
                horizonalDeg = distance(lat_range(1),lon_range(1),lat_range(1),lon_range(2));
                radius_Km = deg2km(horizonalDeg);
                lost_center_lat = (lat_range(2)-lat_range(1)).*rand(numlostarea,1) + lat_range(1);
                lost_center_lon = (lon_range(2)-lon_range(1)).*rand(numlostarea,1) + lon_range(1);
                lost_R = (radius_Km/10-radius_Km/11).*rand(numlostarea,1) + radius_Km/11; %[km] in radius 
            else
                lost_center_lat = [];  lost_center_lon = []; lost_R = [];
            end





            %% Simulated flight paths        
            % generate simulated flights
            obj.simulateFlights(numOfFlights, max_Alt, step_size, lon_range, ...
                lat_range, numlostarea, lost_center_lat, lost_center_lon, lost_R);
                        

        end
    end



    

    methods
        % simulate flight trajectories
        simulateFlights(obj, numOfFlights, max_Alt, step_size, ...
            lon_edge, lat_edge, numlostarea, lost_center_lat, lost_center_lon, lost_R)

        % add interference events
        interference(obj,varargin)

        % visualize simulated data
        Create2Dplot(obj)


    end


end

