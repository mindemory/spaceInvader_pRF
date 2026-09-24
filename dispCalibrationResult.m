function [accepted, valErrDva]                    = dispCalibrationResult(parameters, screen, ...
                                                                           validatePoints, validateCoords, thresholdDva)
% Shows the validation result and asks the experimenter to accept it.
% validatePoints: true alien locations (screen pixels)
% validateCoords: pointer locations at each shot, already mapped to screen
%                 space with the gun-to-screen transform
% thresholdDva:   per-point error (dva) below which a point is drawn green
% Returns accepted (A = accept, Q or ESC = redo) and per-point error in dva.

valErrDva                                         = pixel2va(validateCoords(:, 1), validateCoords(:, 2), ...
                                                             validatePoints(:, 1), validatePoints(:, 2), ...
                                                             parameters, screen);

colors                                            = zeros(length(valErrDva), 3);
for i                                             = 1:length(valErrDva)
    if valErrDva(i)                               <= thresholdDva
        colors(i,:)                               = [0 255 0];   % Green
    else
        colors(i,:)                               = [255 0 0];   % Red
    end
end
message                                           = sprintf(['Mean validation error: %.2f dva (max %.2f)\n\n' ...
                                                             'Press A to accept calibration, Q to redo'], ...
                                                            mean(valErrDva), max(valErrDva));

KbReleaseWait;
while true
    [~, ~, keyCode]                               = KbCheck; % Check keyboard
    if keyCode(KbName('A'))  % Accept
        accepted                                  = true;
        break;
    elseif keyCode(KbName('Q')) || keyCode(KbName('ESCAPE'))  % Redo
        accepted                                  = false;
        break;
    end
    Screen('FillRect', screen.win, screen.bgcolor);

    % Targets in white, responses in green/red joined to their target
    Screen('DrawDots', screen.win, validatePoints', 30, [255 255 255], [], 1);
    for i                                         = 1:size(validateCoords, 1)
        Screen('DrawLine', screen.win, colors(i,:), validatePoints(i, 1), validatePoints(i, 2), ...
                                                    validateCoords(i, 1), validateCoords(i, 2), 2);
        Screen('DrawDots', screen.win, validateCoords(i,:)', 10, colors(i,:), [], 1);
    end
    DrawFormattedText(screen.win, message, 'center', screen.screenYpixels * 0.05, [255 255 255]); % top, clear of the center target

    Screen('Flip', screen.win);
end
KbReleaseWait;
Screen('Flip', screen.win);
end
