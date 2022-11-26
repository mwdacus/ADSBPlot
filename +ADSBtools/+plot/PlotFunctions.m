%% Code Information
%*************************************************************************
%Michael Dacus                                               Stanford GPS

%Function Description: Define Various Plotting Functions based on user
%selection

%Input Data:
%Any ADS-B Dataset

%Output Data:
%Plots of ADS-B Flight Paths categorized by Marker

%CURRENT ISSUES:
%(8/28/2022) STILL NEED TO FIX ALTITUDE V. TIME MARKER
%************************************************************************

classdef PlotFunctions
    methods(Static)
        %Plot Data by nic value (2D and 3D value)
        function plotnic(flightdata)
            if contains('nic',flightdata.Properties.VariableNames)==0
                err_msg="This dataset does not include nic values.";
                error(err_msg)
            else
                %Plot 2D Map
                nicnum=unique(flightdata.nic);
                
                load('nicdata.mat');
                colors=[nicinfo.("NIC Value") jet(length(nicinfo.("NIC Value")))];
                ind=ismember(colors(:,1),nicnum);
                nic=colors(ind,:);
                PlotFunctions.plottopo(flightdata,nic)
                %3D map
                PlotFunctions.plotaerial(flightdata,nic)
                %Altitude
                PlotFunctions.plotalt(flightdata,nic)
            end
        end
        %Plot data by aircraft icao number
        function ploticao24(flightdata)
            if contains('icao24',flightdata.Properties.VariableNames)==0
                err_msg="This dataset does not include icao24 values.";
                error(err_msg)
            else
                %Plot 2D Map
                icao=unique(flightdata.icao24);
                PlotFunctions.plottopo(flightdata,icao)
                %3D map
                PlotFunctions.plotaerial(flightdata,icao)
                %Altitude
                PlotFunctrions.plotalt(flightdata,icao)
            end
        end
        %Plot by ADS-B Ground Receiver
        function plotreceiver(flightdata)
            if contains('serial',flightdata.Properties.VariableNames)==0
                err_msg="This dataset does not include ADSB ground station values.";
                error(err_msg)
            else
                %Plot 2D Map
                receiver=unique(flightdata.serial);
                PlotFunctions.plottopo(flightdata,receiver)
                %3D map
                PlotFunctions.plotaerial(flightdata,receiver)
                %Altitude
                PlotFunctins.plotalt(flightdata,receiver)
            end
        end
        %Plot 2D Topo map
        function plottopo(data,marker)
            %Topo map
            topo=figure('color','w');
            gx=geoaxes;

            for i=1:size(marker,1)
                filter_value=data(data.(inputname(2))==marker(i,1),:);
                geoplot(filter_value.lat,filter_value.lon,'o','MarkerSize',4,'Color',marker(i,2:4))
                hold on
            end
            %Formatting Properties (2D Topo)
            geobasemap('topographic')
            leg=legend(cellstr(num2str(marker(:,1))));
            title(leg,"NIC Value")
            dcm_obj = datacursormode(topo);
            set(dcm_obj,'UpdateFcn',{@PlotFunctions.myupdatefcntopo,data})
            hold off
        end
        %Plot 3D Aerial map
        function plotaerial(data,marker)
            aerial=figure('color','w');
            for j=1:size(marker,1)
                filter_value=data(data.(inputname(2))==marker(j,1),:);
                plot3(filter_value.lon,filter_value.lat,filter_value.alt,'o',...
                    'MarkerSize',4,'Color',marker(j,2:4))
                j=j+1;
                hold on
            end
            %Formatting Properties
            grid on
            xlabel('Longitude [degrees]')
            ylabel('Latitude [degrees]')
            zlabel('Altitude [degrees]')
            leg=legend(cellstr(num2str(marker(:,1))));
            title(leg,"NIC Value")
            dcm_obj = datacursormode(aerial);
            set(dcm_obj,'UpdateFcn',{@PlotFunctions.myupdatefcnaerial,data})
            hold off
        end
        %Plot Altitude v. Time
        function plotalt(data,marker)
            alt=figure('color','w');

            for j=1:size(marker,1)
                filter_value=data(data.(inputname(2))==marker(j,1),:);
                plot(filter_value.mintime,filter_value.alt,'o',...
                    'MarkerSize',2,'color',marker(j,2:4))
                j=j+1;
                hold on
            end
            %Formatting Properties
            grid on
            xlabel('Time (UTC)')
            ylabel('Altitude [m]')
            leg=legend(cellstr(num2str(marker(:,1))));
            title(leg,"NIC Value")
            dcm_obj = datacursormode(alt);
            set(dcm_obj,'UpdateFcn',{@PlotFunctions.myupdatefcnalt,data})
            hold off
        end
        %Plot Animation (FUTURE CODE)
        function [] = plot_flightanim(adsbdata,border)
            starttime=dateshift(adsbdata.time(1),'start','second');
            endtime=dateshift(adsbdata.time(end),'end','second');
            elapsedtime=starttime:seconds(15):endtime;
            %Set the frame dimensions
            gx=geoaxes();
            geobasemap('topographic')
            hold on
            geolimits(sort([border(2) border(1)]),sort([border(4) border(3)]));
            set(gcf, 'Position',  [0, 0, 1928, 1080])
            for i=1:length(elapsedtime)-1
                %Find data within time interval
                sorteddata=adsbdata(adsbdata.time<=elapsedtime(i+1) & ...
                    adsbdata.time>elapsedtime(i),:);
                %if there is no data in current frame
                if isempty(sorteddata)
                    p2=PlotPrevious(adsbdata,i,elapsedtime);
                    movieVector(i)=getframe;
                    delete(p2)
                    pause(0.1)                    
                    continue
                end
                p1=geoscatter(sorteddata.lat,sorteddata.lon,'blue');
                hold on
                %plot previous 1 minute of data (as a shadow effect)
                p2=PlotPrevious(adsbdata,i,elapsedtime);
                movieVector(i)=getframe;
                delete(p1)
                delete(p2)
                pause(0.1)
            end
            %Save movie
            myWriter=VideoWriter('test');
            myWriter.FrameRate=20;
            myWriter.Quality=85;
            open(myWriter)
            writeVideo(myWriter,movieVector)
        end
        %Functions to Plot UHARS Data (Single Aircraft)
        function UHARSPlot(flightdata)
            gx=geoaxes;
            geoplot(flightdata.lat,flightdata.lon,'o')
            geobasemap('topographic')
            hold off
            %Plot Altitude
            altplot=figure();
            plot(flightdata.Time,flightdata.alt,'o')
            hold on
            grid on
            xlabel('Time (UTC)')
            ylabel('Altitude (h) [m]')
            hold off
            %Plot 3D Plot of flight path
            aerialplot=figure();
            plot3(flightdata.lon,flightdata.lat,flightdata.alt,'o')
            hold on
            grid on
            xlabel('Longitude (lon) [degrees]')
            ylabel('Latitude (lat) [degrees]')
            zlabel('Altitude (alt) [meters]')
            hold off
        end
        %Add additional information to data cursor on figures
        function txt = myupdatefcntopo(~,event_obj,table)
            % Customizes text of data tips
            pos = get(event_obj,'Position');
            %find the row position in data set based on position values
            row=find(abs(table.lat-pos(1))<0.0001 & abs(table.lon-pos(2))<0.0001);
            txt = {['Longitude: ',num2str(pos(1))],...
                   ['Latitude: ',num2str(pos(2))],...
                   ['Time: ',datestr(table.mintime(row(1)))],...
                   ['Altitude: ',num2str(3.28084*table.alt(row(1)))],...
                   ['NIC: ',num2str(table.nic(row(1)))],...
                   ['ICAO: ',table.icao24{row(1)}]};
                 %,...
        end
        function txt = myupdatefcnaerial(~,event_obj,table)
        % Customizes text of data tips
        pos = get(event_obj,'Position');
        %find the row position in data set based on position values
        row=find(abs(table.lon-pos(1))<0.0001 & abs(table.lat-pos(2))<0.0001);
        txt = {['Longitude: ',num2str(pos(1))],...
               ['Latitude: ',num2str(pos(2))],...
               ['Time: ',datestr(table.mintime(row(1)))],...
               ['Altitude: ',num2str(3.28084*table.alt(row(1)))],...
               ['NIC: ',num2str(table.nic(row(1)))],...
               ['ICAO: ',table.icao24{row(1)}]};
             %,...
        end
        function txt = myupdatefcnalt(~,event_obj,table)
        % Customizes text of data tips
        pos = get(event_obj,'Position');
        %find the row position in data set based on position values
        row=find(abs(table.mintime-pos(1))<0.0001 & abs(table.alt-pos(2))<0.0001);
        txt = {['Longitude: ',num2str(pos(1))],...
               ['Latitude: ',num2str(pos(2))],...
               ['Time: ',datestr(table.mintime(row(1)))],...
               ['Altitude: ',num2str(3.28084*table.alt(row(1)))],...
               ['NIC: ',num2str(table.nic(row(1)))],...
               ['ICAO: ',table.icao24{row(1)}]};
             %,...
        end
    end
end
