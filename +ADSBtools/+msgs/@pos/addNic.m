function addNic(obj)
    % DESCRIPTION:
    %   parse nic value from ADS-B airborne position message based on type
    %   code(tc) and nic_sb. Method follows rules from MOPs DO-260.
    %   
    % INPUT:
    %  
    %             
    % OUTPUT:
    %   obj will have decoded value for nic: integrity level indicator. nic
    %   is integer ranges from 0 to 11.

    nic_vec = string(nan*zeros(1, length(obj.tc)))';
    probInd = zeros(length(obj.tc),1);  % save index information for nan message


    for i = 1:1:length(obj.tc)
        % load useful information 
        nicsb = obj.nicsb(i); 
        tc = obj.tc(i); 
 
        if isstring(nicsb)
            nicsb = str2double(nicsb);
            tc = str2double(tc);
        end
        
        switch tc
            case 0
                nic = char('0');
            case 20
                nic = char('11');
            case 21
                nic = char('10');
            case 22
                nic = char('0.1');
        
            otherwise
                switch nicsb
                    case 0
                        switch tc
                            case 9
                                nic = char('11'); 
                            case 10
                                nic = char('10');
                            case 11
                                nic = char('8');
                            case 12
                                nic = char('7');
                            case 13
                                nic = char('6');
                            case 14
                                nic = char('5');
                            case 15
                                nic = char('4');
                            case 16
                                nic = char('2');
                            case 17
                                nic = char('1');
                            case 18
                                nic = char('0');
                            otherwise 
                                nic = char("-" + string(nicsb));
                                probInd(i) = 1;
                        end
                
                    case 1
                        switch tc
                            case 11
                                nic = char('9');
                            case 13
                                nic = char('6');
                            case 16
                                nic = char('3');
                            otherwise
                                nic = char("-" + string(nicsb));
                                probInd(i) = 1;
                        end
        
                    otherwise
                        nic = char("-" + string(tc));
                        probInd(i) = 1; 
                end
        end


        nic_vec(i) = nic;
    end 

    % save decoded nic value
    obj.nic = nic_vec;

    % remove nan messages
    fn = properties(obj);
    for i = 1:1:length(fn)
        if ~isempty(obj.(fn{i})) 
            obj.(fn{i})(probInd == 1) = [];
        end
    end

end