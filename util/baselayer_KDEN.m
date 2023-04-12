%adding baselayer for denver

function [fig,R2,Z2]=baselayer_KDEN()
    fig=figure('color','w');
    %how to get 3d tiff file into 3d plot
    basemap='satellite';
    filename='n39_w105_1arc_v3.tif';
    [Z,RZ] = readgeoraster(filename,'OutputType','double');
    [latz,lonz]=geographicGrid(RZ);
    [A,RA,attrib] = readBasemapImage(basemap,RZ.LatitudeLimits,RZ.LongitudeLimits);
    latscale=RA.RasterSize(1)/RZ.RasterSize(1);
    lonscale=RA.RasterSize(2)/RZ.RasterSize(2);
    [Z2,R2] = georesize(Z,RZ,latscale,lonscale,'nearest');
    geoshow(Z2,R2,'DisplayType','surface',CData=A)
    axis normal
    hold on
    grid oN
end


