% Main script

% Check if the token needs to be refreshed
if exist('lastTokenTime', 'var') && datetime('now') >= lastTokenTime + minutes(59)
    accessToken = runRefreshToken(clientID, clientSecret, refreshToken);
    % Update lastTokenTime in the workspace
    lastTokenTime = datetime('now');
    assignin('base', 'lastTokenTime', lastTokenTime);
end

% Define parameters for execution
tic;
params = {
    'ADV', {'scenarios-input!C3:E3', DataBase.InstalledCapacityForOutsideMod{2:4, 'ADV'}'};
    'ADV+NUC', {'scenarios-input!C5:E5', DataBase.InstalledCapacityForOutsideMod{2:4, 'ADV+NUC'}'};
    'B.A.U', {'scenarios-input!C7:E7', DataBase.InstalledCapacityForOutsideMod{2:4, 'B.A.U'}'};
    'M.O.E 1', {'scenarios-input!C11:E11', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 1'}'};
    'M.O.E 2', {'scenarios-input!C13:E13', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 2'}'};
    'M.O.E 3', {'scenarios-input!C15:E15', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 3'}'};
    'MOD', {'scenarios-input!C9:E9', DataBase.InstalledCapacityForOutsideMod{2:4, 'MOD'}'};
};

% Read the entire data table once
headerRange = 'small table scenarios-output!B1:S1';
dataRange = 'small table scenarios-output!B2:S218';
nameRange = 'small table scenarios-output!A2:A218';
yearRange = 'small table scenarios-output!B2:B218';
options = weboptions('HeaderFields', {'Authorization', ['Bearer ', accessToken]});

dataUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, dataRange);
headerUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, headerRange);
nameUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, nameRange);
yearUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, yearRange);

% Read headers
headerData = webread(headerUrl, options);
customColNames = headerData.values{1}; % Extract headers from B1:S1

% Ensure column names are unique
customColNames = matlab.lang.makeUniqueStrings(customColNames);

% Read data
fullData = webread(dataUrl, options);
allData = fullData.values; % Keep all rows

% Read names and years
nameData = webread(nameUrl, options);
yearData = webread(yearUrl, options);

names = nameData.values; % Names from A2:A218
years = yearData.values; % Years from B2:B218

% Combine names and years to create unique row names
rowNames = cellfun(@(n, y) sprintf('%s_%s', n{1}, y{1}), names, years, 'UniformOutput', false);

% Ensure the length of rowNames matches dataMatrix rows
dataMatrix = cell(size(allData, 1), length(customColNames));
numRows = size(dataMatrix, 1);
if length(rowNames) > numRows
    rowNames = rowNames(1:numRows); % Trim excess names
elseif length(rowNames) < numRows
    % Generate placeholder names for missing rows
    extraNames = arrayfun(@(i) sprintf('Row_%d', i), (length(rowNames)+1):numRows, 'UniformOutput', false);
    rowNames = [rowNames; extraNames'];
end

% Ensure unique row names
rowNames = matlab.lang.makeUniqueStrings(rowNames);

% Populate dataMatrix from allData (handling potential missing values)
for i = 1:size(allData, 1)
    currentRow = allData{i};
    for j = 1:length(customColNames)
        if j <= length(currentRow)
            dataMatrix{i, j} = currentRow{j};
        else
            dataMatrix{i, j} = ''; % Fill missing cells with empty string
        end
    end
end

% Remove the YEAR column
yearIndex = find(strcmpi(customColNames, 'YEAR'));
if ~isempty(yearIndex)
    dataMatrix(:, yearIndex) = [];
    customColNames(yearIndex) = [];
end

% Create table with unique column names and updated row names
NZOscenarioTable = cell2table(dataMatrix, 'VariableNames', customColNames, 'RowNames', rowNames);

% Explicitly add the last row if missing
lastRowIndex = numel(rowNames);
if ~strcmp(NZOscenarioTable.Properties.RowNames{end}, rowNames{end})
    lastRowData = allData{end};
    lastRowValues = cell(1, length(customColNames));
    for j = 1:length(customColNames)
        if j <= length(lastRowData)
            lastRowValues{j} = lastRowData{j};
        else
            lastRowValues{j} = '';
        end
    end
    NZOscenarioTable = [NZOscenarioTable; cell2table(lastRowValues, 'VariableNames', customColNames, 'RowNames', {rowNames{lastRowIndex}})]; %#ok<AGROW>
end

% Process each scenario
for i = 1:size(params, 1)
    valueColumn = params{i, 1};
    ranges = params{i, 2};

    % Step 1: Write the relevant demand to Google Sheets
    writeDemandToGoogleSheets(sheetID, accessToken, valueColumn, DataBase);

    % Step 2: Write the specific scenario values to 'scenarios-input'
    writeToGoogleSheets(sheetID, accessToken, ranges, valueColumn, DataBase, []);

    % Step 3: Run the macro to calculate scenarios and costs
    executeGoogleAppsScript(script_id, accessToken);

    % Step 4: Re-read the full data table to get the updated results
    fullData = webread(dataUrl, options); % Re-fetch data after macro execution
    allData = fullData.values; % Keep all rows

    % Step 5: Read the result row for the current scenario
    rowIndex = find(strcmpi(rowNames, valueColumn));
    if ~isempty(rowIndex)
        rowValues = allData{rowIndex}(2:end); % Skip row name column

        % Step 6: Append the result to NZOscenarioTable
        currentRowTable = cell2table(rowValues(:)', 'VariableNames', customColNames, 'RowNames', {valueColumn});
        NZOscenarioTable = [NZOscenarioTable; currentRowTable]; %#ok<AGROW>
    end
end

% Display the final NZOscenarioTable
elapsedTime = toc;
disp('Final NZOscenarioTable and elapsed time in seconds:');
disp(NZOscenarioTable);
disp(elapsedTime);

%% Function Definitions

function writeDemandToGoogleSheets(sheetID, accessToken, valueColumn, DataBase)
    % Target range
    range = 'Demand!B21:B51';

    % Number of rows in the range
    numRows = 31;

    % Values to write (assumes same value repeated for all rows)
    valueToWrite = DataBase.InstalledCapacityForOutsideMod{'Grow rate to NZO model', valueColumn};
    valuesToWrite = arrayfun(@(x) {valueToWrite}, 1:numRows, 'UniformOutput', false); % Ensure 2D cell array for a column

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

function writeToGoogleSheets(sheetID, accessToken, ranges, valueColumn, DataBase, currentRowTable)
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
