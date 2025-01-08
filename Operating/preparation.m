TargetYear = 2050;
BaseYear = 2017;
ScenarioNumber = 19;
Years = TargetYear-BaseYear+1;
ScenariosAndValues = readtable("The Three Scenarios.xlsx",'Sheet','Scenarios','Range','A1:I20','ReadRowNames',true,'ReadVariableNames',true);
ReadValues;
nzo_Nucler;
TechnologicalImprovements;
RowNames = {'Population Growth', 'Increase In Electricity Per Capita', 'Increase in Desalinated Water', 'Reducing Beef Consumption', 'Preventing Food Loss', 'Change In Energy Consumption From Renewable Energies', 'Electricity Production by Natural Gas','Electricity Saving', 'Waste Minimization','Recycle Waste', '11', 'Reducing Mileage', 'Transition To Public Transportation', 'Transition to Electric Car', 'Transition to Electric Van', 'Transition to Electric Truck', 'Transition to Electric Bus','18', 'Water Saving'};
AllButOneAnalysis = array2table(zeros(height(ScenariosAndValues),9));
AllButOneAnalysis.Properties.RowNames = RowNames;
AllButOneAnalysis.Properties.VariableNames = {'Emissions', 'Emissions - Global', 'Emissions - Local', 'Water', 'Water - Global', 'Water - Local', 'Area', 'Area - Global', 'Area - Local'};
OnlyOneAnalysis = array2table(zeros(height(ScenariosAndValues),9));
OnlyOneAnalysis.Properties.RowNames = RowNames;
OnlyOneAnalysis.Properties.VariableNames = {'Emissions', 'Emissions - Global', 'Emissions - Local', 'Water', 'Water - Global', 'Water - Local', 'Area', 'Area - Global', 'Area - Local'};

PopulationGrowth = {0, 0.45, 0.9};
ElectricityPerCapita = {0, 0.2, 0.41};
DesalinatedWater = {0,1.32,2.64};
%% population data
population  = array2table(zeros(4,34));
RowNames = {'Num','Years', 'Israel population', 'Palestinian Authority population'};
pop.Properties.RowNames = RowNames;

for i =1:34
    population(1,i) = {i};
    population(2,i) = {i+2016};
    population(3,i) = {8.8*1.0192^(i-1)};
    population(4,i) = {4.455*1.0223^(i-1)};

end

%% NZO Pre Data
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
beep;

% Open the URL in the default web browser
web(authURL, '-browser');

%% Receiving Tokens
getAuthCode();

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

% Get the current time and display it
currentTime = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss');
disp(['Tokens obtained successfully at: ', char(currentTime)]);

% Save the current time to the workspace
assignin('base', 'lastTokenTime', currentTime);

beep;
