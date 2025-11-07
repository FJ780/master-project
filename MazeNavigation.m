% Project Spyn - simple maze runner with color reactions
% -------------------------------------------------------
% Assumptions:
%  - Left wheel motor = port 'D'
%  - Right wheel motor = port 'A'
%  - Color sensor = port 1 (facing down)
%  - Ultrasonic left = port 2
%  - Ultrasonic right = port 4
%  - Front touch sensor = port 3
%  - Brick handle variable = brick (connected elsewhere)
%  - Motors upside down: NEG speed -> forward, POS -> backward
% -------------------------------------------------------

%% Configuration / tuning
forwardSpeed   = -45;     % negative -> forward
cruisePause    = 0.05;    % pause between sensor reads
backupDuration = 0.5;     % seconds to back up on bump
turnDuration   = 0.6;     % seconds to pivot
turnSpeed      = 90;      % turning speed magnitude

% Color detection thresholds (RGB mode, 0–255)
redThresh   = [100 40 40];   % R>100, G<40, B<40
blueThresh  = [40 60 100];   % B>100, R,G<70ish
greenThresh = [50 100 50];   % G>100, R<70, B<70
yellowThresh = [110 90 90];  % (for your yellow stop)
colorPollInterval = 0.1;

% Ports
COLOR_PORT   = 1;
US_LEFT_PORT = 2;
TOUCH_PORT   = 3;
US_RIGHT_PORT= 4;
LEFT_MOTOR   = 'D';
RIGHT_MOTOR  = 'A';

%% Initialize color sensor
brick.SetColorMode(COLOR_PORT, 4); % RGB mode

fprintf('Project Spyn with color reactions started.\n');
lastColorCheck = tic;

%% Main driving loop
try
    % start moving
    brick.MoveMotor(LEFT_MOTOR, forwardSpeed);
    brick.MoveMotor(RIGHT_MOTOR, forwardSpeed);

    while true
        pause(cruisePause);

        % ---------- COLOR SENSOR CHECK ----------
        if toc(lastColorCheck) > colorPollInterval
            lastColorCheck = tic;
            rgb = brick.ColorRGB(COLOR_PORT);
            if numel(rgb)==3
                R = double(rgb(1));
                G = double(rgb(2));
                B = double(rgb(3));

                % -------- Red detection --------
                if (R > redThresh(1)) && (G < redThresh(2)) && (B < redThresh(3))
                    brick.StopAllMotors('Brake');
                    fprintf('RED detected (RGB = [%d %d %d]). Stop 1 sec.\n', R,G,B);
                    pause(1);
                    brick.MoveMotor(LEFT_MOTOR, forwardSpeed);
                    brick.MoveMotor(RIGHT_MOTOR, forwardSpeed);
                % -------- Blue detection --------
                elseif (B > blueThresh(3)) && (R < blueThresh(1)+30) && (G < blueThresh(2)+30)
                    brick.StopAllMotors('Brake');
                    fprintf('BLUE detected (RGB = [%d %d %d]). 2 beeps.\n', R,G,B);
                    for i = 1:2
                        brick.beep();
                        pause(0.4);
                    end
                    brick.MoveMotor(LEFT_MOTOR, forwardSpeed);
                    brick.MoveMotor(RIGHT_MOTOR, forwardSpeed);
                % -------- Green detection --------
                elseif (G > greenThresh(2)) && (R < greenThresh(1)+20) && (B < greenThresh(3)+20)
                    brick.StopAllMotors('Brake');
                    fprintf('GREEN detected (RGB = [%d %d %d]). 3 beeps.\n', R,G,B);
                    for i = 1:3
                        brick.beep();
                        pause(0.4);
                    end
                    brick.MoveMotor(LEFT_MOTOR, forwardSpeed);
                    brick.MoveMotor(RIGHT_MOTOR, forwardSpeed);
                % -------- Yellow detection (final stop) --------
                elseif (R > yellowThresh(1)) && (G > yellowThresh(2)) && (B < yellowThresh(3))
                    brick.StopAllMotors('Brake');
                    brick.beep();
                    fprintf('YELLOW detected. Stopping program.\n');
                    break;
                end
            end
        end

        % ---------- TOUCH SENSOR CHECK ----------
        if brick.TouchPressed(TOUCH_PORT)
            brick.beep();
            fprintf('Touch bump detected! Backing up and turning...\n');

            % back up
            brick.MoveMotor(LEFT_MOTOR, +40 + 5);
            brick.MoveMotor(RIGHT_MOTOR, +40);
            pause(backupDuration);
            brick.StopAllMotors('Brake');
            pause(0.05);

            % ultrasonic distances
            dLeft  = brick.UltrasonicDist(US_LEFT_PORT);  if dLeft==255,  dLeft=1000; end
            dRight = brick.UltrasonicDist(US_RIGHT_PORT); if dRight==255, dRight=1000; end

            % choose turn direction
            if dLeft > dRight
                brick.MoveMotor(LEFT_MOTOR, +turnSpeed + 5);
                brick.MoveMotor(RIGHT_MOTOR, -turnSpeed);
                fprintf('Turning LEFT (dLeft=%.1f, dRight=%.1f)\n', dLeft,dRight);
            else
                brick.MoveMotor(LEFT_MOTOR, -turnSpeed - 5);
                brick.MoveMotor(RIGHT_MOTOR, +turnSpeed);
                fprintf('Turning RIGHT (dLeft=%.1f, dRight=%.1f)\n', dLeft,dRight);
            end

            pause(turnDuration);
            brick.StopAllMotors('Brake');

            % resume forward
            brick.MoveMotor(LEFT_MOTOR, forwardSpeed - 5);
            brick.MoveMotor(RIGHT_MOTOR, forwardSpeed);
            pause(0.15);
        end
    end

    fprintf('Main loop exited. Motors stopped.\n');

catch ME
    warning('Exception caught: stopping motors.');
    try
        brick.StopAllMotors('Coast');
    catch
    end
    rethrow(ME);
end

% Final cleanup
brick.StopAllMotors('Brake');
brick.beep();
fprintf('Script finished.\n');
