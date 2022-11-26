function plot_2D_TimeNums(time, nic, option)
    % optional input: varargin to determine which type of plt, either shows
    % all nic values or show only jammed vs non-jammed points
    if option == 0
        nic_plt = nic;
        C = ADSBtools.util.distinguishable_colors(100); % colormap 
    elseif option == 1
        % jammed vs non-jammed plt
        C = [1 0 0; 0.4660 0.6740 0.1880]; % colormap
        nic_plt = zeros(size(nic));
        % all NIC < 6 are red, all NIC >=6 are green
        nic_plt(nic >= 6) = 1;
    else
        error("Usage: " + ...
            "plot_2D_TimeNums(time, nic, icao, option). " + ...
            "Valid option: 0 (plot original nic value), " + ...
            "1 (plot in terms of jammed[NIC<7], non-jammed[NIC>=7])")
    end

   
    % observed unique NIC values
    seenNic = unique(nic_plt); 

    % divide points into sub-time windows 
    time_range = linspace(min(time), max(time), 11);
    num_pts = zeros(length(time_range)-1, length(seenNic));
    for i = 1:length(time_range)-1
        % find points within current time window
        pt_ind = (time > time_range(i) & time < time_range(i+1));
        local_pts = nic_plt(pt_ind);
        local_num_pts = zeros(length(seenNic),1);
        for j = 1:length(seenNic)
            local_num_pts(j) = sum(local_pts == seenNic(j));
        end
        num_pts(i,:) = local_num_pts;
    end
    
    time_plt = mean([time_range(2:end)' time_range(1:end-1)'], 2);
    b = bar(time_plt, num_pts,'stacked', 'HandleVisibility','off');
    grid on; hold on;
    % add legend information
    if option == 0 
        for k = 1:1:length(seenNic)
            bar(nan, 'FaceColor', C(seenNic(k)+1,:), 'DisplayName', ...
                "NIC = " + string(seenNic(k)) + " with " + ...
                string(sum(nic_plt == seenNic(k))) + " points");
            b(k).FaceColor = C(seenNic(k)+1,:);
        end
    else
        for k = 1:1:length(seenNic)
            if seenNic(k) == 1
                bar(nan, 'FaceColor', C(seenNic(k)+1,:), 'DisplayName', ...
                    "Nominal points: " + string(sum(nic_plt == seenNic(k))));
            else
                bar(nan, 'FaceColor', C(seenNic(k)+1,:), 'DisplayName', ...
                    "Jammed points: " + string(sum(nic_plt == seenNic(k))));
            end
            b(k).FaceColor = C(seenNic(k)+1,:);
        end
    end
    


    xlabel('Time [UTC]')
    ylabel('Numbers of points')
    startT = min(time);
    startT.Format = 'yyyy-MM-dd HH:mm:ss';
    endT = max(time);
    endT.Format = 'yyyy-MM-dd HH:mm:ss';
    title("Numbers of points from "+ string(startT) + " to " + string(endT))
    legend show;

end