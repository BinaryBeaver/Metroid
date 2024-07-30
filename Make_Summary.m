function [SUM, corrupted_samples] = Make_Summary(input_folder, batch_name, output_filename,opts)
% Chekcs records (mat-files) in the input folder and creates a summary table (SUM).
% The summary contains:
% number of data points in records associated with different parameters(e.g. I_tot, V_tot);
% time shifts bitwen the start-points and end-points;
% data gap durations and other...
% The table is written to xlsx-file "output_filename" to sheet named "batch_name" 
% (You can run the function several times outputting into the same xlsx to different sheets by changing the "batch_name") 
% The incomplete sets of data (e.g. no temperature data) are considered as corrupted samples. The sample-numbers are ouputed in "corrupted_samples" 
%
% Optional input:
% n_serial - number of serial cell in the battery. Needed to conver total voltage to cell-average voltage
% daysample_name_pattern - (string) pattern for file-name recognition
%
% USES:
% Get_Recors_Ledger
% 
% TODO: add optional argument "daysample_name_pattern" to the f-call
% "Get_Recors_Ledger"
    arguments
        input_folder (1,1) string
        batch_name (1,1) string
        output_filename (1,1) string
        opts.daysample_name_pattern (1,1) string = "*__*__*.mat"
        opts.n_serial = 48*2+72;
    end

    % number of serial cells
    n_serial = opts.n_serial;
     
    [ledger, records_list, Ndaysets] = Get_Recors_Ledger(input_folder);
    
    %% calculate summary data
    SUM = ledger;
    SUM(:,3:8) = [];
    Nrec = size(ledger,1);
    corrupted_samples = [];
    for r = 1:Nrec
        %% read data and sizes
        smp_sizes = zeros(6,1);
        % Itot
        if ledger{r,2+1} == 0
            warning("TotalI data is missng: busID %g ; %s",ledger{r,1},ledger{r,2})
            corrupted_samples = [corrupted_samples, r];
            continue
        end
        load(fullfile(input_folder, records_list{ledger{r,2+1}}),'CSV')
        smp_sizes(1) = size(CSV,1);
        Itot = CSV;
        SUM.Itot_size(r) = smp_sizes(1);
        
        % Vtot
        if ledger{r,2+2} ~= 0
            load(fullfile(input_folder, records_list{ledger{r,2+2}}),'CSV')
            smp_sizes(2) = size(CSV,1);
            Vtot = CSV;
            SUM.Vtot_size(r) = smp_sizes(2);
        else
            SUM.Vtot_size(r) = NaN;
        end
        % Vmin
        if ledger{r,2+3} ~= 0
            load(fullfile(input_folder, records_list{ledger{r,2+3}}),'CSV')
            smp_sizes(3) = size(CSV,1);
            Vmin = CSV;
            SUM.Vmin_size(r) = smp_sizes(3);
        else
            SUM.Vmin_size(r) = NaN;
        end
        % Vmax
        if ledger{r,2+4} ~= 0
            load(fullfile(input_folder, records_list{ledger{r,2+4}}),'CSV')
            smp_sizes(4) = size(CSV,1);
            Vmax = CSV;
            SUM.Vmax_size(r) = smp_sizes(4);
        else
            SUM.Vmax_size(r) = NaN;
        end
        % Tmin
        if ledger{r,2+5} ~= 0
            load(fullfile(input_folder, records_list{ledger{r,2+5}}),'CSV')
            smp_sizes(5) = size(CSV,1);
            Tmin = CSV;
            SUM.Tmin_size(r) = smp_sizes(5);
        else
            SUM.Tmin_size(r) = NaN;
        end
    
        % Tmax
        if ledger{r,2+6} ~= 0
            load(fullfile(input_folder, records_list{ledger{r,2+6}}),'CSV')
            smp_sizes(6) = size(CSV,1);
            Tmax = CSV;
            SUM.Tmax_size(r) = smp_sizes(6);
        else
            SUM.Tmax_size = NaN;
        end
        clear CSV;
        
        %% analize currents
        Itot.pos = Itot.val;
        Itot.neg = Itot.val;
        Itot.pos(Itot.val<0) = 0;
        Itot.neg(Itot.val>0) = 0;
        SUM.Qpos(r) = seconds(trapz(Itot.t,Itot.pos))/3600;
        SUM.Qneg(r) = seconds(trapz(Itot.t,Itot.neg))/3600;
    
        %% analize voltages
        if (ledger{r,2+2} ~= 0) && (ledger{r,2+3} ~= 0) && (ledger{r,2+4} ~= 0) 
            Vcell_tot_ave = mean(Vtot.val/n_serial);
            Vcell_min_ave = mean(Vmin.val);
            Vcell_max_ave = mean(Vmax.val);
        
            SUM.Vcell_tot_ave(r) = Vcell_tot_ave;
            SUM.Vcell_min_ave(r) = Vcell_min_ave;
            SUM.Vcell_max_ave(r) = Vcell_max_ave;
            SUM.Vcell_delta_max(r) = max(Vmax.val - Vmin.val)*1000; 
            SUM.Vcell_delta_min(r) = min(Vmax.val - Vmin.val)*1000; 
            SUM.Vtot_relative_min_max(r) = (Vcell_tot_ave - Vcell_min_ave)/(Vcell_max_ave - Vcell_min_ave);
        end
        
        %% calculate start time and finish time shifts
        SUM.t_start(r) = Itot.t(1); 
        SUM.t_finish(r) = Itot.t(end);   
        if ~isnan(SUM.Vtot_size(r))
            SUM.Vtot_start_shift(r) = seconds(Vtot.t(1)-Itot.t(1));
            SUM.Vtot_finish_shift(r) = seconds(Vtot.t(end)-Itot.t(end));
        end
        if ~isnan(SUM.Vmin_size(r))
            SUM.Vmin_start_shift(r) = seconds(Vmin.t(1)-Itot.t(1));
            SUM.Vmin_finish_shift(r) = seconds(Vmin.t(end)-Itot.t(end));
        end
        if ~isnan(SUM.Vmax_size(r))
            SUM.Vmax_start_shift(r) = seconds(Vmax.t(1)-Itot.t(1));
            SUM.Vmax_finish_shift(r) = seconds(Vmax.t(end)-Itot.t(end));
        end
        if ~isnan(SUM.Tmin_size(r))
            SUM.Tmin_start_shift(r) = seconds(Tmin.t(1)-Itot.t(1));
            SUM.Tmin_finish_shift(r) = seconds(Tmin.t(end)-Itot.t(end));
        end
        if ~isnan(SUM.Tmax_size(r))
            SUM.Tmax_start_shift(r) = seconds(Tmax.t(1)-Itot.t(1));
            SUM.Tmax_finish_shift(r) = seconds(Tmax.t(end)-Itot.t(end));
        end
    
        %% find data gaps
        SUM.data_gap(r) = max(Itot.t(2:end) - Itot.t(1:end-1));
        if seconds(SUM.data_gap(r)) < 1.0
            % such small gap is not a gap
            SUM.data_gap(r) = seconds(0.0);
        end
    
        % %% calculate time points mismatch if possible
        % if ~isnan(SUM.Vtot_size(r)) && (SUM.Itot_size(r) == SUM.Vtot_size(r))
        %     SUM.tp_mismatch_Itot_Vtot(r) = max(abs(seconds(Itot.t(:)-Vtot.t(:))));
        % else
        %     SUM.tp_mismatch_Itot_Vtot(r) = NaN;
        % end
        % 
        % if ~isnan(SUM.Vtot_size(r)) && ~isnan(SUM.Vmin_size(r)) && (SUM.Vtot_size(r) == SUM.Vmin_size(r))
        %     SUM.tp_mismatch_Vtot_Vmin(r) = max(abs(seconds(Vtot.t(:)-Vmin.t(:))));
        % else
        %     SUM.tp_mismatch_Vtot_Vmin(r) = NaN;
        % end
        % 
        % if ~isnan(SUM.Vmin_size(r)) && ~isnan(SUM.Vmax_size(r)) && (SUM.Vmin_size(r) == SUM.Vmax_size(r))
        %     SUM.tp_mismatch_Vmin_Vmax(r) = max(abs(seconds(Vmin.t(:)-Vmax.t(:))));
        % else
        %     SUM.tp_mismatch_Vmin_Vmax(r) = NaN;
        % end
        % 
        % if ~isnan(SUM.Vmin_size(r)) && ~isnan(SUM.Tmin_size(r)) && (SUM.Vmin_size(r) == SUM.Tmin_size(r))
        %     SUM.tp_mismatch_Vmin_Tmin(r) = max(abs(seconds(Vmin.t(:)-Tmin.t(:))));
        % else
        %     SUM.tp_mismatch_Vmin_Tmin(r) = NaN;
        % end
        % 
        % if ~isnan(SUM.Tmin_size(r)) && ~isnan(SUM.Tmax_size(r)) && (SUM.Tmin_size(r) == SUM.Tmax_size(r))
        %     SUM.tp_mismatch_Tmin_Tmax(r) = max(abs(seconds(Tmin.t(:)-Tmax.t(:))));
        % else
        %     SUM.tp_mismatch_Tmin_Tmax(r) = NaN;
        % end
    
    end
    writetable(SUM,output_filename ,'Sheet',batch_name);
end

