myname= mfilename;
session_name= myname(5:end);

fprintf('\n\nWelcome to the study "%s"!\n\n', session_name);
startup_new_bbci_online;
addpath([BCI_DIR 'acquisition/setups/' session_name]);

%% Start BrainVisionn Recorder, load workspace and check triggers
system('start Recorder'); pause(1);
bvr_sendcommand('stoprecording');
bvr_sendcommand('loadworkspace', session_name);
try
  bvr_checkparport('type','S');
catch
  error('Check amplifiers (all switched on?) and trigger cables.');
end


%% Create data folder
global TODAY_DIR
acq_makeDataFolder;
VP_NUMBER= acq_vpcounter(session_name, 'new_vp');

RUN_END= [246 255];

%% Define some variables
clear bbci_default
bbci_default.source.acquire_fcn= @bbci_acquire_bv;
bbci_default.source.acquire_param= {struct('fs', 100)};
bbci_default.log.output= 'screen&file';
bbci_default.log.classifier= 1;
bbci_default.control.fcn= @bbci_control_ERP_Speller_binary;
bbci_default.feedback.receiver = 'pyff';
bbci_default.quit_condition.marker= RUN_END;

BC= [];
BC.folder= TODAY_DIR;
BC.read_param= {'fs',100};
BC.marker_fcn= @mrk_defineClasses;
BC.marker_param= {{[31:49], [11:29]; 'target', 'nontarget'}};
BC.save.file= 'bbci_classifier_ERP_Speller';
BC.fcn= @bbci_calibrate_ERP_Speller;
BC.settings= struct('nClasses', 6, ...
                    'nSequences', 5, ...
                    'mrk2feedback_fcn', @(x)(1+mod(x-11,10)));
BC.save.figures=1;

bbci= struct('calibrate', BC);

% Display feedback on laptop screen
%screen_pos= get(0, 'ScreenSize');
%VP_SCREEN= [0 0 screen_pos(3:4)];

% External display has to be configured as PRIMARY display:
% Press Fn-F7 until only the external display is used.
% Then use Display Properties to add laptop display.
% External display has to be *TOP ALIGNED* with internal display
VP_SCREEN= [0 0 1920 1200];

bvr_sendcommand('viewsignals');

eval(['run_' session_name '_script']);
