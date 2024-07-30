function [R_table, false_charge_step_ids] = Calc_Resist_Day(DATI, DATU, DATT, opts)
% Calculate battery resistance for a single day data (single sample)
% Searches for charge sessions and calc resistance baced on ubrupt current drop 
% (current drob hight should be no less than CHARGE_STEP_VAL)
% returns table 'R_table' including: time, resistance and temperature and, additionaly, current drop and voltage drop 
% One row for ech charge session
% input - tables (t,val) for current ('B2V_TotalI'), voltage ('B2V_HVB') and temperature
% If no large enougth current frop was found in a particular charge segmentS - than its id is addeded to the output 'alse_charge_step_ids'
%
% USES: 
% Find_Driving_Segments
% Get_Min_Grid_Vals

    arguments
        DATI
        DATU
        DATT
        opts.CHARGE_STEP_VAL = 200
    end

    [min_grid min_grid_POSval min_grid_NEGval] = Get_Min_Grid_Vals(DATI);

    [DRIVE_SEGMENTS, REST_SEGMENTS, CHARGE_SEGMENTS, states] = Find_Driving_Segments(min_grid, min_grid_POSval, min_grid_NEGval);
    plot(min_grid, states*100, min_grid, min_grid_POSval, min_grid, min_grid_NEGval)
    
    CHARGE_STEP_VAL = opts.CHARGE_STEP_VAL;
    Nchrg = size(CHARGE_SEGMENTS,1);
    % R_table = table;
    % R_table.t = datetime.empty(Nchrg,0);
    % R_table.R0 = double.empty(Nchrg,0);
    % R_table.T = double.empty(Nchrg,0);
    R_table = table('Size',[0, 5],'VariableTypes',["datetime","double","double","double","double"],'VariableNames',["t","R0","T","dI","dU"]);
    false_charge_step_ids = []; 
    if isnan(CHARGE_SEGMENTS)
       return 
    end
    for ich = 1:Nchrg

        charge_vals = min_grid_NEGval(CHARGE_SEGMENTS(ich,1):CHARGE_SEGMENTS(ich,2));
        
        dch = charge_vals(3:1:end) - charge_vals(1:1:end-2);
        [val_max, i_max] = max(dch);
        if val_max >= CHARGE_STEP_VAL
            ch_step_minpoints = [i_max, i_max+2] + CHARGE_SEGMENTS(ich,1)-1;
        else
            warning("No charge step detected")
            false_charge_step_ids = [false_charge_step_ids, ich];
            continue
        end
        
        step_tau_dur = seconds(1);
        step_tau_len = 10;
        
        [~, ita] = min(abs(DATI.t - min_grid(ch_step_minpoints(1))));
        [~, itb] = min(abs(DATI.t - min_grid(ch_step_minpoints(2))));
        tfine = [DATI.t(ita):seconds(0.1):DATI.t(itb)]';
        Ifine = interp1(DATI.t(ita:itb),DATI.val(ita:itb),tfine,'linear');
        dIfine = Ifine(step_tau_len+1:1:end) - Ifine(1:1:end-step_tau_len);
        [dIfine_max, ifine_max] = max(dIfine);
        
        [~, itUa] = min(abs(DATU.t-tfine(ifine_max)));
        [~, itUb] = min(abs(DATU.t-(tfine(ifine_max)+step_tau_dur)));
        dU = DATU.val(itUb) - DATU.val(itUa);
        [~, itTa] = min(abs(DATT.t-tfine(ifine_max)));

        R_table.t(end+1) = tfine(ifine_max);
        R_table.R0(end) = -dU/dIfine_max;
        R_table.T(end) = DATT.val(itTa);
        R_table.dI(end) = dIfine_max;
        R_table.dU(end) = dU;
    end

end
