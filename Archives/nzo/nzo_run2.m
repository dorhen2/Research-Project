%% write
% Spreadsheet ID for Google Sheets
sheetID = '1QvEzjJ6e3JSz7u9p1ValkdNwdz3GCWvFspM52yjl_pM';

% Target range
range = 'Demand!B21:B51';

% Number of rows in the range
numRows = 31;

% Values to write (0.02 for each row)
valuesToWrite = arrayfun(@(x) {DataBase.InstalledCapacityForOutsideMod{'Grow rate to NZO model', 'ADV'}}, 1:numRows, 'UniformOutput', false); % Create array of arrays for rows

% Prepare the request body with JSON encoding
request_body = jsonencode(struct( ...
    'range', range, ...
    'majorDimension', 'ROWS', ...
    'values', {valuesToWrite}));

% URL for API request
url = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s?valueInputOption=USER_ENTERED', sheetID, range);

% Request options
options = weboptions('RequestMethod', 'PUT', ...
                     'HeaderFields', {'Authorization', ['Bearer ' accessToken]}, ...
                     'MediaType', 'application/json');

% Execute the API request
try
    response = webwrite(url, request_body, options);
    disp('Values written successfully to Google Sheets:');
    disp(response);
catch ME
    disp('Error writing to Google Sheets:');
    disp(ME.message);
end

%% 

% Define target ranges and corresponding data
ranges = {
    'scenarios-input!C3:E3', DataBase.InstalledCapacityForOutsideMod{2:4, 'ADV'}';
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
    try
        response = webwrite(url, request_body, options);
        fprintf('Values written successfully to range %s in Google Sheets:\n', range);
        disp(response);
    catch ME
        fprintf('Error writing to range %s in Google Sheets:\n', range);
        disp(ME.message);
    end
end

%% macro code 

% Access Token received after authentication
access_token = 'ya29.a0AeDClZD58le2V4EpauTS9IoEMUm3Z26DZq7XwF-0G927HxuE437ye0qGcdhQZyw5P3IPRQgeUyNhETnu18ApgPHlc7SSyae-a1rWuxdig6hr-L07MjXW7aHQyHjcaSgT6xLZe-MFhnGvTykRroudsyJUPEB2ww36-Or8z0GUaCgYKAfYSARISFQHGX2MiNNXF_W4NjjYS3AuEX90cWg0175';

% Google Apps Script's Script ID
script_id = '1BQg_sOhONPYYGIrsUcZWIY6sFv_eNjQGc_AHE1RrnJbpLKP2yp0DtyDb';

% URL for API request to execute the script
url = ['https://script.googleapis.com/v1/scripts/' script_id ':run'];

% JSON request body to call the function "calculateElectricityCurve" in devMode
request_body = jsonencode(struct('function', 'calculateScenariosAndCosts', 'devMode', true));

% Set request options with Access Token and increased Timeout (60 seconds)
options = weboptions('RequestMethod', 'POST', ...
                     'HeaderFields', {'Authorization', ['Bearer ' accessToken]}, ...
                     'MediaType', 'application/json', ...
                     'Timeout', 60);

% Send the request to execute the script
try
    response = webwrite(url, request_body, options);
    disp('Script executed successfully:');
    disp(response);
catch ME
    disp('Error executing calculateElectricityCurve script:');
    disp(ME.message);
end



%% Read and convert data to MATLAB table with dynamic row and column names
% Google Sheets details
headerRange = 'Scenario output 2050!B1:H1';  % Specify the range for column headers
rowNameRange = 'Scenario output 2050!A4:A7'; % Specify the range for row names
dataRange = 'Scenario output 2050!B4:H7';   % Specify the range for data

% URLs for reading headers, row names, and data
headerUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, headerRange);
rowNameUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, rowNameRange);
dataUrl = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s', sheetID, dataRange);

% HTTP request options with authorization header
options = weboptions('HeaderFields', {'Authorization', ['Bearer ', accessToken]});

try
    % Read column headers
    headerData = webread(headerUrl, options);
    if isfield(headerData, 'values') && ~isempty(headerData.values)
        customColNames = headerData.values{1}; % Extract column headers (first row of the header range)
    else
        error('No headers found in the specified range.');
    end
    
    % Read row names
    rowNameData = webread(rowNameUrl, options);
    if isfield(rowNameData, 'values') && ~isempty(rowNameData.values)
        rowNames = rowNameData.values; % Extract row names (each row in the range)
        rowNames = vertcat(rowNames{:}); % Flatten the nested cell array into a single array
    else
        error('No row names found in the specified range.');
    end
    
    % Read table data
    data = webread(dataUrl, options);
    if isfield(data, 'values') && ~isempty(data.values)
        disp('Values from the range Scenario output 2050!B4:H7:');
        
        % Process table data
        values = data.values; % Extract rows from the data
        valuesMatrix = cellfun(@(row) row', values, 'UniformOutput', false); % Transpose each row
        valuesMatrix = vertcat(valuesMatrix{:}); % Combine all rows into a single matrix
        
        % Create table with dynamic column and row names
        valuesTable = cell2table(valuesMatrix, 'VariableNames', customColNames, 'RowNames', rowNames);
        
        % Display the table
        disp('Converted to MATLAB table with dynamic row and column names:');
        disp(valuesTable);
    else
        disp('No values found in the specified range.');
    end
catch ME
    disp('Error reading data from Google Sheets:');
    disp(ME.message);
end
