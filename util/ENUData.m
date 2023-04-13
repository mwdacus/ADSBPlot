%% Code Information
%*************************************************************************
%Stanford GPS

%Function Description: Converts LLA to ENU data with specified origin, and
%places it in specified table

%*************************************************************************

function [data]=ENUData(lat,lon,alt,origin)
    enudata=lla2enu([lat,lon,alt],origin,'ellipsoid');
    data=cell2table(enudata,'VariableNames',{'x','y','z'});
end