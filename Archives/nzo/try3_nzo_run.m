% Main script
% Define parameters for execution
params = {
     'MOD', {'scenarios-input!C9:E9', DataBase.InstalledCapacityForOutsideMod{2:4, 'MOD'}'};
};

% Define Google Sheets details for the table
headerRange = 'Scenario output 2050!B1:H1';
rowNameRange = 'Scenario output 2050!A2:A8'; % Adjusted for all rows
dataRange = 'Scenario output 2050!B2:H8'; % Adjusted for all rows

% Initialize scenarioTable
scenarioTable = table();

% Loop through parameters and process each scenario
for i = 1:size(params, 1)
    valueColumn = params{i, 1};
    ranges = params{i, 2};
    
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

%% 
function rowTable = readScenarioRow(sheetID, accessToken, headerRange, rowNameRange, dataRange, targetRowName)
    % Construct URLs for API requests
    headerUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, headerRange);
    rowNameUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, rowNameRange);
    options = weboptions('HeaderFields', {'Authorization', ['Bearer ', accessToken]});

    try
        % Read column headers
        disp('Debug: Reading column headers...');
        headerData = webread(headerUrl, options);
        customColNames = headerData.values{1};
        disp('Debug: Column headers read successfully:');
        disp(customColNames);

        % Read row names
        disp('Debug: Reading row names...');
        rowNameData = webread(rowNameUrl, options);
        rowNames = vertcat(rowNameData.values{:});
        disp('Debug: Row names read successfully:');
        disp(rowNames);

        % Find index of the target row
        disp('Debug: Locating the specified row...');
        rowIndex = find(strcmpi(rowNames, targetRowName));
        if isempty(rowIndex)
            error('Row with name "%s" not found.', targetRowName);
        end
        disp(['Debug: Found target row "', targetRowName, '" at index: ', num2str(rowIndex)]);

        % Construct the range for the target row
        specificRowRange = sprintf('Scenario output 2050!B%d:H%d', rowIndex + 1, rowIndex + 1);
        specificRowData = webread(sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, specificRowRange), options);

        % Debugging: Display raw data
        disp('Raw specificRowData.values:');
        disp(specificRowData.values);

        % Validate the structure of specificRowData.values
        if isfield(specificRowData, 'values') && iscell(specificRowData.values)
            rowValues = specificRowData.values{1}; % Extract row values
        else
            error('Invalid data structure: specificRowData.values is not in the expected format.');
        end

        % Debugging: Ensure rowValues matches column headers
        disp('Processed rowValues:');
        disp(rowValues);
        if numel(rowValues) ~= numel(customColNames)
            error('Mismatch between the number of row values (%d) and column headers (%d).', numel(rowValues), numel(customColNames));
        end

        % Build the table for the row
        disp('Debug: Building table for the specific row...');
        rowTable = cell2table(rowValues(:)', 'VariableNames', customColNames, 'RowNames', {targetRowName});
        disp('Debug: Row table built successfully:');
        disp(rowTable);

    catch ME
        % Handle errors
        disp('Error reading specific row from Google Sheets:');
        disp(ME.message);
        rowTable = table(); % Return an empty table on error
    end
end

%% --- Function to write to Google Sheets ---
function writeToGoogleSheets(sheetID, accessToken, ranges, valueColumn, DataBase, currentRowTable)
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

    % Process currentRowTable if needed
    if ~isempty(currentRowTable)
        disp(['Processed row: ', currentRowTable.Properties.RowNames{1}]);
    end
end
