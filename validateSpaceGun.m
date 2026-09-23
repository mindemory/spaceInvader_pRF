function [validatePoints, validateCoords]     = validateSpaceGun(parameters, screen, badAlien, GunToScreen_transform, calibrateType)

if nargin                                     < 4
    calibrateType                             = 'HV12';
end

calibrateScreenRatio                          = 0.2;

if strcmp(calibrateType, 'HV12')
    validatePoints                           = [screen.screenXpixels/2,                          screen.screenYpixels*calibrateScreenRatio;
                                                 screen.screenXpixels/2,                          screen.screenYpixels*(1-calibrateScreenRatio);
                                                 screen.screenXpixels*calibrateScreenRatio,       screen.screenYpixels/2;
                                                 screen.screenXpixels*(1-calibrateScreenRatio),   screen.screenYpixels/2;
                                                 screen.screenXpixels*calibrateScreenRatio,       screen.screenYpixels*calibrateScreenRatio;
                                                 screen.screenXpixels*(1-calibrateScreenRatio),   screen.screenYpixels*calibrateScreenRatio;
                                                 screen.screenXpixels*calibrateScreenRatio,       screen.screenYpixels*(1-calibrateScreenRatio);
                                                 screen.screenXpixels*(1-calibrateScreenRatio),   screen.screenYpixels*(1-calibrateScreenRatio);
                                                 screen.screenXpixels*calibrateScreenRatio*2,     screen.screenYpixels*calibrateScreenRatio*2;
                                                 screen.screenXpixels*calibrateScreenRatio*2,     screen.screenYpixels*(1-calibrateScreenRatio*2);
                                                 screen.screenXpixels*(1-calibrateScreenRatio*2), screen.screenYpixels*calibrateScreenRatio*2;
                                                 screen.screenXpixels*(1-calibrateScreenRatio*2), screen.screenYpixels*(1-calibrateScreenRatio*2)]; 
elseif strcmp(calibrateType, 'HV9')
    validatePoints                           = [screen.screenXpixels/2,                          screen.screenYpixels*calibrateScreenRatio;
                                                 screen.screenXpixels/2,                          screen.screenYpixels*(1-calibrateScreenRatio);
                                                 screen.screenXpixels*calibrateScreenRatio,       screen.screenYpixels/2;
                                                 screen.screenXpixels*(1-calibrateScreenRatio),   screen.screenYpixels/2;
                                                 screen.screenXpixels*calibrateScreenRatio,       screen.screenYpixels*calibrateScreenRatio;
                                                 screen.screenXpixels*(1-calibrateScreenRatio),   screen.screenYpixels*calibrateScreenRatio;
                                                 screen.screenXpixels*calibrateScreenRatio,       screen.screenYpixels*(1-calibrateScreenRatio);
                                                 screen.screenXpixels*(1-calibrateScreenRatio),   screen.screenYpixels*(1-calibrateScreenRatio); 
                                                 screen.screenXpixels/2,                          screen.screenYpixels/2];
end

validateCounter                               = 1;
validatePointsShuff                           = validatePoints; %(randperm(size(calibratePoints, 1)), :);

exploding                                     = false;
explodeAngles                                 = parameters.explodeAngles(randperm(numel(parameters.explodeAngles)));
explodeSpeeds                                 = parameters.explodeSpeeds(randperm(numel(parameters.explodeSpeeds)));
respawnCounter                                = 0;
validateCoords                                = NaN(size(validatePoints));
lockPosition                                  = false;


% Play the sound and block execution until it finishes
% player = audioplayer(audioData{calibLocIdx(calibrateCounter)}, sampleRates(calibLocIdx(calibrateCounter)));
% playblocking(player);
while true  % Loop until calibration is completed or Esc is pressed
    [~, ~, keyCode]                           = KbCheck; % Check keyboard
    if keyCode(KbName('ESCAPE'))
        break;
    end

    % Get location
    % Check whether to use mocap
    if parameters.mocap
          pointerOrigSpace = qtm_getGunPos(parameters.mocapHandle);
    else
        % Ue mouse instead (for debugging)
        [mouseX, mouseY, ~]               = GetMouse(screen.win);
        pointerOrigSpace                  = [mouseX mouseY];
    end
    
    pointerScreenSpace                    = pointerOrigSpace * GunToScreen_transform.T * ...
                                            GunToScreen_transform.b + GunToScreen_transform.c(1, :);

    % Fill screen with black and draw a fixation cross
    Screen('FillRect', screen.win, screen.bgcolor);
    drawTextures(parameters, screen, 'FixationCross', screen.black);
    

    if validateCounter                       > size(validatePointsShuff, 1)
        break;
    end

    if validateCounter                        <= size(validatePoints, 1)
        alien_x                               = validatePointsShuff(validateCounter, 1);
        alien_y                               = validatePointsShuff(validateCounter, 2);
    end

    if keyCode(KbName('space'))
        lockPosition                          = true;
        validateCoords(validateCounter, :)    = pointerScreenSpace;
    end

    % Check if burst should start
    if ~exploding && lockPosition
        exploding                             = true;
        explosionFrame                        = 1;
        lockPosition                          = false;
    end

    % Draw alien if not exploding
    if ~exploding && respawnCounter           == 0
        drawTextures(parameters, screen, 'Alien', [], [alien_x alien_y], badAlien);  
        drawTextures(parameters, screen, 'CrossHair', [], pointerScreenSpace)
    end

    % Draw particle burst animation if exploding
    if exploding
        for p                                = 1:parameters.explodenParticles
            r                                = explodeSpeeds(p) * explosionFrame;
            px                               = alien_x + cos(explodeAngles(p)) * r;
            py                               = alien_y + sin(explodeAngles(p)) * r;
            Screen('DrawDots', screen.win, [px; py], 3, [170 66 3], [], 1);
        end
        explosionFrame                       = explosionFrame + 1;
        if explosionFrame                    > parameters.explodenFrames
            exploding                        = false; % End animation
            respawnCounter                   = parameters.respawnDelayFrames; % Start a respwan countdown
        end
        drawTextures(parameters, screen, 'CrossHair', [], [alien_x alien_y])
    end

    % Handle respawn countdown
    if respawnCounter                        > 0
        respawnCounter                       = respawnCounter - 1;
        if respawnCounter                    == 0
            
            exploding                        = false;
            validateCounter                 = validateCounter + 1;
            % Randomize angles and speeds for next burst
            explodeAngles                    = parameters.explodeAngles(randperm(numel(parameters.explodeAngles)));
            explodeSpeeds                    = parameters.explodeSpeeds(randperm(numel(parameters.explodeSpeeds)));
%             if calibrateCounter              <= size(calibratePointsShuff, 1)
%                 player = audioplayer(audioData{calibLocIdx(calibrateCounter)}, sampleRates(calibLocIdx(calibrateCounter)));
%                 playblocking(player);
%             end
            
        end
    end
    % Flip to the screen
    Screen('Flip', screen.win);
end
Screen('Flip', screen.win);

    
end