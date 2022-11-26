%Determine Flight Profile from data
function [profile_ident]=FlightProfile(tail_data)
    delta_heading=abs(tail_data.heading(2)-tail_data.heading(1));
    delta_alt=abs(tail_data.alt(2)-tail_data.alt(1));
    %Straight-and-level
    if delta_heading<=10 && delta_alt<=100/3.28084
        profile_ident='Straight and Level';
    %Climb or Descent
    elseif delta_heading<=10 && delta_alt>100/3.28084
        profile_ident='Climb or Descent';
    %Combination
    else
        profile_ident='Multiple Maneuvers';
    end
end