function [NZOscenarioTable,accessToken] = nzoFunctionOld(scenarioName, DataBase,clientID, sheetID,clientSecret,refreshToken, script_id, accessToken,lastTokenTime)
% Check if the token needs to be refreshed
if exist('lastTokenTime', 'var') && datetime('now') >= lastTokenTime + minutes(59)
    disp('Refreshing access token...');
    accessToken = runRefreshToken(clientID, clientSecret, refreshToken);
    % Update lastTokenTime in the workspace
    lastTokenTime = datetime('now');
    assignin('base', 'lastTokenTime', lastTokenTime);

end    

% Define the params inside the function
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

    % Define data range and headers
    headerRange = 'Scenario output 2050!B1:H1';
    dataRange = 'Scenario output 2050!A1:H8'; % Includes headers
    options = weboptions('HeaderFields', {'Authorization', ['Bearer ', accessToken]});
    dataUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, dataRange);

    % Read the entire data table
    fullData = webread(dataUrl, options);
    customColNames = fullData.values{1}(2:end); % Extract column headers
    allData = fullData.values(2:end);          % Exclude headers
    rowNames = cellfun(@(x) x{1}, allData, 'UniformOutput', false); % Extract row names

    % Initialize the result table
    NZOscenarioTable = table();

    % Step 1: Write the relevant demand to Google Sheets
    writeDemandToGoogleSheets(sheetID, accessToken, valueColumn, DataBase);

    % Step 2: Write the specific scenario values to 'scenarios-input'
    writeToGoogleSheets(sheetID, accessToken, ranges, valueColumn, DataBase, []);

    % Step 3: Run the macro to calculate scenarios and costs
    executeGoogleAppsScript(script_id, accessToken);

    % Step 4: Re-read the full data table to get the updated results
    fullData = webread(dataUrl, options); % Re-fetch data after macro execution
    allData = fullData.values(2:end);     % Exclude headers
    rowNames = cellfun(@(x) x{1}, allData, 'UniformOutput', false); % Extract row names

    % Step 5: Read the result row for the selected scenario
    rowIndex = find(strcmpi(rowNames, valueColumn));
    if ~isempty(rowIndex)
        rowValues = allData{rowIndex}(2:end); % Skip row name column
        currentRowTable = cell2table(rowValues(:)', 'VariableNames', customColNames, 'RowNames', {valueColumn});
        NZOscenarioTable = [NZOscenarioTable; currentRowTable]; %#ok<AGROW>
    end
end
