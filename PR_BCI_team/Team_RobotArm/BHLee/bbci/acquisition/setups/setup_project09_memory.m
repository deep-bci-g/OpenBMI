if isempty(VP_CODE),
  warning('VP_CODE undefined - assuming fresh subject');
end


path([BCI_DIR 'acquisition/setups/project09_memory'], path);
fprintf('\n\nWelcome to BBCI project09_memory\n\n');
system('c:\Vision\Recorder\Recorder.exe &'); pause(1);

% Load Workspace into the BrainVision Recorder
%bvr_sendcommand('loadworkspace', ['season9_' lower(CLSTAG)]);

%still need to change the workspace for the BV 
bvr_sendcommand('loadworkspace', 'FastnEasy_temp_dense_64ch');
bvr_sendcommand('stoprecording');
try
  bvr_checkparport('type','S');
catch
  error('Check amplifiers (all switched on?) and trigger cables.');
end
global TODAY_DIR REMOTE_RAW_DIR
acq_makeDataFolder;
REMOTE_RAW_DIR= TODAY_DIR;

VP_SCREEN= [0 0 1024 768];
fprintf('Display resolution of secondary display must be set to 1024x768.\n');
fprintf('Type ''run_project09_memory'' and press <RET>.\n');