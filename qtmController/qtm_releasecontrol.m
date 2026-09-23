function [] = qtm_releasecontrol(tcp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stop and close connection with mocap
% CEC 01/21/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
control.string = 'ReleaseControl';
fwrite(tcp,qtm_build_packet('ReleaseControl'))
pause(.5);
while(tcp.BytesAvailable>0)
    size = typecast(uint8(fread(tcp,4)),'int32');
    control = qtm_unpack_packet(fread(tcp,double(size-4)));
end
fprintf('%s\n',control.string)
fclose(tcp);
clear tcp;
