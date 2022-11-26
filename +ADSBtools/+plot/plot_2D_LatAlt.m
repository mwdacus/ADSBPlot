function plot_2D_LatAlt(fig,time, lat, alt, nic, icao, option)
    cla(fig,'reset')
    % optional input: varargin to determine which type of plt, either shows
    % all nic values or show only jammed vs non-jammed points
    if option == 0
        nic_plt = nic;
        C = ADSBtools.util.distinguishable_colors(100); % colormap 
    elseif option == 1
        % jammed vs non-jammed plt
        C = [0.4660 0.6740 0.1880; 1 0 0]; % colormap
        nic_plt = zeros(size(nic));
        % all NIC < 7 are red, all NIC >=6 are green
        nic_plt(nic < 7) = 1;
    else
        error("Usage: " + ...
            "plot_2D_TimeAlt(time, alt, nic, icao, option). " + ...
            "Valid option: 0 (plot original nic value), " + ...
            "1 (plot in terms of jammed[NIC<7], non-jammed[NIC>=7])")
    end

   
    % observed unique NIC values
    seenNic = unique(nic_plt);   


    s=scatter(fig,lat, alt, 3, C(nic_plt+1,:), 'filled', 'HandleVisibility','off');
    grid(fig,'on'); hold(fig,"on");
    % add tip information about icao
    row1 = dataTipTextRow('ICAO', icao);
    row2 = dataTipTextRow('NIC', nic);
    row3 = dataTipTextRow('Time', time);
    s.DataTipTemplate.DataTipRows(end+1) = row1;
    s.DataTipTemplate.DataTipRows(end+1) = row2;
    s.DataTipTemplate.DataTipRows(end+1) = row3;
    % add legend
    if option == 0
        for k = 1:1:length(seenNic)
            plot(fig,nan, nan, 'color', C(seenNic(k)+1,:), 'marker', '.', ...
                'DisplayName', "NIC = " + string(seenNic(k)) + " with " + ...
                string(sum(nic_plt == seenNic(k))) + " points", 'MarkerSize', 10);
        end
    else
        for k = 1:1:length(seenNic)
            if seenNic(k) == 0
                plot(fig,nan, nan, 'color', C(seenNic(k)+1,:), 'marker', '.', ...
                'DisplayName', "Nominal points: " + ...
                string(sum(nic_plt == seenNic(k))), 'MarkerSize', 10);
            else
                plot(fig,nan, nan, 'color', C(seenNic(k)+1,:), 'marker', '.', ...
                'DisplayName', "Jammed points: " + ...
                string(sum(nic_plt == seenNic(k))), 'MarkerSize', 10);
            end
            
        end

    end
    
    xlabel(fig,'Longitude [deg]')
    ylabel(fig,'Baro Altitude[m]')
    % title(string(round(seconds(max(data.time)-min(data.time))/60/60,2))+" hours of ADS-B data")
    startT = min(time);
    startT.Format = 'yyyy-MM-dd HH:mm:ss';
    endT = max(time);
    endT.Format = 'yyyy-MM-dd HH:mm:ss';
    title(fig,"ADS-B data from "+ string(startT) + " to " + string(endT))
    legend(fig);
    hold(fig,'off')

end