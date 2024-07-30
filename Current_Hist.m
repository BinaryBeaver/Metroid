function [vinterval, vmid, hstw_tot] = Current_Hist(input_folder, output_folder, I1C, ledger, records_list, segs, opts) 
% Calculates current value distribution, i.e. makes current histogram
% Data collected and averaged across all the samples in the input folder
% I1C - is the 1C current for the considered battery
% ledger, records_list and segs - are outputs of the Find_Driving_Segments_Multi()
% opts.vinterval_norm - intervals of the histogram normed by 1C-current (Nx1 vector)
% The interval is mirrored to the negative values, i.e [0.0; 0.2; 0.5] transforms to [-0.5; -0.2; 0.0; 0.2; 0.5]
% The histogram magnitude values are calculted based on the row current values weighted by sampling time dt between the time-points
% The data 
%
% Outputs:
% vinterval - absolute histogram intervals
% vmid - mid-points of the histogram intervals
% hstw_tot - magnitudes for the weighted histogram
% Also data are saved to the output folder
%

    arguments
        input_folder (1,1) string
        output_folder (1,1) string
        I1C (1,1) double
        ledger
        records_list
        segs
        opts.save_data = true
        opts.save_png = true
        opts.save_fig = false
        opts.vinterval_norm = [0; 0.15; 0.30; 0.60; 0.90; 1.20; 1.50];
    end


    vinterval = opts.vinterval_norm*I1C;
    % vinterval = [0:1:500]'
    vinterval = [-flip(vinterval(2:end)); vinterval];
    
    vmid = (vinterval(1:end-1)+vinterval(2:end))/2;
    nbins = numel(vinterval)-1;
    hstw_tot = zeros(nbins,1);
    hst_tot = zeros(nbins,1);
    
    Ndays = size(ledger,1);
    N_no_drive_days = 0;
    
    drive_charge_delta = table('Size',[0,5],'VariableTypes',["uint32","datetime","uint32","double","double"],'VariableNames',["busID","date","drive_seg_id","Qchrg","Qdch"]);
    
    for iday = 1:Ndays
        fname = records_list(ledger.recID_Itot(iday));
        load(fullfile(input_folder,fname),"CSV");
        DATI = CSV; clear CSV;
        Nds = size(segs(iday).DRIVE_SEGMENTS,1);
        hstw_day = zeros(nbins,1);
        hst_day = zeros(nbins,1);
        if (Nds > 1)||((Nds == 1)&&(size(segs(iday).DRIVE_SEGMENTS,2) == 2))
            for idrvseg = 1:Nds
                ds = segs(iday).DRIVE_SEGMENTS(idrvseg,:);
                [hstw, hst, deltaQ] =  hist_current(DATI, ds, vinterval);
                hstw_day = hstw_day + hstw;
                hst_day = hst_day + hst;
    
                drive_charge_delta.busID(end+1) = ledger.busID(iday);
                drive_charge_delta.date(end) = ledger.date(iday);
                drive_charge_delta.drive_seg_id(end) = idrvseg;
                drive_charge_delta.Qdch(end) = deltaQ(1);
                drive_charge_delta.Qchrg(end) = deltaQ(2);
            end
        else
            N_no_drive_days = N_no_drive_days+1; 
        end
        hstw_day = hstw_day/Nds;
        hst_day = hst_day/Nds;
        hstw_tot = hstw_tot + hstw_day;
        hst_tot = hst_tot + hst_day;
    
    end
    hstw_tot = hstw_tot/(Ndays - N_no_drive_days);
    hst_tot = hst_tot/(Ndays - N_no_drive_days);

    recup_fraction = mean(drive_charge_delta.Qchrg(:)./drive_charge_delta.Qdch(:));
    Qdch_hist = sum(hstw_tot(nbins/2+1:end).*vmid(nbins/2+1:end));
    Qchrg_hist = -sum(hstw_tot(1:nbins/2).*vmid(1:nbins/2));
    recup_fraction_hist = Qchrg_hist/Qdch_hist;
    disp(sprintf("Recuperation fraction according to the original data = %0.3f",recup_fraction));
    disp(sprintf("Recuperation fraction according to the histogram = %0.3f",recup_fraction_hist))

    if opts.save_data || opts.save_png
        if ~exist(output_folder, 'dir')
            mkdir(output_folder)
        end
    end

    if opts.save_data
        save(fullfile(output_folder,"current_hist.mat"),"hstw_tot","hst_tot","vinterval","vmid","I1C","recup_fraction","recup_fraction_hist","drive_charge_delta")
    end  

    fig1 = figure(1);
    stem(vmid,hstw_tot*100)
    xlabel("Ток, A")
    ylabel("Доля времени, %")
    if opts.save_png
        saveas(fig1,fullfile(output_folder,"I_hist.png"))
    end  
    

    
    function [hstw, hst, deltaQ] =  hist_current(DATI, ds, vinterval) 
    
        % TODO: weight not only by dt, but also bu current value
        % i.e. make the histogram charge-conserving
    
        % +/- 0.5 due to min_grid centered around integer minute values. e.g. 8 is for 7:30 - 8:30 
        seg_start = DATI.t(1) + minutes(ds(1)-0.5);
        seg_end = DATI.t(1) + minutes(ds(2)+0.5);
        [~, idx_start] = min(abs(DATI.t-seg_start));
        [~, idx_end] = min(abs(DATI.t-seg_end));
        DATI = DATI(idx_start:idx_end,:);
        dt = seconds(diff(DATI.t));
        I = (DATI.val(1:end-1)+DATI.val(2:end))/2;
        
        [hstw, hst] = histw_edges(I, dt, vinterval);
        hstw = hstw/sum(dt);
        hst = hst/numel(dt);
    
        % calc discharge / charge amounts (Ah)
        idx_disch = find(I > 0);
        Qdisch = sum(dt(idx_disch).*I(idx_disch));
        idx_chrg = find(I < 0);
        Qchrg = -sum(dt(idx_chrg).*I(idx_chrg));
        deltaQ = [Qdisch Qchrg]/3600;
    
    end


    function [hstw, hst] = histw_edges(vv, ww, vinterval)  
    
        nbins = numel(vinterval)-1;
        % vmid = (vinterval(1:end-1)+vinterval(2:end))/2;
        hstw = zeros(nbins, 1);
        hst = zeros(nbins, 1);
        for i = 1:nbins
            if i < nbins
                idxes = find(all([(vv >= vinterval(i)),(vv < vinterval(i+1))],2));
            elseif i == nbins
                idxes = find(all([(vv >= vinterval(i)),(vv <= vinterval(i+1))],2));
            end
            hst(i) = numel(idxes);
            hstw(i) = sum(ww(idxes));
        end
    end

% function [hstw, hst, vinterval] = histw_sym(vv, ww, ngrades)  
%     maxV  = max(abs(vv));
%     delta = maxV/ngrades;
%     nbins = ngrades*2;
% 
%     vinterval = linspace(0, maxV, ngrades+1)';
%     vinterval = [-flip(vinterval(2:end)); vinterval];
%     % vmid = (vinterval(1:end-1)+vinterval(2:end))/2;
%     hstw = zeros(nbins, 1);
%     hst = zeros(nbins, 1);
%     for i = 1:nbins
%         if i < nbins
%             idxes = find(all([(vv >= vinterval(i)),(vv < vinterval(i+1))],2));
%         elseif i == nbins
%             idxes = find(all([(vv >= vinterval(i)),(vv <= vinterval(i+1))],2));
%         end
%         hst(i) = numel(idxes);
%         hstw(i) = sum(ww(idxes));
%     end
% end

end