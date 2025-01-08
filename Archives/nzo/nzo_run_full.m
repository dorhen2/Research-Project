% Main script
% Define parameters for execution
tic;    
params = {
    'MOD', {'scenarios-input!C9:E9', DataBase.InstalledCapacityForOutsideMod{2:4, 'MOD'}'};
    'M.O.E 1', {'scenarios-input!C11:E11', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 1'}'};
    'M.O.E 2', {'scenarios-input!C13:E13', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 2'}'};
    'B.A.U', {'scenarios-input!C7:E7', DataBase.InstalledCapacityForOutsideMod{2:4, 'B.A.U'}'};
    'ADV', {'scenarios-input!C3:E3', DataBase.InstalledCapacityForOutsideMod{2:4, 'ADV'}'};
    'ADV+NUC', {'scenarios-input!C5:E5', DataBase.InstalledCapacityForOutsideMod{2:4, 'ADV+NUC'}'};
    'M.O.E 3', {'scenarios-input!C15:E15', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 3'}'};
};

% Define target ranges and corresponding data
ranges = {
  'scenarios-input!C9:E9', DataBase.InstalledCapacityForOutsideMod{2:4, 'MOD'}';
    'scenarios-input!C11:E11', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 1'}';
    'scenarios-input!C13:E13', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 2'}';
    'scenarios-input!C7:E7', DataBase.InstalledCapacityForOutsideMod{2:4, 'B.A.U'}';
    'scenarios-input!C3:E3', DataBase.InstalledCapacityForOutsideMod{2:4, 'ADV'}';
    'scenarios-input!C5:E5', DataBase.InstalledCapacityForOutsideMod{2:4, 'ADV+NUC'}';
    'scenarios-input!C15:E15', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 3'}';
};

% Loop through each range and data pair
for i = 1:size(ranges, 1)
    % Extract range and data
    range = ranges{i, 1};
    valuesToWrite = ranges{i, 2};
    
    % Prepare the request body
    request_body = jsonencode(struct('range', range, 'majorDimension', 'ROWS', 'values', {{valuesToWrite}}));
    
    % URL to write in Google Sheets API
    url = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s?valueInputOption=USER_ENTERED', sheetID, range);
    
    % Set request options with Access Token
    options = weboptions('RequestMethod', 'PUT', ...
                         'HeaderFields', {'Authorization', ['Bearer ' accessToken]}, ...
                         'MediaType', 'application/json');
    
    % Send the write request
    webwrite(url, request_body, options);
end

% Define Google Sheets details for the table
headerRange = 'Scenario output 2050!B1:H1';
rowNameRange = 'Scenario output 2050!A2:A8';
dataRange = 'Scenario output 2050!B2:H8';

% Initialize scenarioTable
scenarioTable = table();

% Loop through parameters and process each scenario
for i = 1:size(params, 1)
    valueColumn = params{i, 1};
    ranges = params{i, 2};
    
    % Write new demand to Google Sheets
    writeDemandToGoogleSheets(sheetID, accessToken, valueColumn, DataBase);

    % Run the macro to calculate scenarios and costs
    executeGoogleAppsScript(script_id, accessToken);

    % Read the relevant row for the current parameter
    currentRowTable = readScenarioRow(sheetID, accessToken, headerRange, rowNameRange, dataRange, valueColumn);
    
    % Append the current row to scenarioTable
    if ~isempty(currentRowTable)
        scenarioTable = [scenarioTable; currentRowTable]; %#ok<AGROW>
    end
    
    % Write to Google Sheets and execute additional processing
    writeToGoogleSheets(sheetID, accessToken, ranges, valueColumn, DataBase, currentRowTable);
end

% Display the final scenarioTable
disp('Final scenarioTable:');
disp(scenarioTable);
elapsedTime = toc;
disp('Time in Seconds:');
disp(elapsedTime);

beep;
%% --- Function Definitions ---
function writeDemandToGoogleSheets(sheetID, accessToken, valueColumn, DataBase)
    % Target range
    range = 'Demand!B21:B51';

    % Number of rows in the range
    numRows = 31;

    % Values to write
    valuesToWrite = arrayfun(@(x) {DataBase.InstalledCapacityForOutsideMod{'Grow rate to NZO model', valueColumn}}, ...
                             1:numRows, 'UniformOutput', false);

    % Prepare the request body
    request_body = jsonencode(struct('range', range, 'majorDimension', 'ROWS', 'values', {valuesToWrite}));

    % URL for API request
    url = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s?valueInputOption=USER_ENTERED', sheetID, range);

    % Request options
    options = weboptions('RequestMethod', 'PUT', ...
                         'HeaderFields', {'Authorization', ['Bearer ' accessToken]}, ...
                         'MediaType', 'application/json');

    % Execute the API request
    webwrite(url, request_body, options);
end

function executeGoogleAppsScript(script_id, accessToken)
    % URL for API request to execute the script
    url = sprintf('https://script.googleapis.com/v1/scripts/%s:run', script_id);

    % JSON request body to call the function
    request_body = jsonencode(struct('function', 'calculateScenariosAndCosts', 'devMode', true));

    % Set request options
    options = weboptions('RequestMethod', 'POST', ...
                         'HeaderFields', {'Authorization', ['Bearer ' accessToken]}, ...
                         'MediaType', 'application/json', ...
                         'Timeout', 60);

    % Send the request to execute the script
    webwrite(url, request_body, options);
end

function rowTable = readScenarioRow(sheetID, accessToken, headerRange, rowNameRange, dataRange, targetRowName)
    % Construct URLs for API requests
    headerUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, headerRange);
    rowNameUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, rowNameRange);
    options = weboptions('HeaderFields', {'Authorization', ['Bearer ', accessToken]});

    % Read column headers
    headerData = webread(headerUrl, options);
    customColNames = headerData.values{1};

    % Read row names
    rowNameData = webread(rowNameUrl, options);
    rowNames = vertcat(rowNameData.values{:});

    % Find index of the target row
    rowIndex = find(strcmpi(rowNames, targetRowName));

    % Construct the range for the target row
    specificRowRange = sprintf('Scenario output 2050!B%d:H%d', rowIndex + 1, rowIndex + 1);
    specificRowData = webread(sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, specificRowRange), options);

    % Extract row values
    rowValues = specificRowData.values{1};

    % Build the table for the row
    rowTable = cell2table(rowValues(:)', 'VariableNames', customColNames, 'RowNames', {targetRowName});
end

function writeToGoogleSheets(sheetID, accessToken, ranges, valueColumn, DataBase, currentRowTable)
    % Write ranges to Google Sheets
    for i = 1:size(ranges, 1)
        range = ranges{i, 1};
        valuesToWrite = ranges{i, 2};
        request_body = jsonencode(struct('range', range, 'majorDimension', 'ROWS', 'values', {{valuesToWrite}}));
        options = weboptions('RequestMethod', 'PUT', ...
                             'HeaderFields', {'Authorization', ['Bearer ' accessToken]}, ...
                             'MediaType', 'application/json');
        webwrite(sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s?valueInputOption=USER_ENTERED', sheetID, range), request_body, options);
    end
end
