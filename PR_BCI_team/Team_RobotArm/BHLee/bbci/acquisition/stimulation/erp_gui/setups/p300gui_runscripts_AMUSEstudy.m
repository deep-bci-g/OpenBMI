% Different runscripts that can be accessed through the GUI
global VP_SCREEN;
clear exp_opt;
clear exp_res;

%volume = [0.05 0.036 0.043 0.047 0.054 0.05];   

if ~exist('simulate_run', 'var'),
    simulate_run = 0;
end

switch do_action,
    case 'give_available_experiments',
        available_experiments = {'Oddball', 'Show sounds', 'Calibration', 'Keyboard entry', 'Session 1', 'Session 2-1', 'Session 2-2'};
        requires_online = [0 0 0 1 1 1];
        feedback_type = 'matlab';
        available_parameters = {{'nrStimuli', 200, 'perc_dev', .2}, ...
            {}, ...
            {'isi', 175, 'maxRounds', 15, 'nrExtraStimuli', 3, 'requireResponse', 1}, ...
            {'isi', 175, 'maxRounds', 15, 'trial_pause', 3, 'spellString', 'BBCI'}, ...
            {'isi', 175, 'maxRounds', 15, 'trial_pause', 3, 'spellString', 'BBCI', 'randomClass', 0}, ...
            {'isi', 175, 'maxRounds', 15, 'trial_pause', 3, 'spellString', 'BBCI', 'randomClass', 0}, ...
            {'isi', 175, 'maxRounds', 15, 'trial_pause', 3, 'spellString', 'BBCI', 'randomClass', 0}, ...            
            };
        
    case 'Oddball'
        clear exp_opt;
%         glo_opt.calibrated = diag(volume);
        glo_opt.toneDuration = 40;
        glo_opt.speakerSelected = [6 2 4 1 5 3];
        glo_opt.language = 'german';        
        setup_spatialbci_GLOBALgui;
        figure(99);

        exp_opt = set_defaults(glo_opt, gui_set_opts);
        exp_opt = set_defaults(exp_opt, ...
            'nrStimuli', 200, ...
            'perc_dev', 20/100, ...
            'alternative_placing', 1, ...
            'require_response', 0, ...
            'bv_host', 'localhost', ...
            'isi', 1000, ...
            'filename', 'oddballStandardMessung', ...
            'speech_intro', '', ...
            'fixation', 1, ...
            'vp_screen', [-1920 0 1920 1200], ...
            'msg_fin', 'End', ...
            'msg_intro', 'Entspannen', ...
            'speech_dir', 'C:\svn\bbci\acquisition\data\sound\german\upSampled', ...
            'fs', 44100, ...
            'speaker_number', 6, ...
            'countdown', 0, ...
            'impendances', 0, ...
            'use_speaker', 1, ...            
            'cue_std', stimutil_generateTone(500, 'harmonics', 7, 'duration', 50, 'pan', 1, 'fs', 44100, 'rampon', 10, 'rampoff', 10), ...
            'cue_dev', stimutil_generateTone(1000, 'harmonics', 7, 'duration', 50, 'pan', 1, 'fs', 44100, 'rampon', 10, 'rampoff', 10));
        
        exp_opt.cue_dev = exp_opt.cue_dev * exp_opt.calibrated(exp_opt.use_speaker, exp_opt.use_speaker);
        exp_opt.cue_std = exp_opt.cue_std * exp_opt.calibrated(exp_opt.use_speaker, exp_opt.use_speaker);
        
        VP_SCREEN = exp_opt.vp_screen;
        
        if simulate_run,
            exp_opt.bv_host = '';
            exp_opt.filename = '';
            exp_opt.test = 1;          
        end
        stim_oddballAuditory(exp_opt.nrStimuli, exp_opt);

    case 'Show sounds'
        clear exp_opt glo_opt;
%         glo_opt.calibrated = diag(volume);
        glo_opt.toneDuration = 40;
        glo_opt.speakerSelected = [6 2 4 1 5 3];
        glo_opt.language = 'german';
        setup_spatialbci_GLOBALgui;
%         glo_opt.volume = volume';
        
        util_speakerCalibration(glo_opt);
        
        
    otherwise,
        % global options, set for each run
        clear exp_opt glo_opt;
%         glo_opt.calibrated = diag(volume);
        glo_opt.toneDuration = 40;
        glo_opt.speakerSelected = [6 2 4 1 5 3];
        glo_opt.language = 'german';
        setup_spatialbci_GLOBALgui;
        
        exp_opt = set_defaults(glo_opt, gui_set_opts);
        exp_opt = set_defaults(exp_opt, ...
            'isi', 175, ...
            'isi_jitter', 0, ...
            'countdown', 0, ...
            'repeatTarget', 3, ...
            'text_nrCounted', 'Wie vielen haben Sie gez�hlt?', ...
            'vp_screen', [-1920 0 1920 1200], ...
            'maxRounds', 15, ...
            'trial_pause', 3, ...
            'startup_pause', 3, ...
            'impendances', 0);

        VP_SCREEN = exp_opt.vp_screen;
        figure(99)

        switch do_action,
            case 'Calibration', 
                if isfield(exp_opt, 'spellString'),
                    exp_opt = rmfield(exp_opt, 'spellString');
                end
                exp_opt = set_defaults(exp_opt, ...
                    'filename', 'OnlineTrainFile', ...
                    'itType', 'fixed', ...
                    'mode', 'copy', ...
                    'application', 'TRAIN', ...
                    'nrRounds', 2, ...
                    'requireResponse', 1, ...
                    'useSpeech', 0, ...
                    'visualize_text', 0, ...                    
                    'nrExtraStimuli', 3, ...
                    'responseOffset', 100, ...
                    'sayLabels', 0, ...
                    'sayResult', 0, ...
                    'appPhase', 'train');

            case 'Keyboard entry',
                exp_opt = set_defaults(exp_opt, ...
                    'filename', '', ...
                    'itType', 'fixed', ...
                    'mode', 'free', ...
                    'application', 'HEXO_spell', ...
                    'useSpeech', 1, ...
                    'sayResult', 1, ...
                    'sayLabels', 1, ...
                    'spellString', 'BBCI', ...
                    'visualize_hexo', 1, ...
                    'visualize_text', 1, ...
                    'visualize_result', 0, ...
                    'fake_feedback', 0, ...
                    'no_feedback', 0, ...
                    'mask_errors', 0, ...
                    'auto_correct', 0, ...
                    'auto_target', 0, ...
                    'errorPRec', 1, ...
                    'errorPTrig', 200, ...
                    'dataPort', 12345, ...
                    'appPhase', 'online', ...
                    'bv_host', '', ...
                    'test', 1, ...
                    'doLog', 0, ...
                    'debugClasses', 1);                

            case 'Session 1',
                exp_opt = set_defaults(exp_opt, ...
                    'filename', 'OnlineRunSess1', ...
                    'itType', 'fixed', ...
                    'mode', 'free', ...
                    'application', 'HEXO_spell', ...
                    'useSpeech', 1, ...
                    'sayResult', 1, ...
                    'sayLabels', 1, ...
                    'spellString', 'BBCI', ...
                    'visualize_hexo', 0, ...
                    'visualize_text', 1, ...
                    'visualize_result', 0, ...
                    'fake_feedback', 0, ...
                    'no_feedback', 0, ...
                    'mask_errors', 0, ...
                    'auto_correct', 0, ...
                    'auto_target', 0, ...
                    'errorPRec', 1, ...
                    'errorPTrig', 200, ...
                    'dataPort', 12345, ...
                    'appPhase', 'online');
                
            case 'Session 2-1'
                tmp = load([TODAY_DIR 'bbci_classifier.mat']);
                exp_opt = set_defaults(exp_opt, ...
                    'filename', 'OnlineRunSess21', ...
                    'itType', 'adaptive', ...
                    'mode', 'free', ...
                    'application', 'HEXO_spell', ...
                    'useSpeech', 1, ...
                    'sayResult', 1, ...
                    'sayLabels', 0, ...
                    'spellString', 'AZ', ...
                    'visualize_hexo', 1, ...
                    'visualize_text', 1, ...
                    'visualize_result', 0, ...
                    'fake_feedback', 0, ...
                    'no_feedback', 0, ...
                    'mask_errors', 0, ...
                    'auto_correct', 0, ...
                    'auto_target', 0, ...
                    'errorPRec', 1, ...
                    'errorPTrig', 200, ...
                    'dataPort', 12345, ...
                    'sendResultTrigger', 1, ...
                    'probThres', tmp.bbci.thresholds, ...
                    'appPhase', 'online');
                
            case 'Session 2-2',
                tmp = load([TODAY_DIR 'bbci_classifier.mat']);                
                exp_opt = set_defaults(exp_opt, ...
                    'filename', 'OnlineRunSess22', ...
                    'itType', 'adaptive', ...
                    'mode', 'free', ...
                    'application', 'HEXO_spell', ...
                    'useSpeech', 1, ...
                    'sayResult', 1, ...
                    'sayLabels', 0, ...
                    'spellString', 'AZ', ...
                    'visualize_hexo', 0, ...
                    'visualize_text', 1, ...
                    'visualize_result', 0, ...
                    'fake_feedback', 0, ...
                    'no_feedback', 0, ...
                    'mask_errors', 0, ...
                    'auto_correct', 0, ...
                    'auto_target', 0, ...
                    'errorPRec', 1, ...
                    'errorPTrig', 200, ...
                    'testConnect', 0, ...
                    'dataPort', 12345, ...
                    'sendResultTrigger', 1, ...                
                    'probThres', tmp.bbci.thresholds, ...
                    'appPhase', 'online');                                                            
        end
        
        if simulate_run,
            exp_opt.bv_host = '';
            exp_opt.filename = '';
            exp_opt.test = 1;
            exp_opt.doLog = 0;
            exp_opt.randomClass=1;
%             exp_opt.appPhase = 'train';            
        end
        %start the actual stuff
        exp_res = auditory_MainRoutine(exp_opt);
end