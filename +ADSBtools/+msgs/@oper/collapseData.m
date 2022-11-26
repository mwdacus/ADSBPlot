function collapseData(obj) 
    % collapseData 
    % 
    % DESCRIPTION:
    %   function to combine same message received by different ground
    %   receivers into one message with respect to a union clock 
    %   
    %
    % INPUT:
    %   obj         - struct of ADS-B data (class: oper)
    %
    %                   
    %                   
    % OUTPUT:
    %   update obj with only unique messages on a unified timeline. add an
    %   extra information to the obj with numbers of receivers been seeing
    %   the same message. 
    %




    %% load message and time
    allRawMsg = obj.rawmsg; allTime = datetime(strip(obj.mintime,'both','"') ...
        ,'Format', 'yyyy-MM-dd  HH:mm:ss.SSSSSS');
    
    
    
    %% perform rough estimation of timeline and save unique messages
    % sort data for each flight    
    [uniqueTime, Ind, n1] = unique(allTime, 'stable');

    %Filter out same message different receivers but very closed time (<1s) 
    for i = 2:1:length(Ind)
        localInd = Ind(i);
        %check if messages are different for time changing point
        %if messages are the same, check if time difference > 1s
        if allRawMsg(localInd) == allRawMsg(localInd - 1) &&...
                abs(allTime(localInd)-allTime(localInd-1)) < seconds(1)
            if i == length(Ind)
                nextLocalRange = [localInd:length(allTime)];
            else
                nextLocalRange = [localInd:Ind(i+1)-1];
            end
            
            %merge small time difference into one time and remove the mark
            %of time jump
            allTime(nextLocalRange) = allTime(localInd-1);
        end 
    end
    
    
    % find unique raw messages (in this case would be unique time)
    [newUniqueTime, newInd] = unique(allTime, 'stable');
    
     % find # of appearances of each unique message (= # of recievers)
    [numbersOfAppearance,correspondTime] = groupcounts(allTime, 'none');  
    
    % # of receivers
    numReceiver = nan*zeros(length(newUniqueTime), 1);
    [sortedUniqueTime, sortedInd] = sort(newUniqueTime);
    numReceiver(sortedInd) = numbersOfAppearance;

 


    %% update input data with new index and add numReceiver information
    fn = properties(obj);
    for i = 1:1:length(fn) 
        if ~isempty(obj.(fn{i})) 
            obj.(fn{i}) = obj.(fn{i})(newInd);
        end
    end
    obj.numReceiver = numReceiver;






end
