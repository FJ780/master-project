% Project Spyn

%  - Left wheel motor = port 'D'
%  - Right wheel motor = port 'A'
%  - Color sensor = port 1 (facing down)
%  - Ultrasonic left = port 2
%  - Ultrasonic right = port 4
%  - Front touch sensor = port 3
%  - Brick handle is 'brick' (created elsewhere via ConnectBrick)
%  - Motors are upside-down: NEGATIVE speed -> forward, POSITIVE -> backward
%

%% Configuration / tuning
forwardSpeed = -45;        % negative -> forward (adjust as needed)
cruisePause = 0.05;        % loop pause between sensor reads
backupDuration = 0.5;      % seconds to back up when bumped
turnDuration = 0.6;        % seconds to pivot after backing up
turnSpeed = 90;            % magnitude for turning (positive/negative as required)
    brick.MoveMotor(LEFT_MOTOR, forwardSpeed - 5);
            brick.MoveMotor(LEFT_MOTOR, +40 + 5);
            brick.MoveMotor(RIGHT_MOTOR, +40);
            pause(backupDuration);
            brick.StopAllMotors('Brake');
            pause(0.05);
            % Decide which way to turn based on ultrasonic distances:
            dLeft = brick.UltrasonicDist(US_LEFT_PORT);   % cm (255 = no reading)
            dRight = brick.UltrasonicDist(US_RIGHT_PORT); % cm
            % If noisy or 255, treat 255 as very large (open)
            if dLeft == 255, dLeft = 1000; end
            if dRight == 255, dRight = 1000; end
            % Choose turn direction: go toward the side with *larger* distance (more open)
            if dLeft > dRight
                % Turn LEFT: left wheel backward, right wheel forward (see comments in analysis)
                % left motor backward => positive; right motor forward => negative
                brick.MoveMotor(LEFT_MOTOR, +turnSpeed + 5);
                brick.MoveMotor(RIGHT_MOTOR, -turnSpeed);
                fprintf('Turning LEFT for %.2fs (dLeft=%.1f, dRight=%.1f)\n', turnDuration, dLeft, dRight);
            else
                % Turn RIGHT: left forward (negative), right backward (positive)
                brick.MoveMotor(LEFT_MOTOR, -turnSpeed - 5);
                brick.MoveMotor(RIGHT_MOTOR, +turnSpeed);
                fprintf('Turning RIGHT for %.2fs (dLeft=%.1f, dRight=%.1f)\n', turnDuration, dLeft, dRight);
            end
            pause(turnDuration);
            brick.StopAllMotors('Brake');
            % Resume forward cruise
            brick.MoveMotor(LEFT_MOTOR, forwardSpeed - 5);
            brick.MoveMotor(RIGHT_MOTOR, forwardSpeed);
            % small pause to avoid immediately retriggering
            pause(0.15);
        end
        % Loop continues: color polling and touch checks keep happening
    end
    fprintf('Main loop exited. Motors stopped.\n');
catch ME
    % If anything goes wrong, stop motors and rethrow the error (so you can debug)
    warning('Exception caught: stopping motors.');
    try
        brick.StopAllMotors('Coast');
    catch
        % ignore cleanup errors
    end
    rethrow(ME);
end
% Final clean up (leave brick connected; your wrapper code can call DisconnectBrick when done)
brick.StopAllMotors('Brake');
brick.beep();   % a final beep to indicate script finished
