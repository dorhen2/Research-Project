%% Nucler by ROTH
tic;   
fileName = fullfile('Data', 'ROTH 1 Model.xlsx'); % Target Excel file with correct path
sheetName = 'ROTH 1.0'; % Target sheet

% Define the columns to process (excluding ADV)
columnsToProcess = {'ADV+NUC', 'M.O.E 3'};
ratios = [0.795, 0.898]; % Ratios to write to O2 for each column, 0.795 for ADV, 0.898 FOR MOD  
columnResults = {}; % Cell array to store results from each run

% Predefine ranges to minimize Excel I/O operations
rowNamesRange = 'D17:D21'; % Range for row names
columnNamesRange = 'E16:F16'; % Range for column names
dataRange = 'E17:F21'; % Range for data

% Read row and column labels once
rowNames = readcell(fileName, 'Sheet', sheetName, 'Range', rowNamesRange, 'UseExcel', true);
columnNames = readcell(fileName, 'Sheet', sheetName, 'Range', columnNamesRange, 'UseExcel', true);

% Define exact target cells
targetCells = {'E7', 'E11', 'E8'}; % Corresponding to rows 2, 4, 5

% Loop over each column
for colIdx = 1:length(columnsToProcess)
    % Write the appropriate ratio to cell O2
    writematrix(ratios(colIdx), fileName, 'Sheet', sheetName, 'Range', 'O2');

    % Extract specific data from the current column
    data = DataBase.InstalledCapacityForOutsideMod{[2, 4, 5], columnsToProcess{colIdx}}; % Rows 2, 4, 5

    % Write each value to the corresponding target cell
    for i = 1:length(data)
        writematrix(data(i), fileName, 'Sheet', sheetName, 'Range', targetCells{i});
    end

    % Read data from Excel
    dataRead = readmatrix(fileName, 'Sheet', sheetName, 'Range', dataRange, 'UseExcel', true);

    % Create a table
    resultTable = array2table(dataRead, 'VariableNames', columnNames, 'RowNames', rowNames);

    % Add a new variable to indicate the column being processed
    resultTable.ColumnProcessed = repmat(columnsToProcess(colIdx), size(resultTable, 1), 1);

    % Add unique row identifiers to prevent duplicate row names
    resultTable.Properties.RowNames = strcat(resultTable.Properties.RowNames, "_", columnsToProcess{colIdx});

    % Add to the results array
    columnResults{colIdx} = resultTable;
end

% Combine all results into one table
ROTHcombinedTable = vertcat(columnResults{:});
DataBase.RothNuclerTable = ROTHcombinedTable; 
% Display the combined table
disp('Combined Results Table:');
disp(ROTHcombinedTable);

beep;
%%  Extract Data for DataBase.InstalledCapacityForOutsideMod
% Define constants
baseYear = 2019;
targetYear = 2050;
years = targetYear - baseYear;
base_value = 72.5; % Known base value for both ADV+NUC and M.O.E 3

% --- Extract Target Values ---
ADV_NUC_target = ROTHcombinedTable{'Yearly Post Nuclear Demand_ADV+NUC', 'TWh'};
MOE3_target = ROTHcombinedTable{'Yearly Post Nuclear Demand_M.O.E 3', 'TWh'};

% --- Calculate Demand Growth Rates ---
demand_growth_rate_ADV_NUC_percent = (exp(log(ADV_NUC_target / base_value) / years) - 1);
demand_growth_rate_MOE3_percent = (exp(log(MOE3_target / base_value) / years) - 1) ;

% --- Update DataBase.InstalledCapacityForOutsideMod ---
DataBase.InstalledCapacityForOutsideMod{'Grow rate to NZO model', 'ADV+NUC'} = demand_growth_rate_ADV_NUC_percent;
DataBase.InstalledCapacityForOutsideMod{'Grow rate to NZO model', 'M.O.E 3'} = demand_growth_rate_MOE3_percent;

% --- Display Results ---
disp('--- Final Growth Rates ---');
disp(['ADV+NUC Demand Growth Rate: ', num2str(demand_growth_rate_ADV_NUC_percent), '%']);
disp(['M.O.E 3 Demand Growth Rate: ', num2str(demand_growth_rate_MOE3_percent), '%']);

elapsedTime = toc;
disp('Time in Seconds:');
disp(elapsedTime);

beep;