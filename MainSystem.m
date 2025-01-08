% Read Files
tic;  
createPath;
% Preparations
preparation;
elapsedTime = toc;
disp('Time in Seconds:');
disp(elapsedTime);
%% Calculate emissions by specific steps
tic;   
runningSteps;
elapsedTime = toc;
disp('Time in Seconds:');
disp(elapsedTime);
%% Refresh NZO Token
accessToken = runRefreshToken(clientID, clientSecret, refreshToken);
