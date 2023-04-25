%% Code Information
%*************************************************************************
%Stanford GPS

%Creates a .mat file using data from UI (MAIN_EventUpload) 

%*************************************************************************

function [pkg]=FormStruct(app)
        %Define main struct
        %Define airport struct
        location=struct('lat',app.Lat.Value,'lon',app.Lon.Value,'alt',app.Alt.Value);
        airport=struct('icao',app.AirportICAO.Value,'Name',app.NearestAirportName.Value,...
            'Location',location);
        %Read ADS-B Data to populate struct
        starttime=min(app.adsbdata.time);
        endtime=max(app.adsbdata.time);
        aircraft={unique(app.adsbdata.icao)};
        boxlat=[min(app.adsbdata.lat) max(app.adsbdata.lat)];
        boxlon=[min(app.adsbdata.lon) max(app.adsbdata.lon)];
        boxalt=[min(app.adsbdata.alt) max(app.adsbdata.alt)];
        %Create East-North-Up Table, combine with original adsbdata
        [enudata]=ENUData(app.adsbdata.lat,app.adsbdata.lon,app.adsbdata.alt,...
            [location.lat,location.lon,location.alt]);
        app.adsbdata=[app.adsbdata enudata];
        %Get Elevation Data
        [elevdata,geodata]=GetElevationData(boxlat,boxlon,app.UsernameEditField.Value,...
            app.PasswordEditField.Value);
        %Define struct
        app.eventdata=struct('Airport_Info',airport,'Start_Date',...
            app.StartInterference.Value,'End_Date',app.EndInterference.Value,...
            'StartTime',starttime,'EndTime',endtime,'Aircraft',aircraft,...
            'boxlat',boxlat,'boxlon',boxlon,'boxalt',boxalt,...
            'adsbdata',app.adsbdata,'Z',elevdata,'RZ',geodata);
        pkg=app.eventdata;
end


%% Local Functions
%Add ENU table to existing dataset
function [data]=ENUData(lat,lon,alt,origin)
    enudata=lla2enu([lat,lon,alt],origin,'ellipsoid');
    data=array2table(enudata,'VariableNames',{'x','y','z'});
end