function showprompts(screen, prompt_name, num, doflip)
% Created by Mrugank Dake, Curtis Lab, NYU (10/11/2022)
if nargin < 4
    doflip = 1;
end
switch prompt_name
    case 'WelcomeWindow'
        text = 'Welcome to the task. Time to shoot "em invaders, brace your belt commander.\n Press SPACE to continue ...';
    case 'CalibrateStick'
        text = 'Follow the alien on the screen using your stick. This will be the bad alien for this round.';
    case 'BadCalibration'
        text = 'Oops, that does not look correct. Follow the pointer correctly.'; 
    case 'BadValidation'
        text = 'Do not waste them bullets in space, shoot the aliens. Lets try again!'; 
    case 'ValidateStick'
        text = 'Follow the bad alien again to make sure you can shoot it alright.';
    case 'ValidationAccepted'
        text = 'Looks like we have a great commander incharge. Alright, buckleup!';
    case 'RunOnset'
        text = 'Alright commander, buckleup! Time to shoot those bad aliens down.';
    case 'BlockEnd'
        % TO DO: Add a threshold performance score, maybe????
        text = ['That was some fine shooting. Space points = ' num2str(round(num), "%i") ];
    case 'ContinueorEsc'
        text = ['End of block ' num2str(num) '. Please take a break. Press SPACE to continue.'];
    case 'EyeCalibStart'
        text = sprintf('Please press any key and \n keep focused at the central fixation point for 5 seconds');
    case 'EyeCalibEnd'
        text = sprintf('Thank you. When ready, press key to continue.');
    case 'TrialPause'
        text = 'Experiment is paused! Press SPACE to resume.';
    case 'EndExperiment'
        text = 'Aye aye, spaceman! Until next time ...';
end
fontsize = 30;
text_color = screen.white;
Screen('TextSize', screen.win, fontsize);
DrawFormattedText(screen.win, text, 'center', 'center', text_color);
if doflip == 1
    Screen('Flip', screen.win);
end
end