function getAuthCode()
    % Create a figure for the user interface
    fig = uifigure('Name', 'Authorization Code Input', 'Position', [100, 100, 400, 150]);
    
    % Add a label to guide the user
    uilabel(fig, ...
        'Text', 'Please enter the Authorization Code:', ...
        'Position', [20, 90, 360, 20], ...
        'HorizontalAlignment', 'left');
    
    % Add an edit field for text input
    txtField = uieditfield(fig, 'text', ...
        'Position', [20, 60, 360, 22]);

    % Add a button to submit the input
    uibutton(fig, 'push', ...
        'Text', 'Submit', ...
        'Position', [150, 20, 100, 30], ...
        'ButtonPushedFcn', @(btn, event) saveAndResume(txtField.Value, fig));
    
    % Pause script execution until user clicks Submit
    uiwait(fig);
end

function saveAndResume(input, fig)
    % Save the input to the base workspace
    assignin('base', 'authCode', input);
    
    % Resume script execution
    uiresume(fig);
    
    % Close the user interface
    close(fig);
end
