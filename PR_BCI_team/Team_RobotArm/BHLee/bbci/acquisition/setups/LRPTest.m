%% Arrow Feedback Config

fb_opt_int.g_rel =  1;
fb_opt_int.g_ab   = 1;
fb_opt.control = 'relative';

fb_opt_int.durationUntilBorder = 1000;
fb_opt_int.durationPerTrial = 4000;
fb_opt_int.durationIndicateGoal = 1000;
fb_opt_int.trials = 50;
fb_opt_int.pauseAfter = 50;
fb_opt_int.pauseDuration = 9000;
fb_opt.availableDirections =  ['right', 'foot'];
fb_opt_int.FPS =  60;
fb_opt.fullscreen =  'True';
fb_opt_int.screenWidth =  1000;
fb_opt_int.screenHeight =  700;
fb_opt_int.countdownFrom = 2;
fb_opt_int.hitMissDuration =  1000;
fb_opt.dampedMovement = 'False';
fb_opt.showPunchline = 'True';
fb_opt.damping = 'linear';
%fb_opt.damping = 'distance';
            
%fb_opt.arrowPointlist = [(0.5,0), (0.5,.33), (1,0.33), (1,0.66), (0.5,0.66), (0.5,1), (0,0.5)];
fb_opt.arrowColor = [127, 127, 127];
fb_opt.borderColor = fb_opt.arrowColor;
fb_opt.backgroundColor = [64, 64, 64];
fb_opt.cursorColor = [100, 149, 237];
fb_opt.fontColor = fb_opt.cursorColor;
fb_opt.countdownColor = [237, 100, 148];
fb_opt.punchLineColor = fb_opt.cursorColor;
fb_opt.punchLineColorImpr = [100, 200 , 100];  % if punchline is improved
        
fb_opt.punchlineThickness = 5;   % in pixels 
fb_opt.borderWidthRatio = 0.4;     % in pixels
fb_opt.punchlinePos1 = 0;
fb_opt.punchlinePos2 = 0;

fb_opt.availableDirections= {'left','foot'};



%% Init and record calibration data (see run_season11.m)
%% - Preparation
%bvr_sendcommand('checkimpedances');
%fprintf('\nPrepare cap. Press <RETURN> when finished.\n');
%pause

%bvr_startrecording(['impedances_beginning' VP_CODE]);
%pause(1);
%bvr_sendcommand('stoprecording');


nRuns= 1;
setup_file= 'season11\cursor_adapt_pcovmean.setup';
setup= nogui_load_setup(setup_file);
today_vec= clock;
today_str= sprintf('%02d_%02d_%02d', today_vec(1)-2000, today_vec(2:3));
tmpfile= [TODAY_DIR 'adaptation_pcovmean_Lap_' today_str];
%tag_list= {'LR', 'LF', 'FR'};


tag_list= {'LR'};
all_classes= {'left', 'right', 'foot'};



for ri= 1:nRuns,
 for ti= 1:length(tag_list),  
  CLSTAG= tag_list{ti};
  cmd_init= sprintf('VP_CODE= ''%s''; TODAY_DIR= ''%s''; VP_SCREEN= [%d %d %d %d]; ', VP_CODE, TODAY_DIR, VP_SCREEN);
  bbci_cfy= [TODAY_DIR 'Lap_C3z4_bp2_' CLSTAG];
  cmd_bbci= ['dbstop if error ; bbci_bet_apply(''' bbci_cfy ''');'];
  %system(['matlab -nosplash -r "' cmd_init 'setup_LRPTest; ' cmd_bbci '; exit &']);
  %system(['matlab -nosplash -r "' cmd_init cmd_bbci '; exit &']);
  pause(15)
  ci1= find(CLSTAG(1)=='LRF');
  ci2= find(CLSTAG(2)=='LRF');
  classes= all_classes([ci1 ci2]);
  settings_bbci= {'start_marker', 210, ...
                  'quit_marker', 254, ...
                  'feedback', '1d', ... % This is not the name of the feedback! Just for postprocessing (Guido)
                  'fb_port', 12345, ...
                  'adaptation.policy', 'pcovmean', ...
                  'adaptation.adaptation_ival', [1000 2000], ...  % Vgl mit bbci.setup_opts.ival
                  'adaptation.tmpfile', [tmpfile '_' CLSTAG], ...
                  'adaptation.mrk_start', {ci1, ci2}, ...
                  'adaptation.load_tmp_classifier', 1,...
                  'adaptation.UC_mean', 0.075,...
                  'adaptation.UC_pcov', 0.03}; % CARMEN
  %                  'adaptation.adaptation_ival', [750 4500], ...  % Vgl mit bbci.setup_opts.ival              
  %'adaptation.load_tmp_classifier', ri>1,...
  settings_fb= {'classes', classes, ...
                'trigger_classes_list', {'left','right','foot'},  ...
                'pause_msg', [CLSTAG(1) ' vs. ' CLSTAG(2)], ...
                'trials_per_run', 30, ... 
                'break_every', 20,...
                'cursor_visible',0 ...
                'duration_blank', 3000}; % break between trials
%   settings_fb= {'classes', classes, ...
%                 'trigger_classes_list', {'left','right','foot'},  ...
%                 'pause_msg', [CLSTAG(1) ' vs. ' CLSTAG(2)], ...
%                 'trials_per_run', 5, ... 
%                 'break_every', 5,...
%                 'cursor_visible',0 ...
%                 'duration_blank', 500}; % break between trials
  %setup.graphic_player1.feedback_opt= overwrite_fields(setup.graphic_player1.feedback_opt, settings_fb);
  %setup.control_player1.bbci= overwrite_fields(setup.control_player1.bbci, settings_bbci);
  %setup.general.savestring= ['imag_fbarrow_LapC3z4_' CLSTAG];
  %nogui_send_setup(setup);
%  fprintf('Press <RETURN> when ready to start Run %d�%d: classes %s and wait (press <RETURN only once!).\n', ri, ti, CLSTAG);
%  pause; fprintf('Ok, starting ...\n');
  fprintf('Starting Run %d %d: classes %s.\n', ceil(ri/2), ti+3*mod(ri-1,2), CLSTAG);
  if ri+ti>2,
    pause(5);  %% Give time to display class combination, e.g. 'L vs R'
  end
  %nogui_start_feedback(setup, 'impedances',ri+ti==2);

  filename= bvr_startrecording(['Lap_C3z4_bp2_', CLSTAG],  'impedances',ri+ti==2);
  setup.savemode = true;
  
 PYFF_DIR = 'C:\svn\pyff\src';
 general_port_fields= struct('bvmachine','127.0.0.1',...
                            'control',{{'127.0.0.1',12471,12487}},...
                            'graphic',{{'',12487}});
 general_port_fields.feedback_receiver= 'pyff';
 pyff('startup', 'gui',0, 'dir',PYFF_DIR);
 pyff('init','FeedbackCursorArrow')
 %fprintf('Select FeedbackCursorError in Pyff GUI, press Init button and then press <ENTER> here.\n');
 pause;
 pause(2)
 fb_opt= []; fb_opt_int= [];

 fb_opt.availableDirections= {'right','left'};
 fb_opt_int.pauseAfter = 20; 
 fb_opt_int.hitMissDuration =  2000;
 fb_opt_int.trials = 50;
 
 pyff('set', fb_opt);
 pyff('setint', fb_opt_int);
 pyff('play')
 
%{
bbci.train_file= strcat(bbci.subdir, '/imag_fbarrow_LapC3z4_LR*');
bbci.setup_opts.model= {'RLDAshrink', 'gamma',0, 'scaling',1, 'store_means',1};
bbci.setup_opts.clab= {'F3,4,5,6','FC5-6','C5-6','CP5-6','P5,1,2,6'};
bbci.save_name= strcat(TODAY_DIR, 'bbci_classifier_lrp');
bbci.adaptation.running= 1;
bbci.adaptation.policy= 'pmean';
%bbci.adaptation.offset= bbci.setup_opts.ival(1);
bbci_bet_finish
bbci_setup= bbci.save_name;
bbci.adaptation.adaptation_ival= bbci.setup_opts.ival;
bbci_setup= bbci.save_name;
 

  bbci_bet_apply(bbci_setup, 'bbci.feedback','1d', 'bbci.fb_port', 12345, 'bbci.start_marker',31, 'bbci.quit_marker',101);
%}
  fprintf('type dbcont when feedback has finished (windows must have closed).\n');
  keyboard; fprintf('Thank you for letting me know ...\n');
 end
end

%% Analyze Data, Create & Save Classifier 

% TODO: noch notwendig?? Ev. nur um adaptation zu steuern...
%setup_file= 'season10\cursor_adapt_pcovmean.setup';
%setup= nogui_load_setup(setup_file);


bbci= bbci_default;
bbci.withgraphics = 1;
bbci.setup= 'cspauto';
bbci.train_file= strcat(bbci.subdir, '/Lap_C3z4_bp2_LR*');
bbci.setup_opts.model= {'RLDAshrink', 'gamma',0, 'scaling',1, 'store_means',1};
bbci.setup_opts.clab= {'F3,4,5,6','FC5-6','C5-6','CP5-6','P5,1,2,6'};
bbci.save_name= strcat(TODAY_DIR, 'bbci_classifier_lrp');
bbci_bet_prepare
bbci_bet_analyze

fprintf('Type ''dbcont'' to save classifier and proceed.\n');
keyboard
close all
bbci.adaptation.running= 0;
bbci.adaptation.load_tmp_classifier = 1;
bbci.adaptation.policy= 'pcovmean';
%bbci.adaptation.offset= bbci.setup_opts.ival(1);
bbci.adaptation.adaptation_ival= bbci.setup_opts.ival;
bbci.adaptation.UC= 0.05;
bbci_bet_finish
bbci_setup= bbci.save_name;

%% Use Classifier for PYFF Feedback: Start PYFF 

PYFF_DIR = 'C:\svn\pyff\src';
general_port_fields= struct('bvmachine','127.0.0.1',...
                            'control',{{'127.0.0.1',12471,12487}},...
                            'graphic',{{'',12487}});
general_port_fields.feedback_receiver= 'pyff';
pyff('startup', 'gui',1, 'dir',PYFF_DIR);
fprintf('Select BrainPong2 in Pyff GUI, press Init button and then press <ENTER> here.\n');
pause;
fb_opt= []; fb_opt_int= [];
fb_opt.availableDirections= {'left','foot'};

% fb_opt_int.screenPos= VP_SCREEN;
% primary_screen= get(0, 'ScreenSize');
% fb_opt_int.screenPos(2)= primary_screen(4)-VP_SCREEN(4);
% fb_opt.trials= 400;
% fb_opt.pauseAfter= 25;
% fb_opt.bowlSpeed= 2.5;
% fb_opt.g_rel=0.95;
% fb_opt.font_path=[PYFF_DIR 'Feedbacks\BrainPong2\pirulen.ttf'];
% fb_opt.jitter= 0.1;  %% -> nicht nur ganz-links, ganz-rechts Positionen
% fb_opt_int.countdownFrom= 10;
%pyff('init','BrainPong2');  %% -> us this, if Pyff is started without GUI




pause(2)
pyff('set', fb_opt);
pyff('setint', fb_opt_int);
pyff('play')
% comment the following line, to skip the GUI. If useful, then probably
% only to set the classifier bias
%system(['matlab -r "dbstop if error; matlab_control_gui(''season10/cursor_adapt_pmean'', ''classifier'',''' bbci_setup ''');" &']);
bbci_bet_apply(bbci_setup, 'bbci.feedback','1d', 'bbci.fb_port', 12345, 'bbci.start_marker',31, 'bbci.quit_marker',101);
pause(3)
pyff('stop');
pyff('quit');

pause