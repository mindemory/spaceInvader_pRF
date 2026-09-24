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
flicker = 1; % TODO(cleanup): unused
subjID = 'MD1219';
% Initialize parameters
% subjID = num2str(subjID, "%02d"); % convert subjID to string

rng('shuffle');
rngState = rng;

start_block = 1;
end_block = 1; % TODO(cleanup): unused, only start_block is run
parameters = loadParameters(subjID);

aperture = 0; % 0: full screen mode, 1: stimulus drawn on aperture % TODO(cleanup): unused, 'Aperture' texture is never drawn


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

elseif contains(hostname, 'wireless.nyu.edu') || contains(hostname, 'MacBookPro') || strcmp(hostname, 'mindemory.local')
    thisdev = 'mac';
    addpath(genpath('/Applications/Psychtoolbox'));
    parameters.isDemoMode = false;
    parameters.eyetracker = 0;
    parameters.mocap = 0;
    Screen('Preference','SkipSyncTests', 1)

elseif contains(hostname, 'kernelmachine')
    thisdev = 'mac';
    addpath(genpath('/Users/mrugank/Documents/MATLAB/Psychtoolbox/Psychtoolbox/'));
    parameters.isDemoMode = true;
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
addpath(genpath('./audionumbers')); % TODO(cleanup): audio files are no longer used by any code

% Initialize screen and peripherals
screen                                       = initScreen(parameters);
runStatus                                    = 'running';
alienTextures                                = {};
try
    [kbx, mbx, parameters]                   = initPeripherals(parameters, thisdev);
    if parameters.mocap
        parameters.mocapHandle               = initMocap;
    end
    data_path                                = fullfile(pwd, 'data', subjID);
    parameters                               = initFiles(parameters, screen, data_path, kbx, start_block);

    %% Load up the images
    disp('Loading up Stimuli ...')
    alienFiles                                    = dir('Stimuli/alien*.png');
    alienFiles                                    = sort({alienFiles.name});
    numAliens                                     = numel(alienFiles);
    % Load up and create alien textures
    alienTextures                                 = cell(1, numAliens);
    for i                                         = 1:numAliens
        img                                       = imread(fullfile('Stimuli', alienFiles{i}));
        alienTextures{i}                          = Screen('MakeTexture', screen.win, img);
    end
    % TODO(cleanup): spaceship is planned (see Tester/ demo) but not drawn yet
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

    % TODO(cleanup): unused, calib/validation use parameters.explodeAngles/explodeSpeeds
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
    parameters.hitRadius                          = alienSize * parameters.hitRadiusRatio; % in pixels

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

    % Everything that gets saved lives in runData
    runData.subjID                                = subjID;
    runData.hostname                              = hostname;
    runData.date                                  = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    runData.rngState                              = rngState;
    runData.alienFiles                            = alienFiles;
    runData.badAlienIdx                           = badAlienIdx;
    runData.goodAlienIdx                          = goodAlienIdx;
    runData.sweepOrders                           = sweepOrders;
    runData.barPositions.verticalBarXs            = verticalBarXs;
    runData.barPositions.horizontalBarYs          = horizontalBarYs;
    runData.barPositions.verticalBar_alienYs      = verticalBar_alienYs;
    runData.barPositions.horizontalBar_alienXs    = horizontalBar_alienXs;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calibrate the stick
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    runCalib = true; % For debugging the the experiment below
    % Identity transform, used as is when calibration is skipped
    GunToScreen_transform                         = struct('T', eye(2), 'b', 1, 'c', [0 0]);
    if runCalib
        calibrateType                                 = 'HV9';
        calibAccepted                                 = false;
        runData.calib.nCalibAttempts                  = 0;
        runData.calib.nValidateAttempts               = 0;

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
        while ~calibAccepted
            showprompts(screen, 'CalibrateStick')
            WaitSecs(1);
            goodCalibration                           = false;
            while ~goodCalibration
                % TO DO: Maybe having discretized calibration is not a great idea,
                % probably worth it doing this for validation
                [calibratePoints, calibrateCoords]    = calibSpaceGun(parameters, screen, badAlien, calibrateType);
                runData.calib.nCalibAttempts          = runData.calib.nCalibAttempts + 1;
                if any(isnan(calibrateCoords(:)))     % ESC was pressed during calibration
                    error('invaderTask:userAbort', 'Calibration aborted by user.');
                end
                [calibDistance, ~, GunToScreen_transform] ...
                                                      = procrustes(calibratePoints, calibrateCoords);
                if abs(calibDistance)                 < 0.5
                    goodCalibration                   = true;
                else
                    showprompts(screen, 'BadCalibration')
                    WaitSecs(1);
                end
                disp(calibDistance);
            end

            showprompts(screen, 'ValidateStick')
            WaitSecs(1);
            [validatePoints, validateCoords]          = validateSpaceGun(parameters, screen, badAlien, GunToScreen_transform, calibrateType);
            runData.calib.nValidateAttempts           = runData.calib.nValidateAttempts + 1;
            if any(isnan(validateCoords(:)))          % ESC was pressed during validation
                error('invaderTask:userAbort', 'Validation aborted by user.');
            end
            [calibAccepted, valErrDva]                = dispCalibrationResult(parameters, screen, validatePoints, validateCoords, ...
                                                                              parameters.validationThreshDva);
            if ~calibAccepted
                showprompts(screen, 'BadValidation')
                WaitSecs(1);
            end
        end

        runData.calib.calibratePoints                 = calibratePoints;
        runData.calib.calibrateCoords                 = calibrateCoords;
        runData.calib.calibDistance                   = calibDistance;
        runData.calib.validatePoints                  = validatePoints;
        runData.calib.validateCoords                  = validateCoords;
        runData.calib.valErrDva                       = valErrDva;
        runData.calib.accepted                        = calibAccepted;

        showprompts(screen, 'ValidationAccepted')
    end
    runData.calib.GunToScreen_transform               = GunToScreen_transform;

    %% TESTER TASK
    % TODO(cleanup): old mouse-driven tester, superseded by calibSpaceGun/validateSpaceGun

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
    % TODO(cleanup): no scanner-trigger wait; bar timing uses GetSecs loops and drifts relative to the TR
    showprompts(screen, 'RunOnset')

    % Preallocate logs (they grow automatically if the estimate is short)
    runDuration                                   = parameters.ntrials * parameters.nbars * parameters.TRperbar * parameters.TR;
    maxSets                                       = ceil(runDuration / parameters.timeperStimuliSet) + parameters.ntrials * parameters.nbars;
    maxFrames                                     = ceil(1.2 * runDuration / screen.ifi);
    maxShots                                      = ceil(runDuration / parameters.gunShotWaitTime);
    % stimLog: one row per stimulus set
    stimLog.sweep                                 = NaN(maxSets, 1);
    stimLog.sweepDir                              = cell(maxSets, 1);
    stimLog.bar                                   = NaN(maxSets, 1);
    stimLog.onset                                 = NaN(maxSets, 1); % first flip of the set
    stimLog.offset                                = NaN(maxSets, 1);
    stimLog.alienIdx                              = NaN(maxSets, parameters.aliensPerBar); % index into alienFiles
    stimLog.alienX                                = NaN(maxSets, parameters.aliensPerBar);
    stimLog.alienY                                = NaN(maxSets, parameters.aliensPerBar);
    stimLog.badPresent                            = false(maxSets, 1);
    stimLog.badPos                                = NaN(maxSets, 1);
    stimLog.badXY                                 = NaN(maxSets, 2);
    stimLog.hit                                   = false(maxSets, 1);
    stimLog.RT                                    = NaN(maxSets, 1);
    % shotLog: one row per accepted gun shot
    shotLog.time                                  = NaN(maxShots, 1);
    shotLog.screenXY                              = NaN(maxShots, 2);
    shotLog.rawXY                                 = NaN(maxShots, 2);
    shotLog.setIdx                                = NaN(maxShots, 1); % stimulus set on screen when shot (0 = blank)
    shotLog.distPix                               = NaN(maxShots, 1); % distance to bad alien
    shotLog.distDva                               = NaN(maxShots, 1);
    shotLog.shotType                              = NaN(maxShots, 1); % 1 = hit, 2 = repeat shot on hit alien, 0 = false alarm
    shotLog.RT                                    = NaN(maxShots, 1);
    % frameLog: one row per flip
    frameLog.time                                 = NaN(maxFrames, 1);
    frameLog.rawXY                                = NaN(maxFrames, 2);
    frameLog.screenXY                             = NaN(maxFrames, 2);
    frameLog.setIdx                               = NaN(maxFrames, 1); % 0 = blank frame
    nSets                                         = 0;
    nShots                                        = 0;
    nFrames                                       = 0;
    visibleSet                                    = 0; % stimulus set currently on screen
    pointerOrigSpace                              = [NaN NaN];
    pointerScreenSpace                            = [NaN NaN];

    escKey                                        = KbName('ESCAPE');
    spaceKey                                      = KbName('space');
    lastGunShot                                   = GetSecs;
    WaitSecs(2);

    runStartTime                                  = GetSecs;
    runData.runStartTime                          = runStartTime;
    trial                                         = 1;
    gunShotWaitTime                               = parameters.gunShotWaitTime; % Once a gun shot is seen, don't accept another for 200ms

    while trial                                   <= parameters.ntrials
        currSweepOrder                            = sweepOrders{trial};


        % Fill screen with black
        Screen('FillRect', screen.win, screen.bgcolor);
        drawTextures(parameters, screen, 'FixationCross', screen.white);

        barNum                                    = 1;
        while barNum                              <= parameters.nbars
            barOnset                              = GetSecs;

            while GetSecs - barOnset              <= parameters.TRperbar * parameters.TR

                if randi(parameters.targRate)     == 1
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

                % Log this stimulus set
                nSets                             = nSets + 1;
                shownAlienIdx                     = goodAlienIdx(goodAliensChosen);
                if showBadAlien
                    shownAlienIdx(badAlienPos)    = badAlienIdx;
                    stimLog.badPresent(nSets)     = true;
                    stimLog.badPos(nSets)         = badAlienPos;
                    stimLog.badXY(nSets, :)       = [alienXs(badAlienPos) alienYs(badAlienPos)];
                end
                stimLog.sweep(nSets)              = trial;
                stimLog.sweepDir{nSets}           = currSweepOrder;
                stimLog.bar(nSets)                = barNum;
                stimLog.alienIdx(nSets, :)        = shownAlienIdx;
                stimLog.alienX(nSets, :)          = alienXs;
                stimLog.alienY(nSets, :)          = alienYs;
                firstFrameOfSet                   = true;

                while GetSecs - newStimuliSetOnset <= parameters.timeperStimuliSet
                    [~, ~, keyCode]                           = KbCheck;
                    if keyCode(escKey)
                        error('invaderTask:userAbort', 'Run aborted by user.');
                    end

                    % Get pointer position
                    if parameters.mocap
                        pointerOrigSpace                      = qtm_getGunPos(parameters.mocapHandle);
                    else
                        [mouseX, mouseY, buttons]             = GetMouse(screen.win);
                        pointerOrigSpace                      = [mouseX mouseY];
                    end
    %                 pointerScreenSpace                        = pointerOrigSpace;
                    pointerScreenSpace                    = pointerOrigSpace * GunToScreen_transform.T * ...
                                            GunToScreen_transform.b + GunToScreen_transform.c(1, :);

                    if keyCode(spaceKey)
    %                     drawTextures(parameters, screen, 'CrossHairGunShot', [], pointerScreenSpace)
                        if GetSecs - lastGunShot              > gunShotWaitTime
                            lastGunShot                       = GetSecs;
                            nShots                            = nShots + 1;
                            shotLog.time(nShots)              = lastGunShot - runStartTime;
                            shotLog.screenXY(nShots, :)       = pointerScreenSpace;
                            shotLog.rawXY(nShots, :)          = pointerOrigSpace;
                            shotLog.setIdx(nShots)            = visibleSet;
                            shotLog.shotType(nShots)          = 0;
                            % Score the shot against the set currently on screen
                            if visibleSet > 0 && stimLog.badPresent(visibleSet)
                                badXY                         = stimLog.badXY(visibleSet, :);
                                shotLog.distPix(nShots)       = norm(pointerScreenSpace - badXY);
                                shotLog.distDva(nShots)       = pixel2va(pointerScreenSpace(1), pointerScreenSpace(2), ...
                                                                         badXY(1), badXY(2), parameters, screen);
                                if shotLog.distPix(nShots)    <= parameters.hitRadius
                                    shotLog.RT(nShots)        = shotLog.time(nShots) - stimLog.onset(visibleSet);
                                    if stimLog.hit(visibleSet)
                                        shotLog.shotType(nShots) = 2;
                                    else
                                        shotLog.shotType(nShots) = 1;
                                        stimLog.hit(visibleSet)  = true;
                                        stimLog.RT(visibleSet)   = shotLog.RT(nShots);
                                    end
                                end
                            end
                        end
                    end
                    for i                                     = 1:parameters.aliensPerBar
                        if showBadAlien && i == badAlienPos
                            drawTextures(parameters, screen, 'Alien', [], [alienXs(i) alienYs(i)], badAlien);
                        else
                            drawTextures(parameters, screen, 'Alien', [], [alienXs(i) alienYs(i)], goodAliens{goodAliensChosen(i)});
                        end
                    end
                    if GetSecs - lastGunShot < gunShotWaitTime
                        drawTextures(parameters, screen, 'CrossHairGunShot', [], pointerScreenSpace)
                    else
                        drawTextures(parameters, screen, 'CrossHair', [], pointerScreenSpace)
                    end
                    vbl                                       = Screen('Flip', screen.win);
                    visibleSet                                = nSets;
                    if firstFrameOfSet
                        stimLog.onset(nSets)                  = vbl - runStartTime;
                        firstFrameOfSet                       = false;
                    end
                    nFrames                                   = nFrames + 1;
                    frameLog.time(nFrames)                    = vbl - runStartTime;
                    frameLog.rawXY(nFrames, :)                = pointerOrigSpace;
                    frameLog.screenXY(nFrames, :)             = pointerScreenSpace;
                    frameLog.setIdx(nFrames)                  = nSets;
                end
                stimLog.offset(nSets)                         = GetSecs - runStartTime;
                % TODO(cleanup): these extra flips show a blank frame between stimulus sets, bars and sweeps; intended?
                [visibleSet, nFrames, frameLog]               = logBlankFlip(screen, runStartTime, nFrames, frameLog);
            end
            barNum = barNum + 1;
            [visibleSet, nFrames, frameLog]                   = logBlankFlip(screen, runStartTime, nFrames, frameLog);
        end
        trial = trial + 1;
        [visibleSet, nFrames, frameLog]                       = logBlankFlip(screen, runStartTime, nFrames, frameLog);
    end
    runStatus                                         = 'complete';
catch ME
    if strcmp(ME.identifier, 'invaderTask:userAbort')
        runStatus                                     = 'aborted';
        disp(ME.message)
    else
        runStatus                                     = 'error';
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save and clean up
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('runData', 'var')
    runData.status                                = runStatus;
    saveParams                                    = parameters;
    if isfield(saveParams, 'mocapHandle')
        saveParams                                = rmfield(saveParams, 'mocapHandle');
    end
    runData.parameters                            = saveParams;
    runData.screen                                = rmfield(screen, 'win');
    if exist('stimLog', 'var')
        runData.stimLog                           = trimLog(stimLog, nSets);
        runData.shotLog                           = trimLog(shotLog, nShots);
        runData.frameLog                          = trimLog(frameLog, nFrames);
        % Performance summary
        s.nBadShown                               = sum(runData.stimLog.badPresent);
        s.nHits                                   = sum(runData.stimLog.hit);
        s.nMisses                                 = s.nBadShown - s.nHits;
        s.nFalseAlarms                            = sum(runData.shotLog.shotType == 0);
        s.hitRate                                 = s.nHits / max(s.nBadShown, 1);
        s.meanRT                                  = mean(runData.stimLog.RT, 'omitnan');
        s.medianRT                                = median(runData.stimLog.RT, 'omitnan');
        runData.summary                           = s;
        disp(s)
    end
    matFile                                       = parameters.matFile;
    if ~strcmp(runStatus, 'complete')
        matFile                                   = strrep(matFile, '.mat', '_partial.mat');
    end
    save(fullfile(parameters.block_dir, matFile), 'runData');
    fprintf('Saved data to %s\n', fullfile(parameters.block_dir, matFile));

    if strcmp(runStatus, 'complete')
        showprompts(screen, 'BlockEnd', runData.summary.nHits)
        WaitSecs(2);
        showprompts(screen, 'EndExperiment')
        WaitSecs(1);
    end
end

if ~isempty(alienTextures)
    Screen('Close', [alienTextures{:}]);
end
sca;
Priority(0);
if strcmp(runStatus, 'error')
    rethrow(ME);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Local functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [visibleSet, nFrames, frameLog] = logBlankFlip(screen, runStartTime, nFrames, frameLog)
% Flip an empty frame and log it as a blank (setIdx = 0)
vbl                                           = Screen('Flip', screen.win);
visibleSet                                    = 0;
nFrames                                       = nFrames + 1;
frameLog.time(nFrames)                        = vbl - runStartTime;
frameLog.rawXY(nFrames, :)                    = [NaN NaN];
frameLog.screenXY(nFrames, :)                 = [NaN NaN];
frameLog.setIdx(nFrames)                      = 0;
end

function log = trimLog(log, n)
% Keep the first n rows of every field in a preallocated log
fields                                        = fieldnames(log);
for f                                         = 1:numel(fields)
    log.(fields{f})                           = log.(fields{f})(1:n, :);
end
end
