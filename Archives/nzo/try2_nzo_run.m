% Main script
% Define parameters for execution
params = {
    'MOD', {'scenarios-input!C9:E9', DataBase.InstalledCapacityForOutsideMod{2:4, 'MOD'}'};
    'M.O.E 1', {'scenarios-input!C11:E11', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 1'}'};
    'M.O.E 2', {'scenarios-input!C13:E13', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 2'}'};
    'B.A.U', {'scenarios-input!C7:E7', DataBase.InstalledCapacityForOutsideMod{2:4, 'B.A.U'}'};
    'ADV', {'scenarios-input!C3:E3', DataBase.InstalledCapacityForOutsideMod{2:4, 'ADV'}'};
    'ADV+NUC', {'scenarios-input!C5:E5', DataBase.InstalledCapacityForOutsideMod{2:4, 'ADV+NUC'}'};
    'M.O.E 3', {'scenarios-input!C15:E15', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 3'}'};
};


% Define Google Sheets details for the table
headerRange = 'Scenario output 2050!B1:H1';
rowNameRange = 'Scenario output 2050!A2:A7';
dataRange = 'Scenario output 2050!B2:H7';

% Build table from Google Sheets
scenarioTable = buildScenarioTable(sheetID, accessToken, headerRange, rowNameRange, dataRange);

% Loop through parameters and call the function
for i = 1:size(params, 1)
    valueColumn = params{i, 1};
    ranges = params{i, 2};
    writeToGoogleSheets(sheetID, accessToken, ranges, valueColumn, DataBase, scenarioTable);
end

disp(scenarioTable);

%% --- Function to build scenario table from Google Sheets ---
function scenarioTable = buildScenarioTable(sheetID, accessToken, headerRange, rowNameRange, dataRange)
    % Construct URLs for API requests
    headerUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, headerRange);
    rowNameUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, rowNameRange);
    dataUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, dataRange);

    % HTTP request options with authorization
    options = weboptions('HeaderFields', {'Authorization', ['Bearer ', accessToken]});

    try
        % Read column headers
        headerData = webread(headerUrl, options);
        customColNames = headerData.values{1};

        % Read row names
        rowNameData = webread(rowNameUrl, options);
        rowNames = vertcat(rowNameData.values{:});

        % Read table data
        data = webread(dataUrl, options);
        valuesMatrix = cell(size(data.values, 1), numel(data.values{1}));
        for i = 1:size(data.values, 1)
            row = data.values{i};
            if numel(row) < numel(customColNames)
                row(end+1:numel(customColNames)) = {''};
            end
            valuesMatrix(i, :) = row;
        end

        % Build MATLAB table
        scenarioTable = cell2table(valuesMatrix, 'VariableNames', customColNames, 'RowNames', rowNames);
    catch
        scenarioTable = [];
    end
end

%% --- Function to write to Google Sheets ---
function writeToGoogleSheets(sheetID, accessToken, ranges, valueColumn, DataBase, scenarioTable)
    % Write ranges to Google Sheets
    for i = 1:size(ranges, 1)
        range = ranges{i, 1};
        valuesToWrite = ranges{i, 2};
        request_body = jsonencode(struct('range', range, 'majorDimension', 'ROWS', 'values', {{valuesToWrite}}));
        options = weboptions('RequestMethod', 'PUT', ...
                             'HeaderFields', {'Authorization', ['Bearer ' accessToken]}, ...
                             'MediaType', 'application/json');
        try
            webwrite(sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s?valueInputOption=USER_ENTERED', sheetID, range), request_body, options);
        end
    end

    % Use scenarioTable for further calculations
    if ~isempty(scenarioTable)
        standardizedValueColumn = strrep(valueColumn, '.', '');
        standardizedValueColumn = strrep(standardizedValueColumn, ' ', '');
        rowNames = strrep(scenarioTable.Properties.RowNames, '.', '');
        rowNames = strrep(rowNames, ' ', '');
        matchIndex = find(strcmpi(rowNames, standardizedValueColumn));
        if ~isempty(matchIndex)
            specificData = scenarioTable{matchIndex, :};
        end
    end

    % Google Apps Script's Script ID
    script_id = '1BQg_sOhONPYYGIrsUcZWIY6sFv_eNjQGc_AHE1RrnJbpLKP2yp0DtyDb';

    % URL for API request to execute the script
    url = ['https://script.googleapis.com/v1/scripts/' script_id ':run'];

    % JSON request body to call the function "calculateScenariosAndCosts" in devMode
    request_body = jsonencode(struct('function', 'calculateScenariosAndCosts', 'devMode', true));

    % Set request options
    options = weboptions('RequestMethod', 'POST', ...
                         'HeaderFields', {'Authorization', ['Bearer ' accessToken]}, ...
                         'MediaType', 'application/json', ...
                         'Timeout', 60);

    % Send the request to execute the script
    try
        webwrite(url, request_body, options);
    end
end
