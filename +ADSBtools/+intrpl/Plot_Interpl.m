%% Code Information
%*************************************************************************
%Michael Dacus                                               Stanford GPS

%Function Description: Plot Resulting ADS-B Data

%************************************************************************


function Plot_Interpl(adsb_data,interp_data,t)
    g=figure('color','w');
    gx=geoaxes();
    geoscatter(adsb_data.lat,adsb_data.lon,3,'o','filled','MarkerFaceAlpha',0.5)
    hold on
    geoscatter(interp_data.lat,interp_data.lon,3,'o','filled','MarkerFaceAlpha',0.5)
    %PlotError.CentPlot(interp_data)
    %Formatting Properties
    geobasemap('topographic')
    legend({'ADS-B','Interpolated Flight Paths'})
    dcm_obj = datacursormode(g);
    set(dcm_obj,'UpdateFcn',{@PlotFunctions.myupdatefcntopo,adsb_data})
    title(t)
    hold off
end