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
