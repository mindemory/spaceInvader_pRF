function [] = qtm_sendevent(t,ecode)
% CS 9/11/2011 - wrote it
%    9/16/2011 - optimized the output (made it work)
%

% Set up the event string
cmd.string = 'Event ';

% Concat the ecode to cmd.string
cmd.string = [cmd.string ecode];

% write string to QTM
fwrite(t,qtm_build_packet(cmd.string));

% clean up
clear eventresponse;
clear data;