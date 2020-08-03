

%%% start Pyff
pyff('startup','a',[BCI_DIR 'python\pyff\src\Feedbacks'], 'bvplugin', 0);


%%% Calibration of SPEED

pyff('init','HandWorkStation'); pause(.5)
pyff('set','MODE',2);
pyff('set','DATA_DIR',TODAY_DIR);
pyff('setint','screen_pos',VP_SCREEN);

fprintf('Press <RETURN> to start HandWorkStation SPEED Calibration\n'); pause;
fprintf('Ok, starting...\n'), close all

pyff('play');
stimutil_waitForMarker(RUN_END);

fprintf('HandWorkStation Calibration_1 finished.\n')
pyff('quit'); pause(1);


