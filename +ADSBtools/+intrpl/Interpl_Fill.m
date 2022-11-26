%% Code Information
%*************************************************************************
%Michael Dacus                                               Stanford GPS

%Function Description: Fill in gaps in the ADS-B data using a cubic spline
%interpolation that meet flight gap requirements

%************************************************************************


function [adsb_interp,adsb] = Interpl_Fill(processed_data)
    %Categorize data by flight profile (see FlightProfile), and determine
    %if meets requirements (InterpCriteria)
    interp_cell={};
    interp_cell_hour={};
    adsb_cell0={};
    adsb_cell7={};

    %Go through data by hour, by every aircraft to determine if flight path
    %is interpolatable
    [h,~,~]=hms(processed_data.time);
    numhour=unique(h); 
    for hour=1:numel(numhour)
        hourdata=processed_data(h==numhour(hour),:);
        nominaldata={};
        aircraft=unique(hourdata.icao);
        for k=1:numel(aircraft)
            aircraft_path=hourdata(strcmp(hourdata.icao,aircraft{k}),:);
            aircraft_path = sortrows(aircraft_path,'time','ascend');
            delta_t=diff(seconds(aircraft_path.time-aircraft_path.time(1)));
            delta_t_ind=find(delta_t>10);
            %go through every flight gap in path
            for l=1:sum(delta_t>10)
                %Determine the Flight profile of the flight gap
                filtered_data=aircraft_path(delta_t_ind(l):delta_t_ind(l)+1,:);
                profile_ident=ADSBtools.intrpl.FlightProfile(filtered_data);
                %Determine if flight gap can be interpolated, if so
                %execute interpolation function
                result=InterpCriteria(profile_ident,...
                    delta_t(delta_t_ind(l)));
                if result==1
                    interp_cell_hour{end+1}=InterpPred(aircraft_path,...
                        delta_t(delta_t_ind(l)),delta_t_ind(l));

                    %add adsb flight path if interpolation is nic=0
                    if aircraft_path.nic(delta_t_ind(l))==0 || ...
                            aircraft_path.nic(delta_t_ind(l)+1)==0
                        adsb_cell0{end+1}=aircraft_path;
                    end
                    %if adsb flight path if interpolation is greater than 7
                    if aircraft_path.nic(delta_t_ind(l))>7 || ...
                            aircraft_path.nic(delta_t_ind(l)+1)>7
                        adsb_cell7{end+1}=aircraft_path;
                    end
                end
            end
        end
        %Concatenate Data within the hour
        interp_cell{hour}=vertcat(interp_cell_hour{:});  
        fprintf("Hour %s\n",num2str(hour))
    end
    
    %Concatenate Interpolated and ADS-B Data used in Interpolation
    adsb_interp=vertcat(interp_cell{:});
    adsb0=vertcat(adsb_cell0{:});
    adsb7=vertcat(adsb_cell7{:});
    adsb={adsb0,adsb7};
end


%% Local Functions 
%Criteria for interpolating data
function [result]=InterpCriteria(flight_profile,gap_length)
    if flight_profile=="Straight and Level" && gap_length<=240
        result=1;
    elseif flight_profile=="Multiple Maneuvers" && gap_length<=80
        result=1;
    elseif flight_profile=="Climb or Descent" && gap_length<=180
        result=1;
    else
        result=0;            
    end
end

%Execute Flight Profile
function [interpdata]=InterpPred(aircraft_path,gap_length,gap_ind)
    pred_data=ADSBtools.intrpl.Interpl_Spline(aircraft_path);
    %cut 
    ind=find(pred_data.time == aircraft_path.time(gap_ind), 1);
    interpdata=pred_data(ind+1:ind+gap_length-1,:);
    %Interpolate NIC/NAC value
    nicval=min(aircraft_path.nic(gap_ind),aircraft_path.nic(gap_ind+1));
    interpdata.nic=nicval*ones(size(interpdata,1),1);
end