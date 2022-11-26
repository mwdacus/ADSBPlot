function interference(obj, varargin)
    % interference 
    % 
    % DESCRIPTION:
    %   function to simulated impact of user defined interference sources
    %   on pre-generated simulated ADS-B data. This includes simulated 
    %   updates of aircraft NIC value as well as received jamming power.
    %   In addition, it will save a copy of interference information such as
    %   transmitted jamming power, jammer location, and numbers of jammers.
    %   
    %
    % OPTIONAL INPUT:
    %   Pt          - [Watts] transmitted jamming power of the RIF source
    %   numJammers   - positive integer value
    %   jammer_lat  - [deg] jammer latitude location
    %   jammer_lon  - [deg] jammer longitude location
    %                   
    %                   
    % OUTPUT:
    %   update the obj with impact of user input interference source, save
    %   a copy of the interference information to obj: Pr[dBW], jammerLat,
    %   jammerLon, Pt[W], numJammers 
    %




    %% Parse inputs
    p = inputParser;
    addParameter(p,'Pt',100,@(x)validateattributes(x,{'numeric'},{'positive'}))
    addParameter(p,'numJammers',1,@(x)validateattributes(x,{'numeric'},{'integer','positive'}))
    addParameter(p,'jammer_lat',34.1,@(x)validateattributes(x,{'numeric'},{}))
    addParameter(p,'jammer_lon',33.73,@(x)validateattributes(x,{'numeric'},{}))
    
    parse(p, varargin{:});
    res = p.Results;
    Pt = res.Pt;
    numJammers = res.numJammers;
    jammer_lat = res.jammer_lat;
    jammer_lon = res.jammer_lon;





    %% Calculate received jamming power and corresponding NIC values
    allNIC = zeros(length(obj.lat), numJammers);
    allPr = zeros(length(obj.lat), numJammers);
    for k=1:numJammers
        allHorizonalDeg = distance(jammer_lat(k),jammer_lon(k),obj.lat,obj.lon);
        allHorizonalKm = deg2km(allHorizonalDeg);

        % RHR_horizontal_dis[km] = 4.12*(sqrt(H_jammer[m])+sqrt(H_critical[m]))
        allCriticalAlt = (allHorizonalKm/4.12 - sqrt(0)).^2; % allCriticalAlt [m]
        % Points within line of sight 
        ind_pos = find(obj.alt>=allCriticalAlt);% seen 

        % Distance to the jammer
        allDistanceKm =  sqrt(allHorizonalKm.^2+(0.001.*obj.alt).^2);
        % Points within impact region 
        R = 200/sqrt(1000/Pt(k));% Convert P_t to impact radius: 1000[W] = 200[km]
        ind_pos2 = find(allDistanceKm <= R); % jammed

        % Points being impacted: being seen and jammed
        posInd = intersect(ind_pos, ind_pos2);

        
        R_squared = allDistanceKm(posInd).^2;
        % normalized R^2 into values between 0 and 1
        R_squared_normalized = R_squared/R(k).^2;
        % power receieved = 0 if too far and 1 if quite close
        allNIC(posInd, k) = (1-R_squared_normalized);

        Pr = ADSBtools.const.powerLoss_coeff*Pt(k)./(R_squared*1000^2);

        allPr(posInd, k) = Pr;
        
    end
    pr = sum(allPr,2);
    nic = 1-sum(allNIC,2); 
    nic(nic<0) = 0;
    nic = round(nic*7);

    % convert pr from [W] to 10*log10 [dBW]
    negInd = find(pr==0); posInd = find(pr ~= 0);
    pr(posInd) = 10*log10(pr(posInd));
    pr(negInd) = -inf;
    % combine jammed NIC with non-jammed NIC
    nic(negInd) = obj.nic(negInd);




    %% Add noise too NIC value 
    % 3)the case where NIC == 1,2,3 becomes NIC == 0
    mid_jammed_ind = find(ismember(nic,[1 2 3]));
    if ~isempty(mid_jammed_ind)
        % about 70 percent of middle level jammed points(nic==1 or 2)
        % should drops down to nic == 0
        rand_target_ind = randperm(length(mid_jammed_ind));
        prob = 0.7;
        inner_selected_ind = rand_target_ind(1:floor(length(mid_jammed_ind)*prob));
        final_selected_ind = mid_jammed_ind(inner_selected_ind);
        nic(final_selected_ind) = 0; 
    end

     % 4) the case where NIC == 4,5,6 can be jumping back and forth
    prob_3 = sum(rand >= cumsum([0,1])); 
    if prob_3 == 1
        target_ind = find(ismember(nic,[4 5 6]));
        target_noise_nic = nic(target_ind);
        nic_wnoise = floor(target_noise_nic + 0.1*randn(size(target_noise_nic)));
        nic(target_ind) = nic_wnoise;
    end






    %% save simulated result to obj
    obj.Pr = pr;
    obj.nic = nic;
    obj.jammerLat = jammer_lat;
    obj.jammerLon = jammer_lon;   
    obj.numJammers = numJammers;
    obj.Pt = Pt;


end