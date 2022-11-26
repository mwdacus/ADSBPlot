%% Code Information
%*************************************************************************
%Michael Dacus                                               Stanford GPS

%Function Description: Calculate velocity, ground speed and vertical speed
%given position data 

%************************************************************************


function [final_data]=CalcDynamics(combined_data) 
    reltime=seconds(combined_data.time-combined_data.time(1));
    counter=2;
    for i=2:size(combined_data,1)-1
        vel_x=(combined_data.x(i+1)-combined_data.x(i-1))/...
            (reltime(i+1)-reltime(i-1));
        vel_y=(combined_data.y(i+1)-combined_data.y(i-1))/...
            (reltime(i+1)-reltime(i-1));
        combined_data.vertrate(counter)=(combined_data.z(i+1)-combined_data.z(i-1))/...
            (reltime(i+1)-reltime(i-1));
        combined_data.velocity(counter)=sqrt(vel_x^2+vel_y^2);
        counter=counter+1;
    end
    [h,~]=legs(combined_data.lat,combined_data.lon);
    combined_data.heading=[h(1);h];
    final_data=combined_data(2:end-1,:);
end
