function Create2Dplot(Lat, Lon, Alt, ADSBparam)
    % Create2Dplot 
    % 
    % DESCRIPTION:
    %   function to create bubble plot using Matlab built-in function.
    %   This shows flight paths with color-coded user input ADSBparam, 
    %   such as: NIC, NACp, NACv, SIL. 
    %   
    %
    % INPUT:
    %   Lat          - [deg] aircraft latitude
    %   Lon          - [deg] aircraft longitude
    %   Alt          - [m] aircraft altitude
    %   ADSBparam    - [int] NIC, NACp, NACv, SIL
    %
    %                   
    % OUTPUT:
    %   a visualization of bubble plot
    %

    % size of the plotting area on Earth
    lonEdge = [min(Lon)-1, max(Lon)+1];
    latEdge = [min(Lat)-1 max(Lat)+1];

    % Prepare color labels
    C = jet(length(unique(ADSBparam)));

    % plot onto earth map
    fig = figure('Name', '2Dplot', 'Visible', 'off');
    gb = geobubble(Lat,Lon,Alt, categorical(ADSBparam), ...
        'Basemap','satellite');
    gb.BubbleWidthRange = [1 7];
    gb.SizeLegendTitle = 'Altitude[m]';
    gb.BubbleColorList = C;

    geolimits(latEdge,lonEdge)
    title("2D top view of flight paths")
    warning('off','all')

    set(fig, 'Visible', 'on');
end

