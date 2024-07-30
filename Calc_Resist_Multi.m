function [R_table, false_charge_steps] = Calc_Resist_Multi(input_folder, opts)
% Performs internal resistance calculation (using Calc_Resist_Day()) for every smple in the folder
% output is -  cocatenated outputs of the Calc_Resist_Day()
% by default sves results to the "R_table.mat" in the input_folder (or in opts.otput_folder)
%
% USES:
% Calc_Resist_Day()


    arguments
        input_folder (1,1) string
        opts.CHARGE_STEP_VAL = 200
        opts.output_folder = input_folder
        opts.save_data = true 
    end

    [ledger, records_list, Ndaysets] = Get_Recors_Ledger(input_folder);
    
    R_table = table('Size',[0, 5],'VariableTypes',["datetime","double","double","double","double"],'VariableNames',["t","R0","T","dI","dU"]);
    false_charge_steps = {};
    for i = 1:Ndaysets
        % load current and voltage data
        infile = fullfile(input_folder, records_list(ledger.recID_Itot(i)));
        load(infile, 'CSV');
        DATI = CSV;
        infile = fullfile(input_folder, records_list(ledger.recID_Vtot(i)));
        load(infile, 'CSV');
        DATU = CSV;
        % load temperature data and calc mean values
        infile = fullfile(input_folder, records_list(ledger.recID_Tmin(i)));
        load(infile, 'CSV');
        DATminT = CSV;
        infile = fullfile(input_folder, records_list(ledger.recID_Tmax(i)));
        load(infile, 'CSV');
        DATmaxT = CSV;
        DATT = DATminT;
        DATT.val = (DATminT.val + DATmaxT.val)/2;
        clear DATminT
        clear DATmaxT
        clear CSV
    
        [R_table_day, false_charge_step_ids] = Calc_Resist_Day(DATI, DATU, DATT);
        R_table = [R_table; R_table_day];
        if false_charge_step_ids
            false_charge_steps = [false_charge_steps; {i,false_charge_step_ids}];
        end
        
        fprintf('Day sets processed: %3d\n',i);
    end

    if opts.save_data
        if ~exist(opts.output_folder, 'dir')
            mkdir(opts.output_folder)
        end
        save(fullfile(opts.output_folder,"R_table.mat"), "R_table","false_charge_steps")
    end

end
