
%% Code Information
%*************************************************************************
%Michael Dacus                                               Stanford GPS

%Function Description: Processes the incoming raw ADS-B messages, prior to interpolation. 
% This includes:
    %removing inconsistent timeclocks
    %removing duplicate messages that might affect interpolation
    %cleaning icao codc
%************************************************************************

function [data_filter] = Process_ADSB(D)
    %Remove space within icao number in string
    D.icao=strtrim(D.icao);
    %Check if latitude, longitude, or altitude is a string value, if so, convert to double
    posnames={'lat','lon','alt'};
    for i=1:numel(posnames)
        if isa(D.(posnames{i}),'cell')==1
            D.(posnames{i})=str2double(D.(posnames{i}));
        end
    end
    %Convert Date Strings in DateTime
    if isa(D.time,'datetime')==0
        D.time=datetime(D.time,'InputFormat','yyyy-MM-dd hh:mm:ss.S', ...
            'Format', 'yyyy-MM-dd hh:mm:ss.SSS','TimeZone','UTC');
    end
    %Remove rows with NaN
    D=D(~any(ismissing(D),2),:);
    %Remove Columns with NaN
    D=D(:,~any(ismissing(D),1));
    %find column number of message, time, aircraft and receiver
    msg_ind=find(string(D.Properties.VariableNames)=="rawmsg");
    t_ind=find(string(D.Properties.VariableNames)=="time");
    a_ind=find(string(D.Properties.VariableNames)=="icao");
    r_ind=find(string(D.Properties.VariableNames)=="serial");
    %Removing Incorrect TimeStamps 
    tar=D(:,[t_ind,a_ind,r_ind]);
    [~,~,ic]=unique(tar,'rows','stable');
    h=accumarray(ic,1);
    D.num_occ=h(ic);
    D=D(D.num_occ==1,1:end-1);   
    %Make a new Column for DateTime
    %D.date=datetime(D.time,"ConvertFrom",'posixtime','TimeZone','UTC', ...
    %    'Format','dd-MMM-uuuu HH:mm:ss.SSS');
    %Remove duplicate messages at same time instance (was
    %originally [msg_ind,t_ind])
    msgtime=D(:,t_ind);
    [~,IA,~]=unique(msgtime,'rows','first');
    data_filter=D(IA,1:end);
end

