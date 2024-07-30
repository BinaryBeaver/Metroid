function [DRIVE_SEGMENTS, REST_SEGMENTS, CHARGE_SEGMENTS, states] = Find_Driving_Segments(min_grid, min_grid_POSval, min_grid_NEGval)
% Perform segmentation of the day sample into states: 
%  'REST' (state  = 1) ; 'DRIVE' (state = 3) ; 'CHARGE' (state = 4) ; undefined (state = -1) 
% Segmentation performed based on the current values.
% The input is minute-grid current values - same as ouput of Get_Min_Grid_Vals()   
% Otput (DRIVE_SEGMENTS, REST_SEGMENTS, CHARGE_SEGMENTS) are 2-column arrays containing segmentation info
% 1st column contains index of the segment start according to themin_grid; 2-nd column - end-index of the segment
% The hight of the columns corresponds to the number of the segments found. 
% The 'states' output contains the state values (-1, 1, 3, 4) - one value per minute according to the min_grid
%

    % parameters:
    MAX_GAP_DRIVE = 12;
    MIN_REST_DUR = 60; % minutes
    MIN_IDLE_DUR = 5; % minutes
    MIN_DRIVE_DUR = 30; % minutes
    MIN_CHARGE_DUR = 5; % minutes

    Nmin = numel(min_grid);
    states = zeros(Nmin, 1,'int16');
    for m = 1:Nmin
        if (min_grid_POSval(m) > 15) && (min_grid_NEGval(m) <-1.0)
            states(m) = 3; % DRIVE
        elseif (min_grid_POSval(m) > 5) && (min_grid_POSval(m) < 20) && (min_grid_NEGval(m) > -1.0)
            states(m) = 2; % IDLE   
        elseif (min_grid_POSval(m) < 1.0) && (min_grid_NEGval(m) > -0.1)
            states(m) = 1; % REST
        elseif (min_grid_POSval(m) < 0.1) && (min_grid_NEGval(m) < -100.0)
            states(m) = 4; % CHARGE
        else
            states(m) = -1;
        end
    end
    
    % numerate minutes starting from 1
    imin = minutes(min_grid - min_grid(1))+1;
    
    % let IDLE be DRIVE
    states_ed = states;
    % states_ed(states == 2) = 3;
    % TODO; convert only IDLE adjustant to DRIVE 
    
    % DRIVE forward
    [sq_val, sq_len, sq_str] = split_seqs(states_ed);
    drive_seq = find(any([(sq_val == 3),(sq_val == 2)],2));
    n_drive_seq = numel(drive_seq);
    sq_width_bonus = 0;
    for i = 1:n_drive_seq-1
        if (sq_val(drive_seq(i))==3) && (sq_len(drive_seq(i)) + sq_width_bonus > MAX_GAP_DRIVE)
            if sum(sq_len(drive_seq(i)+1 : drive_seq(i+1)-1)) < MAX_GAP_DRIVE
                sq_val(drive_seq(i)+1 : drive_seq(i+1)-1) = 3;
                sq_width_bonus = sq_width_bonus + sum(sq_len(drive_seq(i) : drive_seq(i+1)-1));
                if sq_val(drive_seq(i+1))==2
                    sq_val(drive_seq(i+1))=3;
                end
            else
                sq_width_bonus = 0;
            end
        end
        
    end
    states_ed_forward = int16(assemble_seqs(sq_val, sq_len));
    
    % DRIVE backward
    [sq_val, sq_len, sq_str] = split_seqs(flip(states_ed_forward));
    drive_seq = find(any([(sq_val == 3),(sq_val == 2)],2));
    n_drive_seq = numel(drive_seq);
    sq_width_bonus = 0;
    for i = 1:n_drive_seq-1
        if (sq_val(drive_seq(i))==3) && (sq_len(drive_seq(i)) + sq_width_bonus > MAX_GAP_DRIVE)
            if sum(sq_len(drive_seq(i)+1 : drive_seq(i+1)-1)) < MAX_GAP_DRIVE
                sq_val(drive_seq(i)+1 : drive_seq(i+1)-1) = 3;
                sq_width_bonus = sq_width_bonus + sum(sq_len(drive_seq(i) : drive_seq(i+1)-1));
                if sq_val(drive_seq(i+1))==2
                    sq_val(drive_seq(i+1))=3;
                end
            else
                sq_width_bonus = 0;
            end
        end
        
    end
    states_ed_backward = flip(int16(assemble_seqs(sq_val, sq_len)));
    [sq_val, sq_len, sq_str] = split_seqs(states_ed_backward);

    %% clear out soert segments
    for i = 1:numel(sq_val)
        if sq_val(i) == 1
            if sq_len(i) < MIN_REST_DUR
                sq_val(i) = -1;
            end
        elseif sq_val(i) == 2
            if sq_len(i) < MIN_IDLE_DUR
                sq_val(i) = -1;
            end
        elseif sq_val(i) == 3
            if sq_len(i) < MIN_DRIVE_DUR
                sq_val(i) = -1;
            end
        elseif sq_val(i) == 4
            if sq_len(i) < MIN_CHARGE_DUR
                sq_val(i) = -1;
            end
        end
    end
    states_cleared = int16(assemble_seqs(sq_val, sq_len));

    %% prepare segments for output
    
    [sq_val, sq_len, sq_str] = split_seqs(states_cleared);
    % find CHARGE
    mode_seq = find(sq_val == 4);
    if numel(mode_seq) > 0
        CHARGE_SEGMENTS = zeros(numel(mode_seq),2);
        for i = 1:numel(mode_seq)
            CHARGE_SEGMENTS(i,1) = sq_str(mode_seq(i));
            CHARGE_SEGMENTS(i,2) = sq_str(mode_seq(i)) + sq_len(mode_seq(i)) -1;
        end
    else
        CHARGE_SEGMENTS = NaN;
        warning('No CHARGE segments found!')
    end
    
    % find DRIVE
    mode_seq = find(sq_val == 3);
    if numel(mode_seq) > 0
        DRIVE_SEGMENTS = zeros(numel(mode_seq),2);
        for i = 1:numel(mode_seq)
            DRIVE_SEGMENTS(i,1) = sq_str(mode_seq(i));
            DRIVE_SEGMENTS(i,2) = sq_str(mode_seq(i)) + sq_len(mode_seq(i)) -1;
        end
    else
        DRIVE_SEGMENTS = NaN;
        warning('No DRIVE segments found!')
    end

    % % find IDLE
    % mode_seq = find(sq_val == 2);
    % if numel(mode_seq) > 0
    %     IDLE_SEGMENTS = zeros(numel(mode_seq),2);
    %     for i = 1:numel(mode_seq)
    %         IDLE_SEGMENTS(i,1) = sq_str(mode_seq(i));
    %         IDLE_SEGMENTS(i,2) = sq_str(mode_seq(i)) + sq_len(mode_seq(i)) -1;
    %     end
    % else
    %     IDLE_SEGMENTS = NaN;
    % end
    
    % find REST
    mode_seq = find(sq_val == 1);
    if numel(mode_seq) > 0
        REST_SEGMENTS = zeros(numel(mode_seq),2);
        for i = 1:numel(mode_seq)
            REST_SEGMENTS(i,1) = sq_str(mode_seq(i));
            REST_SEGMENTS(i,2) = sq_str(mode_seq(i)) + sq_len(mode_seq(i)) -1;
        end
    else
        REST_SEGMENTS = NaN;
        warning('No REST segments found!')
    end
    
    %% States need to be updated !!!!
    states = states_cleared;

end

% save(infile,'CSV','min_grid','min_grid_NEGval','min_grid_POSval')


function [out1, out2, out3] = split_seqs(x)
% Split vector into sequences of equal elements

% out1 - unique elements
% out2 - lenght of sequences
% out3 - indexes of sequence starts

    [s1, s2] = size(x);
    x = x(:);
    d = [true; diff(x) ~= 0];   % TRUE if values change
    b = x(d);                   % Elements without repetitions
    k = find([d; true]);       % Indices of changes
    n = diff(k);                % Number of repetitions
  
    if nargout == 3             % Reply indices of changes
        out3 = k(1:length(k) - 1);
    end

    if s2 > 1                      % Output gets same orientation as input
      b = b.';
      n = n.';
      out3 = out3.';
    end
    out1 = b;
    out2 = n;
end

function x = assemble_seqs(sq_val, sq_len)
    
    if numel(sq_val) ~= numel(sq_len)
        error('Input vectors must be the same length!')
        exit(1)
    end
    
    full_len = sum(sq_len);
    [s1, s2] = size(sq_val);
    x = zeros(full_len,1);
    
    idx = 1;
    for i = 1:numel(sq_val)
        x(idx:idx+sq_len(i)-1) = sq_val(i);
        idx = idx + sq_len(i);
    end
end
