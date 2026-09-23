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
    
elseif contains(hostname, 'wireless.nyu.edu') || contains(hostname, 'MacBookPro')
    thisdev = 'mac';
    addpath(genpath('/Applications/Psychtoolbox'));
    parameters.isDemoMode = true;
    parameters.eyetracker = 0;
    parameters.mocap = 1;
    Screen('Preference','SkipSyncTests', 1)
else
    disp('Running on unknown device. Psychtoolbox might not be added correctly!')
    return;
end

% Initialize data paths
addpath(genpath('./Stimuli'));
addpath(genpath('./qtmController'));
addpath(genpath('./audionumbers'));

% Initialize screen and peripherals
screen                                       = initScreen(parameters);
[kbx, mbx, parameters]                       = initPeripherals(parameters, thisdev);
if parameters.mocap
    parameters.mocapHandle                   = initMocap;
end

handImg = imread('hand.png');
handHeight = screen.screenXpixels * 0.5;
handWidth = round(size(handImg, 2) * handHeight / size(handImg, 1));
leftHandImg                                   = handImg;
rightHandImg                                  = fliplr(handImg);
lefthandTexture                               = Screen('MakeTexture', screen.win, leftHandImg);
righthandTexture                              = Screen('MakeTexture', screen.win, rightHandImg);

leftHandRect = CenterRectOnPoint([0 0 handWidth handHeight], round(screen.xCenter * 0.5), round(screen.yCenter * 1.5));
rightHandRect = CenterRectOnPoint([0 0 handWidth handHeight], round(screen.xCenter * 1.5), round(screen.yCenter * 1.5));

numMarkersUsed = 6;
framesToWait = 20;
while true
    Screen('MakeTexture', screen.win, handImg);
    showofHandsText = 'Do a show of hands!';
    Screen('TextSize', screen.win, 30);
    DrawFormattedText(screen.win, showofHandsText, 'center', round(screen.yCenter * 0.5), screen.white);
    
    Screen('DrawTexture', screen.win, lefthandTexture, [], leftHandRect);
    Screen('DrawTexture', screen.win, righthandTexture, [], rightHandRect);
    Screen('Flip', screen.win)
    WaitSecs(0.1);
    framesToWait = min(framesToWait - 1, 0);
    if framesToWait == 0
        markerpos = qtm_getsampleFromDrive(parameters.mocapHandle, numMarkersUsed);
        if size(markerpos, 1) == numMarkersUsed
    %         uniqueMrkIds = unique(markerpos(:,4));
            maxY = max(markerpos(:,2));
            minY = min(markerpos(:,2));
            distanceY = abs(maxY - minY);
            
            rightMarkerIdxTemp = find(markerpos(:, 2) < minY + distanceY * 0.4);
            leftMarkerIdxTemp = find(markerpos(:,2) > minY + distanceY * 0.6);
    
            rightPtIdx = markerpos(rightMarkerIdxTemp, 4);
            leftPtIdx = markerpos(leftMarkerIdxTemp, 4);
    
            if length(leftPtIdx) == length(rightPtIdx)
                break;
            end
    
        end
    end
end

