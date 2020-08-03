%% InputReader test
% This block tests if the input reader finds the wheel and the pedal for
% the data recording
fprintf('Testing the InputReader.\n');
fprintf('Press <RETURN> to start InputReader test.\n');
pause; fprintf('Ok, starting...\n');
r = dos('C:\bbci\torcs-1.3.1\runtime\InputReader.exe test');
if(r ~= 0)
  error('The InputReader could not find the wheel or the pedal please check the usb connections or restart the system.');
else
  fprintf('Input Reader can read from wheel and pedal. Press <RETURN> to continue.\n');
  pause; fprintf('Ok, ...\n');
end

%% Prepare cap

bvr_sendcommand('checkimpedances');
fprintf('Prepare cap. Press <RETURN> when finished.\n');
pause

 TORCS_DIR = 'C:\bbci\torcs-1.3.1\runtime';


%% -newblock
[seq, wav, opt]= setup_season10_artifacts_demo('clstag', '');
fprintf('Press <RETURN> to start TEST artifact measurement.\n');
pause; fprintf('Ok, starting...\n');
stim_artifactMeasurement(seq, wav, opt, 'test',1);
[seq, wav, opt]= setup_season10_artifacts('clstag', '');
fprintf('Press <RETURN> to start artifact measurement.\n');
pause; fprintf('Ok, starting...\n');
stim_artifactMeasurement(seq, wav, opt);

%% Brake oddball test
setup_carrace_season1_braking;
fprintf('Press <RETURN> to TEST brake-oddball.\n');
pause; fprintf('Ok, starting...\n');
stim_oddballVisual(10, opt, 'test',1);
fprintf('Press <RETURN> to start brake-oddball.\n');
pause; fprintf('Ok, starting...\n');
stim_oddballVisual(N, opt);

%% Relaxation
fprintf('\n\nRelax recording.\n');
[seq, wav, opt]= setup_season10_relax;
fprintf('Press <RETURN> to start RELAX measurement.\n');
pause; fprintf('Ok, starting...\n');
stim_artifactMeasurement(seq, wav, opt);

%% Brake oddball with EEG
setup_carrace_season1_braking;
fprintf('Press <RETURN> to start brake-oddball.\n');
pause; fprintf('Ok, starting...\n');
stim_oddballVisual(N, opt);
pause(2);

%% Self paced breaking with EEG
stimutil_fixationCross;


fprintf('Press <RETURN> to start self-paced braking.\n');
pause; 
fprintf('Starting Local InputReader.\n');
dos('C:\bbci\torcs-1.3.1\runtime\InputReader.exe local BreakSync C:\bbci\torcs-1.3.1\runtime\ &');
fprintf('Ok, starting...\n');
fprintf('Ok.\n');
pause(1);
cd(TODAY_DIR)
bvr_startrecording('selfpaced_braking');
pause(6*60 + 10);
bvr_sendcommand('stoprecording');
fprintf('Press <RETURN> to stop the InputReader.\n');
pause;fprintf('Ok, stoping...\n');
system('taskkill /F /IM InputReader.exe');
fprintf('Ok.\n');

%- Load torcs configuration
cd(TORCS_DIR)
configFolder = input('Type the name of the torcs config folder for the experiment(Enter for no config change): ');
if(strcmp(configFolder,'') == 0)
  absConfigFolder = [TORCS_DIR '\' configFolder '\*'];
  fprintf('Copy files from: %s', absConfigFolder);
  copyfile(absConfigFolder,[TORCS_DIR '\']);
end
cd(TODAY_DIR)

%-Starting torcs
fprintf('Starting Torcs.\n');
cd(TORCS_DIR)
dos('wtorcs.exe &');
cd(TODAY_DIR)

%-newblock
fprintf('Start demo mode of TORCS (see readme file).\n');
fprintf('Press <RETURN> to start carrace observation.\n');
pause; fprintf('Ok, starting...\n');
bvr_startrecording('carrace_observation');
pause(4*60);
bvr_sendcommand('stoprecording');
pause(5);

%-Startign server InputReader
fprintf('Starting Server InputReader.\n');
dos('C:\bbci\torcs-1.3.1\runtime\InputReader.exe server &');
fprintf('Ok.\n');

%-newblock
fprintf('Start player mode of TORCS (see readme file).\n');
fprintf('Press <RETURN> to start carrace run 1.\n');
pause; fprintf('Ok, starting...\n');
bvr_startrecording('carrace_drive');
pause(45*60);
bvr_sendcommand('stoprecording');
pause(5);


%-newblock
fprintf('Start player mode of TORCS (see readme file).\n');
fprintf('Press <RETURN> to start carrace run 2.\n');
pause; fprintf('Ok, starting...\n');
bvr_startrecording('carrace_drive');
pause(45*60);
bvr_sendcommand('stoprecording');
pause(5);

%-newblock
fprintf('Start player mode of TORCS (see readme file).\n');
fprintf('Press <RETURN> to start carrace run 3.\n');
pause; fprintf('Ok, starting...\n');
bvr_startrecording('carrace_drive');
pause(45*60);
bvr_sendcommand('stoprecording');
pause(5);
