function gunPos                              = qtm_getGunPos(mocapHandle)

numMarkersUsed                               = 2;
% gunPos                                   = NaN(numMarkersUsed, 4);
lastmarkerpos                                = zeros(numMarkersUsed, 4);
markerpos                                    = zeros(numMarkersUsed, 4);

while true
    fwrite(mocapHandle,qtm_build_packet('GetCurrentFrame 3DNoLabels'));
    packsize                                 = typecast(uint8(fread(mocapHandle,4)),'int32');
    markerIncoming                           = qtm_unpack_packet(fread(mocapHandle,double(packsize-4)));
    
    switch markerIncoming.type
    
        % Post event setting QTM Server Response
        case 1
            clear markerIncoming
            markerpos                        = lastmarkerpos;
    
       % Normal case of polling for marker position
        case 3
            if ~markerIncoming.nodata && ~markerIncoming.error && isfield(markerIncoming.cmpnt(1),'marker') && length(markerIncoming.cmpnt(1).marker) == numMarkersUsed
                markerpos                    = zeros(numMarkersUsed, 4);
                for markerIdx                = 1:numMarkersUsed
                    markerpos(markerIdx,1)   = markerIncoming.cmpnt(1).marker(markerIdx).x;   % x coordinate
                    markerpos(markerIdx,2)   = markerIncoming.cmpnt(1).marker(markerIdx).y;   % y coordinate
                    markerpos(markerIdx,3)   = markerIncoming.cmpnt(1).marker(markerIdx).z;   % z coordinate
                    markerpos(markerIdx,4)   = markerIncoming.cmpnt(1).marker(markerIdx).id;  % id
                end
    
            else
                markerpos                    = lastmarkerpos;
            end
    end
    % Check if both markers have non-zero positions
    if all(any(markerpos(:,1:3)              ~= 0, 2))
        % Both markers have at least one non-zero coordinate
        break;
    end

    lastmarkerpos                            = markerpos;
        
    % So the TCP/IP doesn't break down
    pause(0.01);
end


%% Compute the slope, this is under the assumption that the hand doesn't move along z-axis
% Fit linear regression: z = slope * y + intercept
y = markerpos(:,2);
z = markerpos(:,3);

% Add a column of ones for the intercept
X = [y, ones(size(y))];
params = X \ z; % Least squares solution


% gunPos  = [0 params(2)]; % We are assuming that z_gun is y_screen and y_gun is x_screen
gunPos = [y(1) z(1)];

end