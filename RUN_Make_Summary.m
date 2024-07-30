input_folder = "d:\МЕТРО\999_mat";
batch_name = "999";
output_filename = ".\Data_summary.xlsx";

% optional:
daysample_name_pattern = "*__*__*.mat";
n_serial = 48*2+72;

[SUM, corrupted_samples] = Make_Summary(input_folder, batch_name,output_filename, daysample_name_pattern=daysample_name_pattern, n_serial=n_serial);