function drawTextures(parameters, screen, texture_name, color, pos, alienTexture)
% created by Mrugank (05/14/2025):
% drawTexture can be called with texture_name to draw either a fixation
% cross or a stimulus at periphery. color argument is optional. Default
% color for either stimulus is white.

switch texture_name
    % Drawing Aperture
    case 'Aperture'
        % Get pixel width and height for inner and outer circle based of VA
        r_pix_aperture = va2pixel(parameters, screen, parameters.apertureSize);
        
        % Coordinates for outer circle
        baseRect_aperture = [0 0 r_pix_aperture*2 r_pix_aperture*2];
        maxDiameter_aperture = ceil(max(baseRect_aperture) * 1.1);
        centeredRect_aperture = CenterRectOnPoint(baseRect_aperture, screen.xCenter, screen.yCenter);
  
        % Draw Aperture
        Screen('FillRect', screen.win, screen.black);
        Screen('FillOval', screen.win, screen.grey, centeredRect_aperture, maxDiameter_aperture)
    
    % Drawing Fixation Cross
    case 'FixationCross'
        if nargin < 4
            fixcolor = screen.white;
        else
            fixcolor = color;
        end
        % Get pixel width and height for inner and outer circle based of VA
        r_pix_outer = va2pixel(parameters, screen, parameters.fixationSizeDeg);
        r_pix_inner = va2pixel(parameters, screen, parameters.fixationSizeDeg/3);
        
        % Coordinates for fixation cross
        xCoords = [-r_pix_outer r_pix_outer 0 0];
        yCoords = [0 0 -r_pix_outer r_pix_outer];
        allCoords = [xCoords; yCoords];
        
        % Coordinates for outer circle
        baseRect_outer = [0 0 r_pix_outer*2 r_pix_outer*2];
        maxDiameter_outer = ceil(max(baseRect_outer) * 1.1);
        centeredRect_outer = CenterRectOnPoint(baseRect_outer, screen.xCenter, screen.yCenter);
        
        % Coordinates for inner circle
        baseRect_inner = [0 0 r_pix_inner*2 r_pix_inner*2];
        maxDiameter_inner = ceil(max(baseRect_inner) * 1.1);
        centeredRect_inner = CenterRectOnPoint(baseRect_inner, screen.xCenter, screen.yCenter);
        
        % Draw Fixation cross
        Screen('FillOval', screen.win, parameters.fixationColor, centeredRect_outer, maxDiameter_outer);
        if strcmp(computer, 'GLNXA64')
            Screen('DrawLines', screen.win, allCoords, round(r_pix_inner*1.5), ...
                fixcolor, [screen.xCenter screen.yCenter], 2); % 2 is for smoothing
        end
        Screen('FillOval', screen.win, parameters.fixationColor, centeredRect_inner, maxDiameter_inner);
        Screen('Flip', screen.win);
    
    % Drawing Fixation Cross
    case 'FixationCrossITI'
        if nargin < 4
            fixcolor = screen.white;
        else
            fixcolor = color;
        end
        % Get pixel width and height for inner and outer circle based of VA
        r_pix_outer = va2pixel(parameters, screen, parameters.fixationSizeDeg);
        r_pix_inner = va2pixel(parameters, screen, parameters.fixationSizeDeg/3);
        
        % Coordinates for fixation cross
        xCoords = [-r_pix_outer r_pix_outer 0 0];
        yCoords = [0 0 -r_pix_outer r_pix_outer];
        allCoords = [xCoords; yCoords];
        
        % Coordinates for outer circle
        baseRect_outer = [0 0 r_pix_outer*2 r_pix_outer*2];
        maxDiameter_outer = ceil(max(baseRect_outer) * 1.1);
        centeredRect_outer = CenterRectOnPoint(baseRect_outer, screen.xCenter, screen.yCenter);
        
        % Coordinates for inner circle
        baseRect_inner = [0 0 r_pix_inner*2 r_pix_inner*2];
        maxDiameter_inner = ceil(max(baseRect_inner) * 1.1);
        centeredRect_inner = CenterRectOnPoint(baseRect_inner, screen.xCenter, screen.yCenter);
        
        % Draw Fixation cross
        Screen('FillOval', screen.win, (screen.black + screen.grey)/2, centeredRect_outer, maxDiameter_outer);
        if strcmp(computer, 'GLNXA64')
            Screen('DrawLines', screen.win, allCoords, round(r_pix_inner*1.5), ...
                fixcolor, [screen.xCenter screen.yCenter], 2); % 2 is for smoothing
        else
            Screen('DrawLines', screen.win, allCoords, round(r_pix_inner*1.5), ...
                fixcolor, [screen.xCenter screen.yCenter]); % 2 is for smoothing
        end
        Screen('FillOval', screen.win, (screen.black + screen.grey)/2, centeredRect_inner, maxDiameter_inner);
        Screen('Flip', screen.win);
        
    % Drawing Stimulus
    case 'Stimulus'
        baseRect = [0 0 dotSize*2 dotSize*2];
        maxDiameter = ceil(max(baseRect) * 1.1);
        centeredRect = CenterRectOnPointd(baseRect, dotCenter(1), dotCenter(2));
        Screen('FillOval', screen.win, color, centeredRect, maxDiameter);

        
        
    case 'CrossHair'
        % Get pixel width and height for inner and outer circle based of VA
        r_pix_crossHairDiameter = parameters.alienSize * parameters.crossHairRatio;
        r_pix_outerCircle = r_pix_crossHairDiameter;
        r_pix_innerCircle = r_pix_crossHairDiameter * 0.6;
        arm_width = r_pix_outerCircle - r_pix_innerCircle;
        arm_pix_out = r_pix_innerCircle + arm_width * 0.5;
        arm_pix_in = r_pix_innerCircle - arm_width * 0.5;
        
        % Coordinates for fixation cross
        armCoords = [-arm_pix_out  0; -arm_pix_in  0;
                      arm_pix_out  0;  arm_pix_in  0;
                      0  arm_pix_out;  0  arm_pix_in;
                      0 -arm_pix_out;  0 -arm_pix_in];
        allCoords = round(armCoords');

        % Coordinates for outer circle
        baseRect_outer = [0 0 r_pix_outerCircle*2 r_pix_outerCircle*2];
        centeredRect_outer = CenterRectOnPoint(baseRect_outer, pos(1), pos(2));

        % Coordinates for inner circle
        baseRect_inner = [0 0 r_pix_innerCircle*2 r_pix_innerCircle*2];
        centeredRect_inner = CenterRectOnPoint(baseRect_inner, pos(1), pos(2));
        
        Screen('FrameOval', screen.win, parameters.crosshairColor, centeredRect_outer, 3);
        Screen('FrameOval', screen.win, parameters.crosshairColor, centeredRect_inner, 2);
        Screen('DrawLines', screen.win, allCoords, 3, parameters.crosshairColor, pos);
    case 'CrossHairGunShot'
        % Get pixel width and height for inner and outer circle based of VA
        r_pix_crossHairDiameter = parameters.alienSize * parameters.crossHairRatio;
        r_pix_outerCircle = r_pix_crossHairDiameter;
        r_pix_innerCircle = r_pix_crossHairDiameter * 0.6;
        arm_width = r_pix_outerCircle - r_pix_innerCircle;
        arm_pix_out = r_pix_innerCircle + arm_width * 0.5;
        arm_pix_in = r_pix_innerCircle - arm_width * 0.5;
        
        % Coordinates for fixation cross
        armCoords = [-arm_pix_out  0; -arm_pix_in  0;
                      arm_pix_out  0;  arm_pix_in  0;
                      0  arm_pix_out;  0  arm_pix_in;
                      0 -arm_pix_out;  0 -arm_pix_in];
        allCoords = round(armCoords');

        % Coordinates for outer circle
        baseRect_outer = [0 0 r_pix_outerCircle*2 r_pix_outerCircle*2];
        centeredRect_outer = CenterRectOnPoint(baseRect_outer, pos(1), pos(2));

        % Coordinates for inner circle
        baseRect_inner = [0 0 r_pix_innerCircle*2 r_pix_innerCircle*2];
        centeredRect_inner = CenterRectOnPoint(baseRect_inner, pos(1), pos(2));
        
        Screen('FrameOval', screen.win, parameters.crosshairColor, centeredRect_outer, 3);
        Screen('FrameOval', screen.win, [255 0 0], centeredRect_inner, 2);
        Screen('DrawLines', screen.win, allCoords, 3, [255 0 0], pos);

    case 'Alien'
%         pix_alienSize = va2pixel(parameters, screen, parameters.alienSize);
        alienDstRect  = CenterRectOnPoint([0 0 parameters.alienSize parameters.alienSize], pos(1), pos(2));
        Screen('DrawTexture', screen.win, alienTexture, [], alienDstRect);

    
end