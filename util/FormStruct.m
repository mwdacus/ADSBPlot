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
        boxlat=[min(app.adsbdata.lat) max(app.adsbdata.lat)];
        boxlon=[min(app.adsbdata.lon) max(app.adsbdata.lon)];
        boxalt=[min(app.adsbdata.alt) max(app.adsbdata.alt)];
        %find all part 91/135 and 121 aircraft
        all_aircraft=unique(app.adsbdata.icao);
        [icao91,icao121,icao135]=FindICAO(all_aircraft);
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
            'StartTime',starttime,'EndTime',endtime,'Aircraft',{all_aircraft},...
            'Part91',icao91,'Part121',icao121,'Part135',icao135,'boxlat',boxlat,...
            'boxlon',boxlon,'boxalt',boxalt,'adsbdata',app.adsbdata,'Z', ...
            elevdata,'RZ',geodata);
        pkg=app.eventdata;
end


%% Local Functions
%Add ENU table to existing dataset
function [data]=ENUData(lat,lon,alt,origin)
    enudata=lla2enu([lat,lon,alt],origin,'ellipsoid');
    data=array2table(enudata,'VariableNames',{'x','y','z'});
end

%find part 91, 135, and 121 aircraft icao codes
function [icao91,icao121,icao135]=FindICAO(icao)
    %find and read tables
    filename_opensky="\util\aircraftDatabase_Opensky.csv";
    filename_mitre="\util\aircraftDatabase_MITRE.xlsx";
    aircraft_reg_mitre_121=readtable(strcat(cd,filename_mitre),'Sheet',"Part 121");
    aircraft_reg_mitre_91135=readtable(strcat(cd,filename_mitre),'Sheet',"Parts 91_135");
    aircraft_reg_opensky=readtable(strcat(cd,filename_opensky));
    %Find tail numbers in OpenSky
    tailno=SearchOpenSky(icao,aircraft_reg_opensky);
    %Find Part 121 Aircraft
    icao121=SearchMITRE(aircraft_reg_mitre_121,aircraft_reg_opensky,...
        tailno,'Part 121');
    %Find Part 91 Aircraft
    icao91=SearchMITRE(aircraft_reg_mitre_91135,aircraft_reg_opensky, ...
        tailno,'Part 91');
    %Find Part 135 Aircraft
    icao135=SearchMITRE(aircraft_reg_mitre_91135,aircraft_reg_opensky, ...
        tailno,'Part 135');
end

%Gather tail numbers from opensky directory
function [tailno]=SearchOpenSky(icao,opensky_dir)
    ac_ind=ismember(opensky_dir.icao24,lower(icao));
    tailno=opensky_dir.registration(ac_ind);
    tailno=tailno(~cellfun('isempty',tailno));
end

%Find Part 121 Aircraft in Mitre Directory
function [mitre_data]=SearchMITRE(mitre_dir,opensky_dir,tailno,fr)
    if fr=="Part 121"
        mitre_ind=ismember(mitre_dir.Reg_,tailno);
        mitre_filt=mitre_dir(mitre_ind,:);
        icao121=FindICAOOpenSky(opensky_dir,mitre_filt.Reg_);
        mitre_data=CondenseICAOTable(mitre_filt,'121',icao121);
    elseif fr=="Part 91"
        mitre_091=mitre_dir(ismember(mitre_dir.CFR,'091'),:);
        mitre_filt=mitre_091(ismember(mitre_091.Reg_,tailno),:);
        [~,IA,~] = unique(mitre_filt.Reg_);
        unique_mitre_filt=mitre_filt(IA,:);
        icao91=FindICAOOpenSky(opensky_dir,unique_mitre_filt.Reg_);
        mitre_data=CondenseICAOTable(unique_mitre_filt,'091',icao91);
    else
        mitre_135=mitre_dir(ismember(mitre_dir.CFR,'135'),:);
        mitre_filt=mitre_135(ismember(mitre_135.Reg_,tailno),:);
        [~,IA,~] = unique(mitre_filt.Reg_);
        unique_mitre_filt=mitre_filt(IA,:);
        icao135=FindICAOOpenSky(opensky_dir,unique_mitre_filt.Reg_);
        mitre_data=CondenseICAOTable(unique_mitre_filt,'135',icao135);
    end   
end

%Find icao numbers from opensky
function [icao]=FindICAOOpenSky(opensky_dir,tailno)
    final_ind=ismember(unique(opensky_dir.registration),tailno);
    [~,IA,~] = unique(opensky_dir.registration);
    newtable=opensky_dir(IA,:);
    icao=newtable.icao24(final_ind);
end

%Sort Table Based on Mitre Data
function [icaotable]=CondenseICAOTable(mitre_filt,fr,icao)
    data=cell(size(mitre_filt,1),5);
    data(:,1)=mitre_filt.Reg_;
    data(:,2)=icao;
    data(:,3)=mitre_filt.Operator;
    data(:,4)=mitre_filt.Carrier;
    if fr=="121"
        data(:,5)=mitre_filt.AirplaneM_M_S;
    else
        data(:,5)=mitre_filt.Model_Series;
    end
    icaotable=cell2table(data,"VariableNames",{'Reg','icao','Operator',...
        'Carrier','Model'});
    icaotable.CFR=str2num(fr).*ones(size(mitre_filt,1),1);
end