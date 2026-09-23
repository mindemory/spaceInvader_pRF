function parameters                     = loadParameters(subjID)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% program basic settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parameters.eyeTrackerOn                 = 0;
parameters.transparency                 = 0.85; % transparency for debug mode
parameters.viewingDistance              = 55; % viewDist (in cm)
parameters.apertureSize                 = 28; % in degrees of visual angle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% study parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parameters.studyname                    = 'Invader_pRF';
parameters.subject                      = subjID;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scan parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parameters.TR                           = 1.3; % in seconds
parameters.TRperbar                     = 2; % 2 TRs
parameters.timeperStimuliSet            = 0.6; % in seconds (to start with, this can change base don performance)
parameters.nbars                        = 12;
parameters.aliensPerBar                 = 6;
parameters.alienAreaPerStim             = 0.99; % Percentage of area to use to display alien
parameters.ntrials                      = 8; %8; % Total number of sweeps to run
parameters.targRate                     = 2; % The target will have a 1/X chance of being presented in each set
parameters.targCooldown                 = 1; % The target is only allowed to be presented once every X seconds; must be >= response_period
parameters.responsePeriod               = 0.9; % Maximum response time allowed in seconds; must be <= targ_cooldown
parameters.responseDelay                = 0.2; % Time period starting from the onset of stimuli in which subject cannot respond. This is used to keep a suitable window open for response feedback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stimulus parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parameters.fixationColor               = [255 255 255]; % black
parameters.hitCorrectColor             = [0 255 0]; % green
parameters.fixationBreakColor          = [255 191 0]; % amber
parameters.crosshairColor              = [255 191 0];
parameters.fixationSizeDeg             = 0.6; % degrees of visual angle
parameters.fixbreakthresh              = 1.2; % degrees of visual angle
% % Adding parameters for stimulus (TO DO: change to dva)
% % parameters.alienSize                   = 100; % in pixels
% parameters.alienSize                   = 2.5; % in dva
% parameters.spaceshipSize               = 120; % in pixels
% parameters.marginForAlien              = 0.15; % in fraction (fraction of screen on each size not to use)
% parameters.marginForSpaceship          = 0.05; % in fraction (fraction of bottom screen not to use)
parameters.crossHairRatio              = 0.5; % Half of alien size
% Explosion parameters
parameters.explodenParticles           = 300;
parameters.explodenFrames              = 20;
% parameters.burstRadius                 = parameters.alienSize * 1.05; % Radius within which you are okay to hit
parameters.explodeAngles               = rand(1, parameters.explodenParticles) * 2 * pi;
parameters.explodeSpeeds               = rand(1, parameters.explodenParticles) * 5 + 5;
parameters.respawnDelayFrames          = 20; % Number of frames after explosion to wait for
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % timing parameters (in seconds)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% parameters.initDuration = 1;
% parameters.sampleDuration = 0.25; %0.5;
% parameters.delayDuration = 4;
% % parameters.delay1Duration = parameters.delayDuration/2;
% % parameters.delay2Duration = parameters.delayDuration/2;%-parameters.delay1Duration-parameters.pulseDuration;
% % parameters.respDuration = 2;
% parameters.respDuration = 3;
% parameters.feedbackDuration = 1;
% parameters.itiDuration = [1.5,2.5];
end



