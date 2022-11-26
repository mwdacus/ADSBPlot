function collapseData(obj) 
    % collapseData 
    % 
    % DESCRIPTION:
    %   function to combine same message received by different ground
    %   receivers into one message with respect to a union clock 
    %   
    %
    % INPUT:
    %   obj         - struct of ADS-B data (class: vel)
    %                   
    %
    %
    % OUTPUT:
    %   update obj with only unique messages on a unified timeline. add an
    %   extra information to the obj with numbers of receivers been seeing
    %   the same message. 
    %


    
    %% load message and time
    allRawMsg = obj.rawmsg;  allSerial = obj.serial; 



    %% perform rough estimation of timeline and save unique messages
    % number of the ground receiver 
    T = table(allRawMsg, allSerial);
    
    % find unique raw messages (works for vel and pos, not for oper)
    [uniqueMsg, Ind] = unique(allRawMsg, 'stable');
    % find # of appearances of each unique message for different ground 
    % receivers (= # of recievers)
    G = groupcounts(T,{'allRawMsg','allSerial'});
    [numbersOfAppearance, correspondMsg] = groupcounts(G.allRawMsg, 'none'); 
    
    % # of receivers
    numReceiver = nan*zeros(length(uniqueMsg), 1);
    [sortedUniqueMsg, sortedInd] = sort(uniqueMsg);
    numReceiver(sortedInd) = numbersOfAppearance;


    
 


    %% update input data with new index and add numReceiver information
    fn = properties(obj);
    for i = 1:1:length(fn) 
        if ~isempty(obj.(fn{i})) 
            obj.(fn{i}) = obj.(fn{i})(Ind);
        end
    end
    obj.numReceiver = numReceiver;





end
