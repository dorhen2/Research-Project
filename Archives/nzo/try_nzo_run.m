% Main script
% Check if DataBase exists
% Define parameters for execution
params = {
        'MOD', {'scenarios-input!C3:E3', DataBase.InstalledCapacityForOutsideMod{2:4, 'MOD'}'};
        'M.O.E 1', {'scenarios-input!C5:E5', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 1'}'};
        'M.O.E 2', {'scenarios-input!C7:E7', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 2'}'};
        'BAU', {'scenarios-input!C9:E9', DataBase.InstalledCapacityForOutsideMod{2:4, 'BAU'}'};
        'ADV', {'scenarios-input!C11:E11', DataBase.InstalledCapacityForOutsideMod{2:4, 'ADV'}'};
        'ADV+NUC', {'scenarios-input!C13:E13', DataBase.InstalledCapacityForOutsideMod{2:4, 'ADV+NUC'}'};
        'M.O.E 3', {'scenarios-input!C15:E15', DataBase.InstalledCapacityForOutsideMod{2:4, 'M.O.E 3'}'};
    };

    % Loop through parameters and call the function
for i = 1:size(params, 1)
        valueColumn = params{i, 1};
        ranges = params{i, 2};
        writeToGoogleSheets(sheetID, accessToken, ranges, valueColumn, DataBase);
end


% Function for writing to Google Sheets
function writeToGoogleSheets(sheetID, accessToken, ranges, valueColumn, DataBase)
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
        catch ME
            fprintf('Error writing to range %s in Google Sheets: %s\n', range, ME.message);
        end
    end

    % Write Demand values to Google Sheets
    rangeDemand = 'Demand!B21:B51';
    numRows = 31;
    valuesToWriteDemand = arrayfun(@(x) {DataBase.InstalledCapacityForOutsideMod{'Grow rate to NZO model', valueColumn}}, 1:numRows, 'UniformOutput', false);
    request_body_demand = jsonencode(struct('range', rangeDemand, 'majorDimension', 'ROWS', 'values', {valuesToWriteDemand}));
    urlDemand = sprintf('https://sheets.googleapis.com/v4/spreadsheets/%s/values/%s?valueInputOption=USER_ENTERED', sheetID, rangeDemand);

    try
        webwrite(urlDemand, request_body_demand, options);
    catch ME
        fprintf('Error writing to Demand range in Google Sheets: %s\n', ME.message);
    end
    % Access Token received after authentication
    access_token = 'ya29.a0AeDClZD58le2V4EpauTS9IoEMUm3Z26DZq7XwF-0G927HxuE437ye0qGcdhQZyw5P3IPRQgeUyNhETnu18ApgPHlc7SSyae-a1rWuxdig6hr-L07MjXW7aHQyHjcaSgT6xLZe-MFhnGvTykRroudsyJUPEB2ww36-Or8z0GUaCgYKAfYSARISFQHGX2MiNNXF_W4NjjYS3AuEX90cWg0175';
    
    % Google Apps Script's Script ID
    script_id = '1BQg_sOhONPYYGIrsUcZWIY6sFv_eNjQGc_AHE1RrnJbpLKP2yp0DtyDb';
    
    % URL for API request to execute the script
    url = ['https://script.googleapis.com/v1/scripts/' script_id ':run'];
   
    % JSON request body to call the function "calculateScenariosAndCosts" in devMode
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
        disp('Error executing calculateScenariosAndCosts script:');
        disp(ME.message);
    end

        





end
