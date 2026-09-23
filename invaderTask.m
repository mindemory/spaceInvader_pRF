% function ori_task(subjID, day, start_block, TMSamp, prac_status, powerMate, aperture)
% clearvars -except subjID day start_block TMSamp powerMate prac_status aperture;
clear; close all; clc;
% Created by Mrugank Dake, Curtis Lab, NYU (05/14/2025)
% Eyelink flags:
%               Fixation: XDAT 1
%               Sample:   XDAT 10/11
%               Delay 1:  XDAT 2
%               Delay 2:  XDAT 3
%               Response: XDAT 4
%               Feedback: XDAT 5
%               ITI:      XDAT 6
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
flicker = 1;
subjID = 'MD1219';
% Initialize parameters
% subjID = num2str(subjID, "%02d"); % convert subjID to string


start_block = 1;
end_block = 1;
parameters = loadParameters(subjID);

aperture = 0; % 0: full screen mode, 1: stimulus drawn on aperture


% Check the system running on: currently accepted: syndrome
[ret, hostname] = system('hostname');
if ret ~= 0
    hostname = getenv('HOSTNAME');
end
hostname = strtrim(hostname);

% Initialize PTB and Eyetracking parameters
if strcmp(hostname, 'syndrome') || strcmp(hostname, 'zod') || strcmp(hostname, 'zod.psych.nyu.edu') % Lab iMac is meant for debugging
    thisdev = 'mac';
    addpath(genpath('/Applications/Psychtoolbox')) %% mrugank (01/28/2022): load PTB
    parameters.isDemoMode = true; % set to true if you want the screen to be transparent
    parameters.eyetracker = 0; % set to 0 if there is no eyetracker
    parameters.mocap = 0;
    Screen('Preference','SkipSyncTests', 1)
    
elseif contains(hostname, 'wir2eless.nyu.edu') || contains(hostname, 'MacBookPro') || strcmp(hostname, 'mindemory.local')
    thisdev = 'mac';
    addpath(genpath('/Applications/Psychtoolbox'));
    parameters.isDemoMode = false;
    parameters.eyetracker = 0;
    parameters.mocap = 0;
    Screen('Preference','SkipSyncTests', 1)
else
    disp('Running on unknown device. Psychtoolbox might not be added correctly!')
    return;
end

% Initialize data paths
addpath(genpath('./Stimuli'));
addpath(genpath('./qtmController'));
addpath(genpath('./audionumbers'));

% numFiles = 12;
% audioData = cell(1, numFiles);
% sampleRates = zeros(1, numFiles);
% 
% for i = 1:numFiles
%     filename = fullfile('audionumbers', sprintf('%d.wav', i));
%     [y, fs] = audioread(filename);
%     audioData{i} = y;
%     sampleRates(i) = fs;
% end

% Initialize screen and peripherals
screen                                       = initScreen(parameters);
[kbx, mbx, parameters]                       = initPeripherals(parameters, thisdev);
if parameters.mocap
    parameters.mocapHandle                   = initMocap;
end

%% Load up the images
disp('Loading up Stimuli ...')
numAliens                                     = 20;
% Load up and create alien textures
alienTextures                                 = cell(1, numAliens);
for i                                         = 1:numAliens
    filename                                  = sprintf('Stimuli/alien%02d.png', i);
    img                                       = imread(filename);
    alienTextures{i}                          = Screen('MakeTexture', screen.win, img);
end
% % Load up and crate spaceship texture
% spaceshipImg                                  = imread('Stimuli/spaceship.png');
% spaceshipTexture                              = Screen('MakeTexture', screen.win, spaceshipImg);
% 
% % Space ship anchored at
% spaceship_x                                   = screen.xCenter;
% spaceship_y                                   = round(screen.screenYpixels * (1 - parameters.marginForSpaceship)) - parameters.spaceshipSize;

% Choose alien for this run
badAlienIdx                                   = randi(numAliens);
goodAlienIdx                                  = setdiff(1:numAliens, badAlienIdx);
badAlien                                      = alienTextures{badAlienIdx};
goodAliens                                    = alienTextures(goodAlienIdx);

explosionAngles                               = rand(1, parameters.explodenParticles) * 2 * pi;
explosionSpeeds                               = rand(1, parameters.explodenParticles) * 5 + 5;


vertSpaceToUse                                = screen.screenYpixels * 0.9;
vertSpaceEliminated                           = screen.screenYpixels * 0.1;

barWidth                                      = round(vertSpaceToUse / parameters.nbars);
horiVertDifference                            = screen.screenXpixels -  vertSpaceToUse;

% Get the stimulus Size and the alienSize
stimSize                                      = min(barWidth, round(vertSpaceToUse / parameters.aliensPerBar));
stimBufferSize                                = stimSize * (1 - parameters.alienAreaPerStim);
alienSize                                     = stimSize * parameters.alienAreaPerStim;
parameters.alienSize                          = alienSize;

% Keep the bar positions handy (Vertial bars for L2R and R2L; Horizontal
% bars for T2D and D2T)
verticalBarXs                                 = round(linspace(horiVertDifference/2 + barWidth/2, ...
                                                               screen.screenXpixels - horiVertDifference/2 - barWidth/2, ...
                                                               parameters.nbars));
horizontalBarYs                               = round(linspace(vertSpaceEliminated/2 + barWidth/2, ...
                                                               screen.screenYpixels - vertSpaceEliminated/2  -barWidth/2, ...
                                                               parameters.nbars));
% Keep the stimulus positions handy (Vertial bars for L2R and R2L; Horizontal
% bars for T2D and D2T)
verticalBar_alienYs                           = round(linspace((vertSpaceEliminated + stimBufferSize + alienSize)/2, ...
                                                               screen.screenYpixels - (vertSpaceEliminated + stimBufferSize + alienSize)/2, ...
                                                               parameters.aliensPerBar));
horizontalBar_alienXs                         = round(linspace((horiVertDifference + stimBufferSize + alienSize)/2, ...
                                                                screen.screenXpixels - (horiVertDifference + stimBufferSize + alienSize)/2, ...
                                                                parameters.aliensPerBar));
sweepOrders                                   = {'L2R', 'T2B', 'R2L', 'B2T', ...
                                                 'L2R', 'T2B', 'R2L', 'B2T'};
                         %%               
                         
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calibrate the stick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
runCalib = true; % For debugging the the experiment below
if runCalib
    calibrateType                                 = 'HV9';
    goodCalibration                               = false;
    goodValidation                                = false;
    thresholdError                                = 3; % in dva 
    
    % while ~KbCheck  % Loop until any key is pressed
    % %     Get mouse position
    %     [x, y, buttons] = GetMouse(screen.win);
    % %     x = screen.xCenter;
    % %     y = screen.yCenter;
    %     Screen('FillRect', screen.win, 0);
    %     drawTextures(parameters, screen, 'CrossHair', [], [x y])
    %     Screen('Flip', screen.win);
    %     % Fill screen with black
    % end
        
    
    
    % end
    showprompts(screen, 'CalibrateStick')
    WaitSecs(1);
    while ~goodCalibration
        % TO DO: Maybe having discretized calibration is not a great idea,
        % probably worth it doing this for validation
        [calibratePoints, calibrateCoords]        = calibSpaceGun(parameters, screen, badAlien, calibrateType);
        [calibDistance, calibrateCoords_transformed, GunToScreen_transform] ...
                                                  = procrustes(calibratePoints, calibrateCoords);
        if abs(calibDistance)                     < 0.5
            goodCalibration                       = true;
        else
            showprompts(screen, 'BadCalibration')
            WaitSecs(1);
        end
        disp(calibDistance);
    end
    
    showprompts(screen, 'ValidateStick')
    WaitSecs(1);
    while ~goodValidation
        [validatePoints, validateCoords]          = validateSpaceGun(parameters, screen, badAlien, GunToScreen_transform, calibrateType);
    
        validationError                           = mean(pixel2va(validateCoords(:,1), validateCoords(:,2), ...
                                                             calibrateCoords(:,1), calibrateCoords(:,2), ...
                                                             parameters, screen));
        if validationError                        < parameters.alienSize * 2
            goodValidation                        = true;
        else
            showprompts(screen, 'BadValidation')
            WaitSecs(1);
        end
    end
    
    showprompts(screen, 'ValidationAccepted')
end

%% TESTER TASK

% fixed_alien_x = randi(alienXrange);
% fixed_alien_y = randi(alienYrange);
% alien_burst = false;
% 
% 
% % Animation state variables
% exploding = false;
% explosionFrame = 0;
% 
% respawnDelayFrames = 20; % Number of frames to wait after explosion
% respawnCounter = 0;
% 
% alienTextureThis = alienTextures{randi(numAliens)};
% while ~KbCheck  % Loop until any key is pressed
%     % Get mouse position
%     [x, y, buttons] = GetMouse(screen.win);
% 
%     % Fill screen with black
%     Screen('FillRect', screen.win, 0);
% 
%     spaceGundistance = sqrt((x - fixed_alien_x)^2 + (y - fixed_alien_y)^2);
%     
%     
%     % Check if burst should start
%     if ~exploding && spaceGundistance <= parameters.burstRadius
%         exploding = true;
%         explosionFrame = 1;
%     end
% 
%     % Draw alien if not exploding
%     if ~exploding && respawnCounter == 0
%         alienDstRect = CenterRectOnPoint([0 0 parameters.alienSize parameters.alienSize], fixed_alien_x, fixed_alien_y);
%         Screen('DrawTexture', screen.win, alienTextureThis, [], alienDstRect);
%     end
% 
%     % Draw particle burst animation if exploding
%     if exploding
%         for p = 1:parameters.explodenParticles
%             r = explosionSpeeds(p) * explosionFrame;
%             px = fixed_alien_x + cos(explosionAngles(p)) * r;
%             py = fixed_alien_y + sin(explosionAngles(p)) * r;
%             Screen('DrawDots', screen.win, [px; py], 3, [170 66 3], [], 1);
%         end
%         explosionFrame = explosionFrame + 1;
%         if explosionFrame > parameters.explodenFrames
%             exploding = false; % End animation
%             respawnCounter = respawnDelayFrames; % Start a respwan countdown
%         end
%     end
% 
%     % Handle respawn countdown
%     if respawnCounter > 0
%         respawnCounter = respawnCounter - 1;
%         if respawnCounter == 0
%             exploding = false;
%             % Pick new random position for alien
%             fixed_alien_x = randi(alienXrange);
%             fixed_alien_y = randi(alienYrange);
%             % Optionally, randomize angles and speeds for next burst
%             explosionAngles = rand(1, parameters.explodenParticles) * 2 * pi;
%             explosionSpeeds = rand(1, parameters.explodenParticles) * 5 + 5;
%             alienTextureThis = alienTextures{randi(numAliens)};
%         end
%     end
% 
%     % Draw spaceship at bottom center
%     dx = x - spaceship_x;
%     dy = -(y - spaceship_y);
%     Spaceshipangle = atan2d(dx, dy); % atan2d gives angle in degrees
%     
%     % Draw spaceship at bottom center, rotated to point at mouse
%     spaceshipDstRect = CenterRectOnPoint([0 0 parameters.spaceshipSize parameters.spaceshipSize], spaceship_x, spaceship_y);
%     Screen('DrawTexture', screen.win, spaceshipTexture, [], spaceshipDstRect, Spaceshipangle);
%     
%     
% 
%     if spaceGundistance <= parameters.burstRadius
%         alien_burst = true;
%     end
% 
%     % Flip to the screen
%     Screen('Flip', screen.win);
% 
%     % Optional: break if mouse button is pressed
%     if any(buttons)
%         break;
%     end
% end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Start Experiment
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
showprompts(screen, 'RunOnset')


badAlienCoords                                = [];
badAlienTimestamps                            = [];
GunshotCoords                                 = [];
GunshotTimestamps                             = [];

lastGunShot                                   = GetSecs;
WaitSecs(2);

runStartTime                                  = GetSecs;
trial                                         = 1;
gunShotWaitTime                               = 0.2; % Once a gun shot is seen, don't accept another for 100ms

while trial                                   <= parameters.ntrials
    currSweepOrder                            = sweepOrders{trial};                      


    % Fill screen with black
    Screen('FillRect', screen.win, screen.bgcolor);
    drawTextures(parameters, screen, 'FixationCross', screen.white);

    barNum                                    = 1;
    while barNum                              <= parameters.nbars
        barOnset                              = GetSecs;
        
        while GetSecs - barOnset              <= parameters.TRperbar * parameters.TR
            
            if randi(2)                       == 1
                showBadAlien                  = true;
            else
                showBadAlien                  = false;
            end
        
            if showBadAlien
                badAlienPos                   = randi(parameters.aliensPerBar);
                goodAlienPos                  = setdiff(1:parameters.aliensPerBar, badAlienPos);
            end
            goodAliensChosen                  = randperm(numAliens-1, parameters.aliensPerBar);
            newStimuliSetOnset                = GetSecs;

            if strcmp(currSweepOrder, 'L2R')
                alienXs                       = verticalBarXs(barNum) * ones(parameters.aliensPerBar, 1);
                alienYs                       = verticalBar_alienYs;
            elseif strcmp(currSweepOrder, 'R2L')
                alienXs                       = verticalBarXs(parameters.nbars - barNum + 1) * ones(parameters.aliensPerBar, 1);
                alienYs                       = verticalBar_alienYs(end:-1:1);
            elseif strcmp(currSweepOrder, 'T2B')
                alienXs                       = horizontalBar_alienXs;
                alienYs                       = horizontalBarYs(barNum) * ones(parameters.aliensPerBar, 1);
            elseif strcmp(currSweepOrder, 'B2T')
                alienXs                       = horizontalBar_alienXs(end:-1:1);
                alienYs                       = horizontalBarYs(parameters.nbars - barNum + 1) * ones(parameters.aliensPerBar, 1);

            end
            getAlienSampIfFound               = true;
            
            while GetSecs - newStimuliSetOnset <= parameters.timeperStimuliSet 
                [~, ~, keyCode]                           = KbCheck;
                
            
                % Get mouse position                          
                [mouseX, mouseY, buttons]                 = GetMouse(screen.win);
                pointerOrigSpace                          = [mouseX mouseY];
%                 pointerScreenSpace                        = pointerOrigSpace;
                pointerScreenSpace                    = pointerOrigSpace * GunToScreen_transform.T * ...
                                        GunToScreen_transform.b + GunToScreen_transform.c(1, :);
            
                if keyCode(KbName('space'))
%                     drawTextures(parameters, screen, 'CrossHairGunShot', [], pointerScreenSpace)
                    if GetSecs - lastGunShot              > gunShotWaitTime 
                        GunshotCoords                     = [GunshotCoords pointerScreenSpace'];
                        GunshotTimestamps                 = [GunshotTimestamps GetSecs-runStartTime];
                        lastGunShot = GetSecs;                  
                    end
                end
                for i                                     = 1:parameters.aliensPerBar
                    if showBadAlien && i == badAlienPos
                        drawTextures(parameters, screen, 'Alien', [], [alienXs(i) alienYs(i)], badAlien);
                        if getAlienSampIfFound
                            badAlienCoords                = [badAlienCoords [alienXs(i); alienYs(i)]];
                            badAlienTimestamps             = [badAlienTimestamps GetSecs-runStartTime];
                            getAlienSampIfFound           = false;
                        end
                    else
                        drawTextures(parameters, screen, 'Alien', [], [alienXs(i) alienYs(i)], goodAliens{goodAliensChosen(i)});
                    end
                    if GetSecs - lastGunShot < gunShotWaitTime
                        drawTextures(parameters, screen, 'CrossHairGunShot', [], pointerScreenSpace)
                    else
                        drawTextures(parameters, screen, 'CrossHair', [], pointerScreenSpace)
                    end
                end
                Screen('Flip', screen.win);
            end
            Screen('Flip', screen.win);
        end
        barNum = barNum + 1;
        Screen('Flip', screen.win);
    end
    trial = trial + 1;
    Screen('Flip', screen.win);
end

