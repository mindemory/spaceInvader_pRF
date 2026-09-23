function data = qtm_unpack_packet(pkt)
% CEC 01.20.11

data.type = typecast(uint8(pkt(1:4)),'int32');
data.error = 0;
data.nodata = 0;
data.xml = 0;

data_seg = pkt(5:end);

switch data.type
    % Error
    case 0
        data.error = 1;
        data.string = char(data_seg);

        % Command String/Command Response
    case 1
        data.string = char(data_seg);

        % XML
    case 2
        data.string = char(data_seg);
        data.xml = 1;
        %data.xmlstruct = xml_parse(data.string');

        % Data
    case 3
        data.timestamp = typecast(uint8(data_seg(1:8)),'int64');
        data.frame_num = typecast(uint8(data_seg(9:12)),'int32');
        data.cmpnt_cnt = typecast(uint8(data_seg(13:16)),'int32');

        cmpnt_seg = data_seg(17:end);

        for i=1:data.cmpnt_cnt
            data.cmpnt(i).size = typecast(uint8(cmpnt_seg(1:4)),'int32');
            data.cmpnt(i).type = typecast(uint8(cmpnt_seg(5:8)),'int32');

            switch data.cmpnt(i).type
                % 3D (3D marker data)
                case 1

                    % 3DRes (3D marker data with residuals)
                case 9

                    % 3DnoLabels (Unidentified 3D marker data)
                case 2
                    data.cmpnt(i).marker_cnt = typecast(uint8(cmpnt_seg(9:12)),'int32');
                    cmpnt_seg = cmpnt_seg(17:end);
                    for j=1:data.cmpnt(i).marker_cnt
                         data.cmpnt(i).marker(j).x = typecast(uint8(cmpnt_seg(1:8)),'double'); %change to float32?
                         data.cmpnt(i).marker(j).y = typecast(uint8(cmpnt_seg(9:16)),'double'); %seg 4 not 8?
                         data.cmpnt(i).marker(j).z = typecast(uint8(cmpnt_seg(17:24)),'double');
                         data.cmpnt(i).marker(j).id = typecast(uint8(cmpnt_seg(25:28)),'uint32');
                         cmpnt_seg = cmpnt_seg(33:end);
                    end

                    % 3DnoLabelsRes (Unidentified 3D marker data with residuals)
                case 10

                    % Analog
                case 3

                    % Force
                case 4

                    % 6D (6D Data - position and rotation matrix)
                case 5

                    % 6DRes (6D Data - position and rotation matrix with residual)
                case 11

                    % 6DEuler (6D Data - position and Euler angles)
                case 6

                    % 6DEulerRes (6D Data - position and Euler angles with residuals)
                case 12

                    % 2D (2D marker data)
                case 7

                    % 2DLin (Linearized 2D marker data)
                case 8
            end
        end

        % No More Data
    case 4
        data.nodata = 1;
end