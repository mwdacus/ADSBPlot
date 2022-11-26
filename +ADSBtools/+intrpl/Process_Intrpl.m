%% Code Information
%*************************************************************************
%Michael Dacus                                               Stanford GPS

%Function Description: Processes incoming ADS-B data prior to interpolation
%************************************************************************


function [finaldata] = Process_Intrpl(loadedData,origin,border)
    % Process ADS-B Data (Remove duplication messages, inconsistent
    %timeclocks, etc.)
    processeddata=ADSBtools.intrpl.Process_ADSB(loadedData);

    % Condense Processed Data based on parameter names (paramName)
    %condensedata=CondenseTable(processeddata);

    % Add ENU Data to Table
    combined_data=ENUAdd(processeddata,origin);

    % Find unique values for number of hours, and aircraft
%     [h,~,~]=hms(condensedata.time);
%     numhours=unique(h); 
    combined_air=unique(combined_data.icao);
    alldata=cell(1,numel(combined_air));
    finaldata=cell(1,numel(combined_air));
    
    % Separate in every hour, by every aircraft and reconstruct flight path
%     for hour=1:numel(numhours)
%         combined_data=condensedata(h==numhours(hour),:);
%         combined_air=unique(combined_data.icao);
%         alldata=cell(1,numel(combined_air));
        for j=1:numel(combined_air)

            %Filter to specific aircraft
            combined_data_aircraft=combined_data(strcmp(combined_data.icao, ...
                combined_air(j)),:);
            combined_data_aircraft = sortrows(combined_data_aircraft,'time', ...
                'ascend');

            %Check if there is less than 2 data points in aircraft flight path, if
            %so, do not include in final data set
            if size(combined_data_aircraft,1)<=2
                continue
            end   

             %Remove Outliers/Uninterpolated Positions
            [combined_data_aircraft]=VelCriteria(combined_data_aircraft);

            %Check again if there is insufficient data
            if size(combined_data_aircraft,1)<=2
                continue
            end   

            %Split into aircraft segments (gaps smaller than 10 seconds)
            delta_t=diff(seconds(combined_data_aircraft.time - ...
                combined_data_aircraft.time(1))');

            %find indices of flight gap
            delta_t_ind=[1 find((delta_t>10)) find((delta_t>10))+1 ...
                size(combined_data_aircraft,1)];
            delta_t_ind=sort(delta_t_ind,'ascend');

            %if there are no gaps (greater than 10 seconds), reconstruct trajectory
            %as one segment
            if length(delta_t_ind)==2
                alldata{j}=ADSBtools.intrpl.Reconstruct(combined_data_aircraft,...
                    combined_air{j},origin);
            % otherwise...
            else
                segmentdata=cell(numel(delta_t_ind)/2,1);
                counter=1;
                for k=1:2:numel(delta_t_ind)
                    if delta_t_ind(k)~=delta_t_ind(k+1)
                        segflight=combined_data_aircraft(delta_t_ind(k):delta_t_ind(k+1),:);
                        segmentdata{counter}=ADSBtools.intrpl.Reconstruct(segflight,combined_air{j},origin);
                        counter=counter+1;
                    else
                        continue
                    end
                end
                emptyind=cellfun(@isempty,segmentdata)==0;
                segmentdata=segmentdata(emptyind);
                alldata{j}=vertcat(segmentdata{:});
            end
            
            %Display the aircraft ID
            disp(combined_air{j})
        end
        finaldata=vertcat(alldata{:});
%         finaldata{hour}=vertcat(alldata{:});
%     end
%     finaldataday=vertcat(finaldata{:});
    
end

%% Local Functions    
%Compute and add ENU Data to table
function [aircraftpath]=ENUAdd(aircraftpath,origin)
    %Add ENU to Table
    enuframe=lla2enu([aircraftpath.lat aircraftpath.lon aircraftpath.alt],origin,"ellipsoid");
    aircraftpath.x=enuframe(:,1);
    aircraftpath.y=enuframe(:,2);
    aircraftpath.z=enuframe(:,3);
end

%Determine if flight path is interpolatable
function [finaldata]=VelCriteria(aircraft_path)
    aircraft_path=sortrows(aircraft_path,'time','ascend');
    aircraft_path=ADSBtools.intrpl.CalcDynamics(aircraft_path);
    sigma=movstd(aircraft_path.velocity,seconds(30),'SamplePoints',...
        aircraft_path.time);
    findout=sigma<50;
    finaldata=aircraft_path(findout,:);
end

%Filter original ADS-B format to condensed table
function [pos_data_filtered]=CondenseTable(positiondata)
    t_ind=find(string(positiondata.Properties.VariableNames)=="time");
    msg_ind=find(string(positiondata.Properties.VariableNames)=="rawmsg");
    lat_ind=find(string(positiondata.Properties.VariableNames)=="lat");
    lon_ind=find(string(positiondata.Properties.VariableNames)=="lon");
    alt_ind=find(string(positiondata.Properties.VariableNames)=="alt");
    nic_ind=find(string(positiondata.Properties.VariableNames)=="nic");
    icao_ind=find(string(positiondata.Properties.VariableNames)=="icao");
    %serial_ind=find(string(positiondata.Properties.VariableNames)=="serial");
    pos_data_filtered=positiondata(:,[t_ind,icao_ind,lat_ind,lon_ind,alt_ind, ...
        nic_ind]);
    pos_data_filtered=sortrows(pos_data_filtered,'time','ascend');
    %Convert to timetable
    pos_data_filtered=table2timetable(pos_data_filtered);
end
