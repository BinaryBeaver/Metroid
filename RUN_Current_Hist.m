input_folder = "d:\МЕТРО\999_mat";
output_folder = "d:\МЕТРО\999_mat\summary";
load(fullfile(input_folder,"summary\segmentation.mat"))

% vinterval = [-400:50:400]';
I1C = 324;
[vinterval, vmid, hstw_tot] = Current_Hist(input_folder, output_folder, I1C, ledger, records_list, segs); 




% vinterval = [0; 0.15; 0.30; 0.60; 0.90; 1.20; 1.50]*I1C;
% % vinterval = [0:1:500]'
% vinterval = [-flip(vinterval(2:end)); vinterval];
% 
% vmid = (vinterval(1:end-1)+vinterval(2:end))/2;
% nbins = numel(vinterval)-1;
% hstw_tot = zeros(nbins,1);
% hst_tot = zeros(nbins,1);
% 
% Ndays = size(ledger,1);
% N_no_drive_days = 0;
% 
% drive_charge_delta = table('Size',[0,5],'VariableTypes',["uint32","datetime","uint32","double","double"],'VariableNames',["busID","date","drive_seg_id","Qchrg","Qdch"]);
% 
% for iday = 1:Ndays
%     fname = records_list(ledger.recID_Itot(iday));
%     load(fullfile(input_folder,fname),"CSV");
%     DATI = CSV; clear CSV;
%     Nds = size(segs(iday).DRIVE_SEGMENTS,1);
%     hstw_day = zeros(nbins,1);
%     hst_day = zeros(nbins,1);
%     if (Nds > 1)||((Nds == 1)&&(size(segs(iday).DRIVE_SEGMENTS,2) == 2))
%         for idrvseg = 1:Nds
%             ds = segs(iday).DRIVE_SEGMENTS(idrvseg,:);
%             [hstw, hst, deltaQ] =  hist_current(DATI, ds, vinterval);
%             hstw_day = hstw_day + hstw;
%             hst_day = hst_day + hst;
% 
%             drive_charge_delta.busID(end+1) = ledger.busID(iday);
%             drive_charge_delta.date(end) = ledger.date(iday);
%             drive_charge_delta.drive_seg_id(end) = idrvseg;
%             drive_charge_delta.Qdch(end) = deltaQ(1);
%             drive_charge_delta.Qchrg(end) = deltaQ(2);
%         end
%     else
%         N_no_drive_days = N_no_drive_days+1; 
%     end
%     hstw_day = hstw_day/Nds;
%     hst_day = hst_day/Nds;
%     hstw_tot = hstw_tot + hstw_day;
%     hst_tot = hst_tot + hst_day;
% 
% end
% hstw_tot = hstw_tot/(Ndays - N_no_drive_days);
% hst_tot = hst_tot/(Ndays - N_no_drive_days);
% 
% fig1 = figure(1);
% stem(vmid,hstw_tot*100)
% xlabel("Ток, A")
% ylabel("Доля времени, %")
% saveas(fig1,fullfile(output_folder,"I_hist.png"))
% 
% save(fullfile(output_folder,"current_hist.mat"),"hstw_tot","hst_tot","vinterval","vmid","I1C")
% 
% 
% 
% 
% recup_fraction = mean(drive_charge_delta.Qchrg(:)./drive_charge_delta.Qdch(:))
% Qdch_hist = sum(hstw_tot(nbins/2+1:end).*vmid(nbins/2+1:end));
% Qchrg_hist = -sum(hstw_tot(1:nbins/2).*vmid(1:nbins/2));
% Qchrg_hist/Qdch_hist
% 
% 
% 
% 
% 
% 
% function [hstw, hst, deltaQ] =  hist_current(DATI, ds, vinterval) 
% 
%     % TODO: weight not only by dt, but also bu current value
%     % i.e. make the histogram charge-conserving
% 
%     % +/- 0.5 due to min_grid centered around integer minute values. e.g. 8 is for 7:30 - 8:30 
%     seg_start = DATI.t(1) + minutes(ds(1)-0.5);
%     seg_end = DATI.t(1) + minutes(ds(2)+0.5);
%     [~, idx_start] = min(abs(DATI.t-seg_start));
%     [~, idx_end] = min(abs(DATI.t-seg_end));
%     DATI = DATI(idx_start:idx_end,:);
%     dt = seconds(diff(DATI.t));
%     I = (DATI.val(1:end-1)+DATI.val(2:end))/2;
% 
%     [hstw, hst] = histw_edges(I, dt, vinterval);
%     hstw = hstw/sum(dt);
%     hst = hst/numel(dt);
% 
%     % calc discharge / charge amounts (Ah)
%     idx_disch = find(I > 0);
%     Qdisch = sum(dt(idx_disch).*I(idx_disch));
%     idx_chrg = find(I < 0);
%     Qchrg = -sum(dt(idx_chrg).*I(idx_chrg));
%     deltaQ = [Qdisch Qchrg]/3600;
% 
% end
% 
% 
% function [hstw, hst] = histw_edges(vv, ww, vinterval)  
% 
%     nbins = numel(vinterval)-1;
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
% 
% % function [hstw, hst, vinterval] = histw_sym(vv, ww, ngrades)  
% %     maxV  = max(abs(vv));
% %     delta = maxV/ngrades;
% %     nbins = ngrades*2;
% % 
% %     vinterval = linspace(0, maxV, ngrades+1)';
% %     vinterval = [-flip(vinterval(2:end)); vinterval];
% %     % vmid = (vinterval(1:end-1)+vinterval(2:end))/2;
% %     hstw = zeros(nbins, 1);
% %     hst = zeros(nbins, 1);
% %     for i = 1:nbins
% %         if i < nbins
% %             idxes = find(all([(vv >= vinterval(i)),(vv < vinterval(i+1))],2));
% %         elseif i == nbins
% %             idxes = find(all([(vv >= vinterval(i)),(vv <= vinterval(i+1))],2));
% %         end
% %         hst(i) = numel(idxes);
% %         hstw(i) = sum(ww(idxes));
% %     end
% % end