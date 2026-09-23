function mocapHandle                 = initMocap()

mocapHandle                          = tcpip('100.1.1.66',22223);
set(mocapHandle, 'InputBufferSize', 30000);
fopen(mocapHandle);

% Make sure the connection is stable
fwrite(mocapHandle,qtm_build_packet('GetParameters'));
packsize                             = typecast(uint8(fread(mocapHandle,4)),'int32');
getParamMsg                          = qtm_unpack_packet(fread(mocapHandle,double(packsize-4)));
disp(getParamMsg.string')

end