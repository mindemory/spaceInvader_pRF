function goodCalibration                           = dispCalibrationResult(parameters, screen, ...
                                                                           calibratePoints, calibrateCoords, ...
                                                                           validateCoords, thresholdError)

% Align the calibrateCoords to calibratePoints
[d, calibrateCoords_transformed, transform]       = procrustes(calibratePoints, calibrateCoords);
% Apply scaling and rotation
validateCoords_transformed                        = validateCoords * transform.T * transform.b + transform.c(1, :);

validateError                                     = NaN(size(calibratePoints,1),1);
for ptIdx                                         = 1:size(calibratePoints, 1)
    validateError(ptIdx)                          = pixel2va(validateCoords_transformed(ptIdx, 1), validateCoords_transformed(ptIdx, 2), ...
                                                             calibrateCoords_transformed(ptIdx, 1), calibrateCoords_transformed(ptIdx, 2), ...
                                                             parameters, screen);
end
% validateError                                     = pixel2va(gx, gy, tarx, tary, parameters, screen)

% validateError = sqrt(sum((calibrateCoords_transformed - validateCoords_transformed).^2, 2));
colors                                            = zeros(length(validateError), 3);
for i                                             = 1:length(validateError)
    if validateError(i)                           <= thresholdError
        colors(i,:)                               = [0 255 0];   % Green
    else
        colors(i,:)                               = [255 0 0];   % Red
    end
end

while true  % Loop until calibration is completed or Esc is pressed
    [~, ~, keyCode]                               = KbCheck; % Check keyboard
    if keyCode(KbName('ESCAPE'))
        break;
    elseif keyCode(KbName('A'))  % Accept
        goodCalibration = true;
        message = 'Calibration Accepted. Press any key to exit.';
        break;
    elseif keyCode(KbName('Q'))  % Redo
        goodCalibration = false;
        message = 'Calibration Rejected. Press any key to exit.';
        break;
    end
    % Fill screen with black and draw a fixation cross
    Screen('FillRect', screen.win, screen.bgcolor);

    Screen('DrawDots', screen.win, calibrateCoords_transformed', 30, [255 255 255], [], 1);

%     Screen('DrawDots', screen.win, round(validateCoords_transformed'), 5, [255 0 0], [], 1);
    for i = 1:size(validateCoords_transformed,1)
        Screen('DrawDots', screen.win, validateCoords_transformed(i,:)', 10, colors(i,:), [], 1);
    end
    DrawFormattedText(screen.win, 'Press A to accept calibration, Q to redo', 'center', 'center', [255 255 255]);

    Screen('Flip', screen.win);
end








end