function [calibratePoints, pointerCoords]     = calibSpaceGun(parameters, screen, badAlien, calibrateType)

if nargin                                     < 4
    calibrateType                             = 'HV12';
end

calibrateScreenRatio                          = 0.2;

% TODO(cleanup): point grid is duplicated in calibSpaceGun/validateSpaceGun; HV12 branch is unused (invaderTask uses HV9)
if strcmp(calibrateType, 'HV12')
    calibratePoints                           = [screen.screenXpixels/2,                          screen.screenYpixels*calibrateScreenRatio;
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
    calibratePoints                           = [screen.screenXpixels/2,                          screen.screenYpixels*calibrateScreenRatio;
                                                 screen.screenXpixels/2,                          screen.screenYpixels*(1-calibrateScreenRatio);
                                                 screen.screenXpixels*calibrateScreenRatio,       screen.screenYpixels/2;
                                                 screen.screenXpixels*(1-calibrateScreenRatio),   screen.screenYpixels/2;
                                                 screen.screenXpixels*calibrateScreenRatio,       screen.screenYpixels*calibrateScreenRatio;
                                                 screen.screenXpixels*(1-calibrateScreenRatio),   screen.screenYpixels*calibrateScreenRatio;
                                                 screen.screenXpixels*calibrateScreenRatio,       screen.screenYpixels*(1-calibrateScreenRatio);
                                                 screen.screenXpixels*(1-calibrateScreenRatio),   screen.screenYpixels*(1-calibrateScreenRatio); 
                                                 screen.screenXpixels/2,                          screen.screenYpixels/2];
end

% TODO(cleanup): old alternate point grid, kept for reference
% if strcmp(calibrateType, 'HV12')
%     calibratePoints                           = [screen.screenXpixels/2,                          screen.screenYpixels*calibrateScreenRatio;
%                                                  screen.screenXpixels/2,                          screen.screenYpixels*(1-calibrateScreenRatio);
%                                                  screen.screenXpixels*calibrateScreenRatio,       screen.screenYpixels/2;
%                                                  screen.screenXpixels*(1-calibrateScreenRatio),   screen.screenYpixels/2;
%                                                  screen.screenXpixels*calibrateScreenRatio,       screen.screenYpixels*calibrateScreenRatio;
%                                                  screen.screenXpixels*(1-calibrateScreenRatio),   screen.screenYpixels*calibrateScreenRatio;
%                                                  screen.screenXpixels*calibrateScreenRatio,       screen.screenYpixels*(1-calibrateScreenRatio);
%                                                  screen.screenXpixels*(1-calibrateScreenRatio),   screen.screenYpixels*(1-calibrateScreenRatio);
%                                                  screen.screenXpixels*calibrateScreenRatio*2,     screen.screenYpixels*calibrateScreenRatio*2;
%                                                  screen.screenXpixels*calibrateScreenRatio*2,     screen.screenYpixels*(1-calibrateScreenRatio*2);
%                                                  screen.screenXpixels*(1-calibrateScreenRatio*2), screen.screenYpixels*calibrateScreenRatio*2;
%                                                  screen.screenXpixels*(1-calibrateScreenRatio*2), screen.screenYpixels*(1-calibrateScreenRatio*2)]; 
% elseif strcmp(calibrateType, 'HV9')
%     calibratePoints                           = [0,                                               0;
%                                                  screen.screenXpixels/2,                          0;
%                                                  screen.screenXpixels,                            0;
%                                                  0,                                               screen.screenYpixels/2;
%                                                  screen.screenXpixels/2,                          screen.screenYpixels/2;
%                                                  screen.screenXpixels,                            screen.screenYpixels/2;
%                                                  0,                                               screen.screenYpixels;
%                                                  
%                                                  screen.screenXpixels*calibrateScreenRatio,       screen.screenYpixels*calibrateScreenRatio;
%                                                  screen.screenXpixels*(1-calibrateScreenRatio),   screen.screenYpixels*calibrateScreenRatio;
%                                                  screen.screenXpixels*calibrateScreenRatio,       screen.screenYpixels*(1-calibrateScreenRatio);
%                                                  screen.screenXpixels*(1-calibrateScreenRatio),   screen.screenYpixels*(1-calibrateScreenRatio)]; 
%                                                  %[screen.screenXpixels/2,                          screen.screenYpixels/2;
%     calibLocIdx                               = [2 8 4 6 1 3 7 9];
% end

calibrateCounter                              = 1;
calibratePointsShuff                          = calibratePoints; %(randperm(size(calibratePoints, 1)), :);

exploding                                     = false;
explodeAngles                                 = parameters.explodeAngles(randperm(numel(parameters.explodeAngles)));
explodeSpeeds                                 = parameters.explodeSpeeds(randperm(numel(parameters.explodeSpeeds)));
respawnCounter                                = 0;
pointerCoords                                 = NaN(size(calibratePoints));
lockPosition                                  = false;


while true  % Loop until calibration is completed or Esc is pressed
    [~, ~, keyCode]                           = KbCheck; % Check keyboard
    if keyCode(KbName('ESCAPE'))
        break;
    end
    % Fill screen with black and draw a fixation cross
    Screen('FillRect', screen.win, screen.bgcolor);
    drawTextures(parameters, screen, 'FixationCross', screen.black);
    

    if calibrateCounter                       > size(calibratePointsShuff, 1)
        break;
    end

    if calibrateCounter                       <= size(calibratePoints, 1)
        alien_x                               = calibratePointsShuff(calibrateCounter, 1);
        alien_y                               = calibratePointsShuff(calibrateCounter, 2);
    end

    if keyCode(KbName('space'))
        % Check whether to use mocap
        if parameters.mocap
%             TODO(cleanup): older averaging / stability-check approaches below
%             gunPos                           = NaN(10, 2);
%             for i = 1:10
%                 gunPos(i, :)                       = qtm_getGunPos(parameters.mocapHandle);
%             end
%             pointerX = mean(gunPos(:, 1), "all", "omitnan");
%             pointerY = mean(gunPos(:, 2), "all", "omitnan");
              gunPos = qtm_getGunPos(parameters.mocapHandle);
              pointerX = gunPos(1);
              pointerY = gunPos(2);
%             prevGunPos                        = zeros(10, 2);
%             stableGun                         = false;
%             while ~stableGun
%                 currentGunPos                 = qtm_getGunPos(parameters.mocapHandle);
%                 prevGunPos                    = circshift(prevGunPos, -1);
%                 prevGunPos(end, :)            = currentGunPos;
% 
%                 % Calculate Euclidean distance between current and previous positions
%                 gunPosdiffs = vecnorm(diff(prevGunPos), 2, 2);
%             
%                 % Check stability condition
%                 if all(gunPosdiffs < 1e-1)
%                     stableGun = true;
%                     pointerX = mean(prevGunPos(:,1));
%                     pointerY = mean(prevGunPos(:,2));
%                 end
%             
% %                 prevPos = gunPos;
%                 pause(0.01);
%             end
        else
            % Ue mouse instead (for debugging)
            [pointerX, pointerY, ~]               = GetMouse(screen.win);
        end
        lockPosition                          = true;
        pointerCoords(calibrateCounter, :)    = [pointerX, pointerY];
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
    end

    % Draw particle burst animation if exploding
    % TODO(cleanup): explosion animation is duplicated in calibSpaceGun/validateSpaceGun
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
            calibrateCounter                 = calibrateCounter + 1;
            % Randomize angles and speeds for next burst
            explodeAngles                    = parameters.explodeAngles(randperm(numel(parameters.explodeAngles)));
            explodeSpeeds                    = parameters.explodeSpeeds(randperm(numel(parameters.explodeSpeeds)));
            
        end
    end
    % Flip to the screen
    Screen('Flip', screen.win);
end
Screen('Flip', screen.win);

    
end