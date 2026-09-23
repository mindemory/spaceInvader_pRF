function markerpos = qtm_getsampleFromDrive(tcp, numMarkersUsed)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sample from mocap for marker position 
% ZD adopt from MD's code 05/11/2025
% CWS 09/16/2011 - added switch data.type to solve "Event set" error and
%     deal with event set response leading to error
%     '??? Reference to non-existent field 'cmpnt'.'
% tcp: tcpid
% numMakersUsed: number of markers being used
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Poll QTM for marker
fwrite(tcp, qtm_build_packet('GetCurrentFrame 3DNoLabels'));
packsize = typecast(uint8(fread(tcp,4)),'int32');
data = qtm_unpack_packet(fread(tcp,double(packsize-4)));
lastmarkerpos = zeros(numMarkersUsed, 4);

switch data.type

    % Post event setting QTM Server Response
    case 1
        clear data
        markerpos = lastmarkerpos;

        % Normal case of polling for marker position
    case 3
        if ~data.nodata && ~data.error && isfield(data.cmpnt(1),'marker')
            actualMarkerCount = min(numMarkersUsed, length(data.cmpnt(1).marker));
            markerpos = zeros(length(data.cmpnt(1).marker), 4);
            for markerIdx = 1:actualMarkerCount
                markerpos(markerIdx,1) = data.cmpnt(1).marker(markerIdx).x;   % x coordinate
                markerpos(markerIdx,2) = data.cmpnt(1).marker(markerIdx).y;   % y coordinate
                markerpos(markerIdx,3) = data.cmpnt(1).marker(markerIdx).z;   % z coordinate
                markerpos(markerIdx,4) = data.cmpnt(1).marker(markerIdx).id;  % id
            end

        else
            markerpos = lastmarkerpos;
        end
end
% disp(markerpos)

