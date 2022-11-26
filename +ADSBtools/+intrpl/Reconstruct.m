%% Code Information
%*************************************************************************
%Michael Dacus                                               Stanford GPS

%Problem Statement:: (Use Method in paper Zheng et. al) that
%reconstructs flight path to equally spaced and smooth points (position
%only)
%Reconstructs the flight paths to a 1 second interval

%*************************************************************************


function [fulldata] = Reconstruct(aircraft_path,aircraft,origin)
    starttime=dateshift(aircraft_path.time(1),'start','second');
    endtime=dateshift(aircraft_path.time(end),'end','second');
    %Calculate interval (in seconds) of timestamps
    reltime=seconds(aircraft_path.time-starttime);
    time=(starttime:seconds(1):endtime)';
    %Establish length of the equally-spaced time interval
    n=length(time);
    abstime=seconds(time-starttime);
    %Create Design Matrix (A)
    A=zeros(size(aircraft_path,1),n);
    for i=1:length(reltime)
        [a,I]=mink(abs(reltime(i)-abstime),2);
        if I(1)<I(2)
            A(i,I(1):I(2))=[a(2) a(1)];
        else
            A(i,I(2):I(1))=[a(1) a(2)];
        end
    end
    %Create Tikonov Regularization Matrix (L)
    L=zeros(n-2,n);
    for j=1:n-2
        L(j,j)=1;
        L(j,j+1)=-2;
        L(j,j+2)=1;
    end
    %Define Original ADS-B reported positions
    P_0=[aircraft_path.x aircraft_path.y aircraft_path.z];
    %Flight Path Reconstruction (Closed Form Solution)
    lambda=100;
    P=inv(A'*A+lambda*L'*L)*A'*P_0;
    %Create Output Table
    %Convert back to LLA Coordinate Systems; Make TimeTable
    lladata=enu2lla(P,origin,'ellipsoid');
    lat=lladata(:,1);
    lon=lladata(:,2);
    alt=lladata(:,3);
    fulldata=timetable(time,lat,lon,alt);
    %Interpolate NIC/NAC value
    nic=zeros(n,1);
    for k=1:n
        [~,ind]=min(abs(abstime(k)-reltime));
        nic(k)=aircraft_path.nic(ind);
    end
    fulldata.nic=nic;
    fulldata.x=P(:,1);
    fulldata.y=P(:,2);
    fulldata.z=P(:,3);
    %Add Aircraft ICAO number
    fulldata.icao(:)={aircraft};
    %Calculate Dynamics
    fulldata=ADSBtools.intrpl.CalcDynamics(fulldata);
end
