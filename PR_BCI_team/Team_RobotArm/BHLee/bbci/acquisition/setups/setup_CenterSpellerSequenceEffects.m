session_name= 'CenterSpellerSequenceEffects';

addpath([BCI_DIR 'acquisition/setups/' session_name]);
fprintf('\n\nWelcome to the study "%s"!\n\n', session_name);

%% Start BrainVisionn Recorder, load workspace and check triggers
system('c:\Vision\Recorder\Recorder.exe &'); pause(1);
bvr_sendcommand('stoprecording');
bvr_sendcommand('loadworkspace', 'ActiCap_64ch_linked_mastoids');
try
  bvr_checkparport('type','S');
catch
  error('Check amplifiers (all switched on?) and trigger cables.');
end

%% Check VP_CODE, initialize counter, and create data folder
if isempty(VP_CODE),
  warning('VP_CODE undefined - assuming fresh subject');
end
if strcmp(VP_CODE, 'Temp');
  VP_NUMBER= 1;
else
  VP_COUNTER_FILE= [DATA_DIR session_name '_VP_Counter'];
  % delete([VP_COUNTER_FILE '.mat']);   %% for reset
  if exist([VP_COUNTER_FILE '.mat']),
    load(VP_COUNTER_FILE, 'VP_NUMBER');
  else
    VP_NUMBER= 0;
  end
  VP_NUMBER= VP_NUMBER + 1;
  fprintf('VP number %d.\n', VP_NUMBER);
end
global TODAY_DIR
acq_makeDataFolder;

%% Settings for online classification
general_port_fields= struct('bvmachine','127.0.0.1',...
                            'control',{{'127.0.0.1',12471,12487}},...
                            'graphic',{{'',12487}});
general_port_fields.feedback_receiver= 'pyff';
bbci= [];
bbci.setup= 'ERP_Speller';
bbci.feedback= 'ERP_Speller';
bbci.classDef= {[31:49], [11:29];
                'target', 'nontarget'};
bbci.start_marker= [240];           %% Countdown start
bbci.quit_marker= [2 4 8 246 247 255];  %% Push button or end markers
bbci.pause_after_quit_marker= 1000;
bbci_default = bbci;

%VP_SCREEN = [0 0 1920 1200];
VP_SCREEN = [0 0 1280 1024];
fprintf(['Type ''run_' session_name ''' and press <RET>\n']);
