function [segs, ledger, records_list] = Find_Driving_Segments_Multi(input_folder, output_folder, opts) 
% Runs acros all "B2V_TotalI"-mat-files in the input folder (using Get_Recors_Ledger) 
% and preforms segmentation (Find_Driving_Segments) 
% Outputs "segs" struct array which contains DRIVE, REST nad CHARGE segments
% Segements data stored as Nx2 array. N - number of found segments of the certain type. 1st column - is for the start the indexes acoeding to the min_grid. 2nd column - is for the segmends end points. 
% "segs" struct also stores the states vector - sate-code of every minuteon the grid
% Also plots day-graphs containing current and ascribed states
% USES:
% Get_Recors_Ledger
% Get_Min_Grid_Vals
% Find_Driving_Segments
    arguments
        input_folder (1,1) string
        output_folder (1,1) string
        opts.save_data = true
        opts.save_png = true
        opts.save_fig = false
    end


    if ~exist(output_folder, 'dir')
        mkdir(output_folder)
    end

    [ledger, records_list, Ndaysets] = Get_Recors_Ledger(input_folder);
    
    segs = struct("busID",{},"date",{},"min_grid",{},"DRIVE_SEGMENTS",{},"REST_SEGMENTS",{},"CHARGE_SEGMENTS",{},"states",{});
    for i = 1:Ndaysets
        % load current and voltage data
        infile = fullfile(input_folder, records_list(ledger.recID_Itot(i)));
        load(infile, 'CSV');
        DATI = CSV;
        clear CSV
    
        [min_grid min_grid_POSval min_grid_NEGval] = Get_Min_Grid_Vals(DATI);
    
        [DRIVE_SEGMENTS, REST_SEGMENTS, CHARGE_SEGMENTS, states] = Find_Driving_Segments(min_grid, min_grid_POSval, min_grid_NEGval);
        fig1 = figure(1);
        plot(min_grid, states*100, min_grid, min_grid_POSval, min_grid, min_grid_NEGval)
        fig_name = "DrvSegs__"+string(ledger.busID(i)) + "__" + string(ledger.date(i)) + ".png";
        if opts.save_png
            saveas(fig1,fullfile(output_folder,fig_name))
        end
        segs(i).busID = ledger.busID(i);
        segs(i).date = ledger.date(i);
        segs(i).min_grid = min_grid;
        segs(i).DRIVE_SEGMENTS = DRIVE_SEGMENTS;
        segs(i).REST_SEGMENTS = REST_SEGMENTS;
        segs(i).CHARGE_SEGMENTS = CHARGE_SEGMENTS;
        segs(i).states = states;
    
    end
    
    if opts.save_data
        save(fullfile(output_folder,"segmentation.mat"),"segs","ledger","records_list");
    end

end