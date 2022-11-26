function resultAlt = checkInAnnex10(inputAlt, sortedTable)
    % DESCRIPTION:
    %   function decodes baroaltitude with 100ft increment. 
    %   
    % INPUT:
    %   inputAlt     - binary code of altitude from ADS-B airborne position
    %   message 
    %   sortedTable  - the table for 100ft altitude increment in Annex 10
    %  
    %             
    % OUTPUT:
    %   resultAlt    - decoded baroaltitude[m]



    numInputAlt = [];
    for k=1:numel(inputAlt)
        % remove the Q bit [alt(8)]
        if k~=8
            numInputAlt = [numInputAlt str2num(inputAlt(k))];
        end
    end
    
    resultAlt = nan;
    possibleInd = find(sum(numInputAlt) == sortedTable.SUM); % pick a rough range for possible location
    
    for i = possibleInd(1): possibleInd(end)
        % match ALT bit with pulse chart's column (see definition in MOPs)
        if isequal(numInputAlt, sortedTable{i,{'C1','A1','C2','A2','C4','A4','B1','B2','D2','B4','D4'}})
            resultAlt = sortedTable.ALT(i)* 0.3048; %ft to m
            break
        end
    end
    
    
end