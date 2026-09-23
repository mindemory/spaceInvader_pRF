function markerpos = qtm_getsample(t,lastmarkerpos,x_trans,x_gain,y_trans,y_gain)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sample from mocap for marker position in mgl dva
% CEC 01/20/11
% CWS 09/16/2011 - added switch data.type to solve "Event set" error and
%     deal with event set response leading to error
%     '??? Reference to non-existent field 'cmpnt'.'
%
% Usage: markerpos = qtm_getsample(t,mgl_range,qtm_range,lastmarkerpos,x_trans,x_gain,y_trans,y_gain)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Poll QTM for marker
fwrite(t,qtm_build_packet('GetCurrentFrame 3DnoLabels'));
size = typecast(uint8(fread(t,4)),'int32');
data = qtm_unpack_packet(fread(t,double(size-4)));

% Switch to deal with "Event set" response
switch data.type    
    
    % Post event setting QTM Server Response
    case 1
        clear data
        markerpos = lastmarkerpos;
        
        % Normal case of polling for marker position
    case 3
        if ~data.nodata && ~data.error && isfield(data.cmpnt(1),'marker')
            markerpos(1) = ((data.cmpnt(1).marker(1).x)/10) * x_gain + x_trans; %adjust x translation and x gain
            markerpos(2) = ((data.cmpnt(1).marker(1).y)/10) * y_gain + y_trans; %adjust y translation and x gain    
        else
            markerpos = lastmarkerpos;
        end
end
