%% Combine all csv files from one day together
function combineFile(airport, dirADSB)
    % check inputdata is data or rawdata
    char_dirADSB = char(dirADSB); airport = char(airport);
    dashIndices = find(char_dirADSB == '\');
    dataType = char_dirADSB(dashIndices(end-2):dashIndices(end-1));

    % check unique year/month/day information 
    checkFiles = dir(dirADSB + '*.csv');
    allCheckFiles = {checkFiles.name};
    dateInfo = [];
    for i = 1:1:length(allCheckFiles)
        dateInfo = [dateInfo string(allCheckFiles{i}(length(airport)+1 : length(airport)+10))];
    end
    dateInfo = unique(dateInfo);


    % specify importing options
    for option = ["-Pos", "-Vel", "-Oper", "-Combined"]   
        for i = 1:1:length(dateInfo)
            date = char(dateInfo(i));
            files = dir(dirADSB + '*' + date + '*' + option + '*.csv');
            allFiles = {files.name};
            % move to next file if current file does not exist
            if isempty(allFiles)
                continue
            end
            allCsv = [];

            for j = 1:length(allFiles)
                currName = allFiles{j};
                if string(dataType) == "\Data\"
                    if option == "-Pos"
                        type = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s';
                    elseif option == "-Oper"
                        type = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s';
                    elseif option == "-Vel"
                        type = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s';
                    else 
                        continue
                    end
                else
                    if option == "-Pos"
                        type = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s'; %20
                    elseif option == "-Oper"
                        type = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s'; %15
                    elseif option == "-Vel"
                        type = '%s%s%s%s%s%s%s%d%d%d%d%s%s%s%s%s%s%s'; %18
                    else
                        type = '%s%s%s%s%s%s%s%s%s%s%s'; %11
                    end
                end


                csv = readtable(dirADSB + allFiles{j},...
                    'Delimiter', ',', 'Format', type, 'HeaderLines', 0, 'ReadVariableNames', true);


                allCsv = [allCsv; csv]; % Concatenate vertically
            end

            % move to next date if current type of data (option) does not exist
            % option = ["-Pos", "-Vel", "-Oper", "-Combined"]
            if isempty(allCsv)
                continue
            end

            delete(dirADSB + "*" + date + '*' + option + '*.csv');

            if string(dataType) == "\Data\"
                writetable(allCsv, dirADSB + airport(1:end-1) + " " + date + option + '.csv');
            else
                writetable(allCsv, dirADSB + airport(1:end-1) + " " + date + option + '-Raw-Message.csv');
            end

        end

    end


end


