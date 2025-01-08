%% Pre Data
% Client ID and Secret
clientID = '456727067618-7f77buj4r31qrlgq0v0a1m53okn79nsv.apps.googleusercontent.com';
clientSecret = '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';
redirectURI = 'urn:ietf:wg:oauth:2.0:oob'; % ברירת מחדל לדסקטופ
script_id = '1BQg_sOhONPYYGIrsUcZWIY6sFv_eNjQGc_AHE1RrnJbpLKP2yp0DtyDb';

% Authorization URL
authURL = sprintf(['https://accounts.google.com/o/oauth2/auth?', ...
                   'client_id=%s&', ...
                   'redirect_uri=%s&', ...
                   'response_type=code&', ...
                   'scope=https://www.googleapis.com/auth/spreadsheets https://www.googleapis.com/auth/script.projects'], ...
                   clientID, urlencode(redirectURI));

disp('Visit the following URL to authorize the application:');
disp(authURL);

% Open the URL in the default web browser
web(authURL, '-browser');

%% Receiving Tokens

% Authorization Code (שקיבלת)
authCode = '4/1AeanS0YgQptSZVW4zM3Rnt4ZzBnST-Vm-FAMIXVlsPMd4Eb-qjWLZXVxM2o';

% Token URL
tokenURL = 'https://oauth2.googleapis.com/token';

% Request Access Token
options = weboptions('MediaType', 'application/x-www-form-urlencoded');
tokenResponse = webwrite(tokenURL, ...
    'code', authCode, ...
    'client_id', clientID, ...
    'client_secret', clientSecret, ...
    'redirect_uri', redirectURI, ...
    'grant_type', 'authorization_code', options);

% Access and Refresh Tokens
accessToken = tokenResponse.access_token;
refreshToken = tokenResponse.refresh_token;

% New Spreadsheet ID for Google Sheets
sheetID = '1QvEzjJ6e3JSz7u9p1ValkdNwdz3GCWvFspM52yjl_pM';


disp('Tokens obtained successfully');


%% Refresh Token URL
tokenURL = 'https://oauth2.googleapis.com/token';

% חידוש ה-Access Token
options = weboptions('MediaType', 'application/x-www-form-urlencoded');
refreshResponse = webwrite(tokenURL, ...
    'client_id', clientID, ...
    'client_secret', clientSecret, ...
    'refresh_token', refreshToken, ...
    'grant_type', 'refresh_token', options);

% Access Token חדש
accessToken = refreshResponse.access_token;

disp('Access token refreshed successfully.');
disp(accessToken);


