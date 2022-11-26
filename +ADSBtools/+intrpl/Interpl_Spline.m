%% Code Information
%*************************************************************************
%Michael Dacus                                               Stanford GPS

%Function Description: Use Cubic Spline Interpolation to interpolate over
%the entire flight trajectory path

%Input Information:
% aircraft_path:table

%Output Data:
%One combined file
%************************************************************************


function [filteredpath] = Interpl_Spline(aircraft_path)
     reltime=seconds(aircraft_path.time-aircraft_path.time(1));
%     %Find gaps in data,filter to interpolated data
%     [~,ind]=max(diff(reltime));
%     endgap=ind+21;
%     interpdata=aircraft_path(1:endgap,:);
    %interpolate data
    timecount=reltime(1):1:reltime(end);
    lat=spline(reltime,aircraft_path.lat,timecount)';
    lon=spline(reltime,aircraft_path.lon,timecount)';
    alt=spline(reltime,aircraft_path.alt,timecount)';
    velocity=spline(reltime,aircraft_path.velocity,timecount)';
    vertrate=spline(reltime,aircraft_path.vertrate,timecount)';
    heading=spline(reltime,aircraft_path.heading,timecount)';
    time=(seconds(timecount)+aircraft_path.time(1))';
    filteredpath=timetable(time,lat,lon,alt,velocity,vertrate,heading);
    filteredpath.icao24(:)=aircraft_path.icao(1);
end
