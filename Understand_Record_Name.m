function [busID, param, date] = Understand_Record_Name(rec_name)
% splits the record name 'rec_name' into output:
% busID - numeric
% param - string (parameter name)
% date - datetime
% rec_name format must be: '*busID*__*param-name*__*date*' , e.g. "00120__B2V_TotalI__2023-10-20"
    rec_name = string(rec_name);
    words = split(rec_name,'__');
    busID = str2num(words{1});
    param = words{2};
    date = datetime(words{3}(1:end),'InputFormat','yyyy-MM-dd');
end