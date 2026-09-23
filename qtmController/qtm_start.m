function tcp = qtm_start
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize and start connection with mocap and take control
% CEC 01/21/11
% Usage: tcp = qtm_start;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Normal TCP/IP Connection
tcp = tcpip('100.1.1.66',22223);
set(tcp, 'InputBufferSize', 30000);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fopen(tcp);
pause(.5);
welcome.string = 'Connection Failed!';
while(tcp.BytesAvailable>0)
    size = typecast(uint8(fread(tcp,4)),'int32');
    welcome = qtm_unpack_packet(fread(tcp,double(size-4)));
end
fprintf('%s\n',welcome.string)
version.string = 'Version Failed!';
fwrite(tcp,qtm_build_packet('Version 1.7')) %change to newer version?
%Version 1.8 of QTM RT uses float32 while previous versions use double
pause(.5);
while(tcp.BytesAvailable>0)
    size = typecast(uint8(fread(tcp,4)),'int32');
    version = qtm_unpack_packet(fread(tcp,double(size-4)));
end
fprintf('%s\n',version.string)
fwrite(tcp,qtm_build_packet('GetParameters All'))
pause(.5);
while(tcp.BytesAvailable>0)
    size = typecast(uint8(fread(tcp,4)),'int32');
    params = qtm_unpack_packet(fread(tcp,double(size-4)));
end
control.string = 'Control Failed!';
fwrite(tcp,qtm_build_packet('TakeControl'))
pause(.5);
while(tcp.BytesAvailable>0)
    size = typecast(uint8(fread(tcp,4)),'int32');
    control = qtm_unpack_packet(fread(tcp,double(size-4)));
end
fprintf('%s\n',control.string)
