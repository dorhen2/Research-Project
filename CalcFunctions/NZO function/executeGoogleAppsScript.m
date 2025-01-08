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