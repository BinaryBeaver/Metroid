function [ledger, records_list, Ndaysets] = Get_Recors_Ledger(input_folder,opts)
% Searches the folder for mat-files with data (records)
% Forms a list (string array) of dat-files (records) - record_list 
% Forms a table containing record indexes (within the record list) for differant data-parameters
%
% Currently, if not all parameters found for a particular date, the data-set (several records for different parameters for one day)
% for this date is considered currupted and not includet into the ledger
%
% Optional input:
% n_serial - number of serial cell in the battery. Needed to conver total voltage to cell-average voltage
% daysample_name_pattern - (string) pattern for file-name recognition
%
% Uses:
% Understand_Record_Name

    arguments
        input_folder (1,1) string
        opts.daysample_name_pattern (1,1) string = "*__*__*.mat"
    end

    daysample_name_pattern = opts.daysample_name_pattern;
    records_list = {dir(fullfile(input_folder,daysample_name_pattern)).name}';
    records_list = string(records_list);
    Nrecs = numel(records_list);
    
    %% creating a ledger of files in the folder
    % list of parameter tags in filenames
    param_list = ["B2V_TotalI","B2V_HVB","B2V_MinCellV","B2V_MaxCellV","B2V_MinCellT","B2V_MaxCellT"];
    varNames = ["busID","date","recID_Itot","recID_Vtot","recID_Vmin","recID_Vmax","recID_Tmin","recID_Tmax"];
    varTypes = ["uint32","datetime","uint32","uint32","uint32","uint32","uint32","uint32"];
    sz = [0 8];
    ledger = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
    wid = 'MATLAB:table:RowsAddedExistingVars';
    warning('off',wid);
    
    
    for s = 1:Nrecs
        [busID, param, date] = Understand_Record_Name(records_list{s}(1:end-4));
    
        ix_record = find((ledger.busID == busID)&(ledger.date == date));
        if isempty(ix_record)
            ix_record = size(ledger,1)+1;
    
            ledger.busID(ix_record) = busID;
            ledger.date(ix_record) = date;
        end
        par_id = find(param_list == param);
        if isempty(par_id)
            warning("Invalid parametr tag: %s",records_list{s})
        else
            if ledger{ix_record,par_id+2} ~= 0
                warning("Dublicating record: %s",records_list{s})
            end
            ledger{ix_record,par_id+2} = s;
        end
    end
    Ndaysets = height(ledger);
end