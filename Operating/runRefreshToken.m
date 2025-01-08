%% Refresh Token URL
function accessToken = runRefreshToken(clientID, clientSecret, refreshToken)
    % URL for refreshing the token
    tokenURL = 'https://oauth2.googleapis.com/token';

    % Set up options for the HTTP request
    options = weboptions('MediaType', 'application/x-www-form-urlencoded');

    % Make a POST request to refresh the token
    refreshResponse = webwrite(tokenURL, ...
        'client_id', clientID, ...
        'client_secret', clientSecret, ...
        'refresh_token', refreshToken, ...
        'grant_type', 'refresh_token', options);

    % Extract the new access token from the response
    accessToken = refreshResponse.access_token;

    % Display success message and the new access token
    disp('Access token refreshed successfully.');
    disp(accessToken);
end
