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
