function [DataNZOscenarioTable,NZOscenarioTable,accessToken] = nzoFunction(scenarioName, DataBase,clientID, sheetID,clientSecret,refreshToken, script_id, accessToken,lastTokenTime)
% Reinitialize an empty table for results
DataNZOscenarioTable = table();

% Check if the token needs to be refreshed
if exist('lastTokenTime', 'var') && datetime('now') >= lastTokenTime + minutes(59)
    accessToken = runRefreshToken(clientID, clientSecret, refreshToken);
    % Update lastTokenTime in the workspace
    lastTokenTime = datetime('now');
    assignin('base', 'lastTokenTime', lastTokenTime);
end

% Define parameters for execution

params = {
    'ADV', {'scenarios-input!C3:E3', DataBase.InstalledCapacityForOutsideMod{2:4, 'ADV'}'};
    'ADV+NUC', {'scenarios-input!C5:E5', DataBase.InstalledCapacityForOutsideMod{2:4, 'ADV+NUC'}'};
    'B.A.U', {'scenarios-input!C7:E7', DataBase.InstalledCapacityForOutsideMod{2:4, 'B.A.U'}'};
    'M.O.E 1', {'scenarios-input!C11:E11', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 1'}'};
    'M.O.E 2', {'scenarios-input!C13:E13', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 2'}'};
    'M.O.E 3', {'scenarios-input!C15:E15', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 3'}'};
    'MOD', {'scenarios-input!C9:E9', DataBase.InstalledCapacityForOutsideMod{2:4, 'MOD'}'};
};

    % Check if the scenario exists in params
    scenarioIndex = find(strcmpi(params(:, 1), scenarioName), 1);
    if isempty(scenarioIndex)
        error('Scenario "%s" not found in params.', scenarioName);
    end

   % Extract the selected scenario details
    valueColumn = params{scenarioIndex, 1};
    ranges = params{scenarioIndex, 2};

% Read the entire data table once
headerRange = 'small table scenarios-output!B1:S1';
dataRange = 'small table scenarios-output!B2:S218';
nameRange = 'small table scenarios-output!A2:A218';
yearRange = 'small table scenarios-output!B2:B218';
options = weboptions('HeaderFields', {'Authorization', ['Bearer ', accessToken]}, 'Timeout', 120);

dataUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, dataRange);
headerUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, headerRange);
nameUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, nameRange);
yearUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, yearRange);

% Read headers
headerData = webread(headerUrl, options);
customColNames = headerData.values{1}; % Extract headers from B1:S1

% Ensure column names are unique
customColNames = matlab.lang.makeUniqueStrings(customColNames);

% Read names and years
nameData = webread(nameUrl, options);
yearData = webread(yearUrl, options);

names = nameData.values; % Names from A2:A218
years = yearData.values; % Years from B2:B218

% Combine names and years to create unique row names
rowNames = cellfun(@(n, y) sprintf('%s_%s', n{1}, y{1}), names, years, 'UniformOutput', false);



    % Step 1: Write the relevant demand to Google Sheets
    writeDemandToGoogleSheets(sheetID, accessToken, valueColumn, DataBase);

    % Step 2: Write the specific scenario values to 'scenarios-input'
    writeToGoogleSheets(sheetID, accessToken, ranges, valueColumn, DataBase, []);

    % Step 3: Run the macro to calculate scenarios and costs
    maxRetries = 3;
    retryDelay = 5; % Delay in seconds
    attempt = 0;
    success = false;

    while ~success && attempt < maxRetries
        attempt = attempt + 1;
        try
            executeGoogleAppsScript(script_id, accessToken);
            success = true;
        catch ME
            if strcmp(ME.identifier, 'MATLAB:webservices:Timeout')
                warning('Attempt %d: Request timed out. Retrying in %d seconds...', attempt, retryDelay);
                pause(retryDelay);
            else
                rethrow(ME);
            end
        end
    end

    if ~success
        error('All attempts to execute Google Apps Script have failed.');
    end

    % Step 4: Find all rows for the scenario
    specificRowsIndices = find(contains(rowNames, valueColumn));
    if isempty(specificRowsIndices)
        disp(['Rows not found for scenario: ', valueColumn]);
    end

    % Define range for all relevant rows
    specificRowRange = sprintf('small table scenarios-output!B%d:S%d', specificRowsIndices(1) + 1, specificRowsIndices(end) + 1);
    specificRowUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, specificRowRange);
    specificRowData = webread(specificRowUrl, options);

   % Extract and append row values
if isempty(specificRowData.values)
    disp(['Rows not found for scenario: ', valueColumn]);
else
    for j = 1:size(specificRowData.values, 1)
        rowValues = specificRowData.values{j};

        % Ensure rowValues matches column count
        if length(rowValues) < length(customColNames)
            rowValues = [rowValues, repmat({''}, 1, length(customColNames) - length(rowValues))];
        end

        % Convert numeric strings to numbers
        rowValues = cellfun(@(x) str2double(x), rowValues, 'UniformOutput', false);

        % Create a unique row name
        currentRowName = sprintf('%s_%s', valueColumn, years{specificRowsIndices(j)}{1});
        if ismember(currentRowName, DataNZOscenarioTable.Properties.RowNames)
            continue; % Avoid duplicate warnings; just skip
        end

        % Append the result to DataNZOscenarioTable
        currentRowTable = cell2table(rowValues(:)', 'VariableNames', customColNames, 'RowNames', {currentRowName});
        DataNZOscenarioTable = [DataNZOscenarioTable; currentRowTable]; %#ok<AGROW>
    end
end

NZOscenarioTable = DataNZOscenarioTable;

% Display the final DataNZOscenarioTable

%disp('Final DataNZOscenarioTable and elapsed time in seconds:');
%disp(DataNZOscenarioTable);

