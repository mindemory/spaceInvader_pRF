function pkt = qtm_build_packet(cmd)
% Compute the # of bytes in packet:
%   4 - to hold size
%   4 - to hold type
%   (variable) - length of command
%   1 - for terminating null
% and convert it to binary so we can output appropriate endian values
bin_size = dec2bin(length(cmd)+9,32);

% Build the packet, doing the endian conversion for the size int32 manually
% little endian
pkt = [char([bin2dec(bin_size(25:32)) bin2dec(bin_size(17:24)) bin2dec(bin_size(9:16)) bin2dec(bin_size(1:8))]) char([1 0 0 0]) cmd char([0])];