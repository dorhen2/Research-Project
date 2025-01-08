%% Nucler by ROTH
fileName = 'ROTH 1 Model.xlsx'; % Target Excel file
sheetName = 'ROTH 1.0'; % Target sheet

% Define the columns to process (excluding ADV)
columnsToProcess = {'ADV+NUC', 'M.O.E 3'};
ratios = [0.795, 0.898]; % Ratios to write to O2 for each column
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
combinedResults = vertcat(columnResults{:});

% Display the combined table
disp('Combined Results Table:');
disp(combinedResults);

beep;
%% %% write code
% New Spreadsheet ID for Google Sheets
sheetID = '1QvEzjJ6e3JSz7u9p1ValkdNwdz3GCWvFspM52yjl_pM';

% Target cell range - cell B1 in Documentation sheet
range = 'parameters!C7';

% Value to write - for example, the number 1000
request_body = jsonencode(struct('range', range, 'majorDimension', 'ROWS', 'values', {{ {2033} }}));

% URL to write in Google Sheets API
url = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s?valueInputOption=USER_ENTERED', sheetID, range);

% Set request options with Access Token
options = weboptions('RequestMethod', 'PUT', ...
                     'HeaderFields', {'Authorization', ['Bearer ' accessToken]}, ...
                     'MediaType', 'application/json');

% Send the write request
try
    response = webwrite(url, request_body, options);
    disp('Value written successfully to Google Sheets:');
    disp(response);
catch ME
    disp('Error writing to Google Sheets:');
    disp(ME.message);
end
%% macro

% Google Apps Script's Deployment ID
script_id = 'AKfycbzztZjKI7hpzu0FCfzVPdqnif3mfnf9S-6Y-Z91WTUp2xvMpMJHU-NH1dhzXiLZfOORnQ';

% URL for API request to execute the script
url = ['https://script.googleapis.com/v1/scripts/' script_id ':run'];

% JSON request body to call the function "calculateElectricityCurve"
request_body = jsonencode(struct('function', 'calculateElectricityCurve'));

% Set request options with Access Token
options = weboptions('RequestMethod', 'POST', ...
                     'HeaderFields', {'Authorization', ['Bearer ' accessToken]}, ...
                     'MediaType', 'application/json', ...
                     'Timeout', 60);

% Send the request to execute the script
try
    % Execute the Apps Script
    response = webwrite(url, request_body, options);
    disp('Script executed successfully:');
    disp(response);
catch ME
    % Handle errors
    disp('Error executing calculateElectricityCurve script:');
    disp(ME.message);
end


%% read code
% Google Sheets details
range = 'summary!C28';  % Specify the cell range (C28 in "summary" sheet)

% URL for reading data
url = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, range);

% HTTP request options with authorization header
options = weboptions('HeaderFields', {'Authorization', ['Bearer ', accessToken]});

% Send the request and read data
data = webread(url, options);

% Display the retrieved value
if isfield(data, 'values') && ~isempty(data.values)
    disp('Value from cell C28 in sheet "summary":');
    disp(data.values{1}); % Display the value
else
    disp('No value found in cell C28.');
end

