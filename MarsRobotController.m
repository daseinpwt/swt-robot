classdef MarsRobotController < handle

    properties (Constant)
        MOTOR_LEFT    = 1
        MOTOR_RIGHT   = 2

        COLOR_BLACK   = 1
        COLOR_WHITE   = 2
        COLOR_RED     = 3
        COLOR_GREEN   = 4
        COLOR_GRAY    = 5

        COLOR_NUM     = 5

        %! This params matrix should be measured each time
        COLOR_FLAG_VALUE = [
        %   BLACK   WHITE   RED    GREEN   GRAY
            440     730     1000   1000    1000 ; % LEFT MOTOR
            430     720     1000   1000    1000   % RIGHT MOTOR
        ]

        SPEED_SLOW    = 10
        SPEED_NORMAL  = 30
        SPEED_FAST    = 50

        % for moving along the black line
        BACK_TIME     = 0.25;
        TURN_TIME     = 0.3;
    end

    properties
        nxt_handle
        mtr_all    % BOTH MOTORS
        mtr_left   % LEFT MOTOR
        mtr_right  % RIGHT MOTOR
    end

    methods
        function setup(obj)
            COM_CloseNXT('all');

            % Connect to robot and get the handle object
            obj.nxt_handle = COM_OpenNXT();
            COM_SetDefaultNXT(obj.nxt_handle);

            % Open light sensors 'active' mode
            % SENSOR_2: right
            % SENSOR_3: left
            OpenLight(SENSOR_2, 'ACTIVE');
            OpenLight(SENSOR_3, 'ACTIVE');

            % Open distance sensor
            OpenUltrasonic(SENSOR_1);

            % Get motors controlling objects
            obj.mtr_all = NXTMotor('AC');
            obj.mtr_left = NXTMotor('C');
            obj.mtr_right = NXTMotor('A');
        end

        %F This function will return a double values, which is
        %  the distance between the robot and the nearest object
        %  in front of the robot.
        function distance = detectObstacle(obj)
            distance = GetUltrasonic(SENSOR_1);
%             distance = 21;
        end

        %F Make beep sound.
        function beep(obj, hz, ms)
            NXT_PlayTone(hz, ms);
        end

        %F Stop the robot (the end of the task).
        function stop(obj)
            obj.mtr_all.Stop('off');
            pause(1.0);
            obj.beep(440, 100);
        end

        %F Check if the motor has detected the color
        function sensored = sensoredColor(obj, motor, color)
            if motor == obj.MOTOR_LEFT
                v = GetLight(SENSOR_3);
%                 v = 500;
            else
                v = GetLight(SENSOR_2);
%                 v = 720;
            end

            color_flags = obj.COLOR_FLAG_VALUE(motor, :);
            p = 1;
            for i = 2 : obj.COLOR_NUM
                if (abs(v - color_flags(i)) < abs(v - color_flags(p)))
                    p = i;
                end
            end
            sensored = (p == color);
        end

        function goStraightForward(obj, speed, duration)
            obj.mtr_all.Stop('off');
            obj.mtr_all.Power = speed;
            obj.mtr_all.SendToNXT();
            if (duration ~= -1)
                pause(duration);
                obj.mtr_all.Stop('off');
            end
        end

        function goStraightBackward(obj, speed, duration)
            obj.mtr_all.Stop('off');
            obj.mtr_all.Power = -speed;
            obj.mtr_all.SendToNXT();
            if (duration ~= -1)
                pause(duration);
                obj.mtr_all.Stop('off');
            end
        end

        function turnRight(obj, speed, duration)
            obj.mtr_left.Power = speed;
            obj.mtr_left.SendToNXT();
            if (duration ~= -1)
                pause(duration);
                obj.mtr_left.Stop('off');
            end
        end

        function turnLeft(obj, speed, duration)
            obj.mtr_right.Power = speed;
            obj.mtr_right.SendToNXT();
            if (duration ~= -1)
                pause(duration);
                obj.mtr_right.Stop('off');
            end
        end

        function start(obj)
            obj.goStraightForward(obj.SPEED_NORMAL, -1);

            while (true)
                if (obj.detectObstacle() <= 20)
                    obj.stop();
                    return;
                end

                if obj.sensoredColor(obj.MOTOR_RIGHT, obj.COLOR_BLACK)
                    obj.goStraightBackward(self.SPEED_NORMAL, obj.BACK_TIME);
                    pause(0.2);
                    obj.turnRight(self.SPEED_NORMAL, obj.TURN_TIME);
                    obj.goStraightForward(self.SPEED_NORMAL, -1);
                elseif obj.sensoredColor(obj.MOTOR_LEFT, obj.COLOR_BLACK)
                    obj.goStraightBackward(self.SPEED_NORMAL, obj.BACK_TIME);
                    pause(0.2);
                    obj.turnLeft(self.SPEED_NORMAL, obj.TURN_TIME);
                    obj.goStraightForward(self.SPEED_NORMAL, -1);
                end
            end
        end
    end
end
