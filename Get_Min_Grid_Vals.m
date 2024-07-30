function [min_grid min_grid_POSval min_grid_NEGval] = Get_Min_Grid_Vals(CSV)
% Resamples row data into the minute-spaced grid
% Input table (CSV) contains two columns: 't' (datetime) and 'val' (numeric)
% The time-grid points set to integer minutes values (e.g. 10:23:00, 10:24:00, 10:25:00...)
% For every time-point the value avereged over +/- 30 sec interval, i.e.[10:22:30, 10:23:30] for time-point 10:23:00
% positeve values and integer values (within 1-minute interval) are
% processed separatly and outputed into 'min_grid_POSval', 'min_grid_NEGval'
% total average per minute vould be min_grid_val = (min_grid_POSval+min_grid_NEGval)
    n_orig = size(CSV,1);
    
    % delete repeating time-values
    [~,ia,~] = unique(CSV.t);
    CSV = CSV(ia,:);

    % find closesets to the start time tA so that: tA = MM:30 inside the data
    time_start = CSV.t(1);
    tA = time_start;
    if second(tA) < 30.0
        tA.Second = 30.0;
    else
        tA.Second = 30.0;
        tA.Minute = tA.Minute+1;
    end
    % find closesets to the end time tB so that: tB = MM:30 inside the data
    time_end = CSV.t(end);
    tB = time_end;
    if second(tB) < 30.0
        tB.Second = 30.0;
        tB.Minute = tB.Minute-1;
    else
        tB.Second = 30.0;
    end
    
    nm = minutes(tB-tA);
    half_min_grid = tA + minutes((0:nm)');
    half_min_grid_Val = interp1(CSV.t,CSV.val,half_min_grid,'linear');
    
    
    CSV(end+1:end+nm+1,:) = [num2cell(half_min_grid), num2cell(half_min_grid_Val)];
    CSV = sortrows(CSV);
    
    min_grid = half_min_grid(1:end-1) + seconds(30);
    min_grid_POSval = zeros(nm,1);
    min_grid_NEGval = zeros(nm,1);
    POSval = CSV.val;
    POSval(POSval<0) = 0;
    NEGval = CSV.val;
    NEGval(NEGval>0) = 0;
    for m = 1:nm
        ia = find(CSV.t == half_min_grid(m));
        ib = find(CSV.t == half_min_grid(m+1));
        min_grid_POSval(m) = seconds(trapz(CSV.t(ia:ib),POSval(ia:ib)))/60;
        min_grid_NEGval(m) = seconds(trapz(CSV.t(ia:ib),NEGval(ia:ib)))/60;
    end
end