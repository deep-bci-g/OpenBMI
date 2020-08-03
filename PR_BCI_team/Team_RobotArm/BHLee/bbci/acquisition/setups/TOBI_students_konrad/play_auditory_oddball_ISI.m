function varout = play_auditory_oddball_ISI(cue_sequence, opt);%play_auditory_oddball_ISI - Stimulus Presentation for Auditory Oddball%%%Arguments:% cue_sequence: vector specifying the sequence of nontarget (0) and target% (1) cues, e.g. [0 0 0 1 0 0 1 0 0 0 0 1 0 0]% OPT: Struct or property/value list of optional properties:% 'perc_dev': Scalar: percentage of deviants% 'isi':      Scalar: inter-stimulus interval [ms]% 'require_response': Boolean: if true, a response stimulus is expected%    within the ISI.% 'response_markers': Cell array 1x2 of strings: description of response%    markers expected for STD and DEV stimuli. Default: {'R 16','R  8'}.% 'cue_std', Cell array of strings: file name of WAV file for%    standard stimuli.% 'cue_dev', Cell array of strings: file name of WAV file for%    deviant stimuli.% 'msg_vpos': Scalar. Vertical position of message text object. Default: 0.57.% 'msg_spec': Cell array. Text object specifications for message text object.%   Default: {'FontSize',0.1, 'FontWeight','bold', 'Color',[.9 0 0]})% 'pahandle': Handle to a preassigned PsychSound ASIO soundcard. Default%   ([]) uses the standerd Matlab routines for audio playback. Please note%   that a PsychSound card has a preallocated fs, so speech and stimuli%   should match this.% 'speaker_number': In order for the sound matrix to match the predefined%   number of speakers, this should be set if pahandle is set.% 'use_speaker': Defines which speaker is used for presentation (if%   pahandle is set).%%Triggers:%   1: STD stimulus%   2: DEV stimulus% 251: beginning of relaxing period% 252: beginning of main experiment ue(after countdown)% 253: end of main experiment% 254: end%% 12/09: added support for PsychPortAudio. Martijn%%GLOBZ: BCI_DIR, VP_CODEglobal BCI_DIR VP_CODE SOUND_DIRopt= set_defaults(opt, ...                  'filename', 'auditory_std_oddbal', ...                  'test', 0, ...                  'impedances', 1, ...                  'isi', 1500,...                  'isi_jitter', 0, ...                  'std_marker_base', 1, ...                  'dev_marker_base', 21, ...                  'require_response', 1, ...                  'response_markers', {'R 16', 'R  8'}, ...                  'avoid_dev_repetitions', 0, ...                  'alternative_placing', 0, ...                  'fixation', 0, ...                  'bv_host', 'localhost', ...                  'countdown', 3, ...                  'duration_intro', 1000, ...                  'speech_dir', [SOUND_DIR 'english'], ...                  'fs', 22050, ...                  'speech_intro', '', ...                  'msg_intro','', ...                  'handle_background', [], ...                  'msg_fin','fin', ...                  'pahandle', [], ...                  'speaker_number', 8, ...                  'use_speaker', 1);N = length(cue_sequence);if ~iscell(opt.cue_dev),  opt.cue_dev= {opt.cue_dev};endif ~iscell(opt.cue_std),  opt.cue_std= {opt.cue_std};endif ischar(opt.cue_dev{1}),  if ~isabsolutepath(opt.cue_dev{1}),    opt.cue_dev= strcat(BCI_DIR, 'acquisition/data/sound/', opt.cue_dev);    opt.cue_std= strcat(BCI_DIR, 'acquisition/data/sound/', opt.cue_std);  end  for ii= 1:length(opt.cue_dev),    [opt.cue_dev{ii}, opt.fs]= ...        wavread([opt.cue_dev{ii} '.wav']);  end  for ii= 1:length(opt.cue_std),    [opt.cue_std{ii}, opt.fs]= ...        wavread([opt.cue_std{ii} '.wav']);  endendif ~isempty(opt.speech_intro),  [sound_intro.wav, sound_intro.fs]= ...      wavread([opt.speech_dir '/speech_' opt.speech_intro '.wav']);endfor ii= 1:opt.countdown,  [sound_counting(ii).wav, sound_counting(ii).fs]= ...      wavread([opt.speech_dir '/speech_' int2str(ii) '.wav']);end% % % if ~isempty(opt.bv_host),%   bvr_checkparport;% endif opt.fixation,  [H_cross, opt]= stimutil_fixationCross(opt);elseif isempty(opt.handle_background),  opt.handle_background= stimutil_initFigure(opt);endh_msg= stimutil_initMsg(opt);set(h_msg, 'String',opt.msg_intro, 'Visible','on');drawnow;waitForSync;if opt.test,  fprintf('Warning: test option set true: EEG is not recorded!\n');else  if ~isempty(opt.filename),    bvr_startrecording([opt.filename VP_CODE], 'impedances', opt.impedances);  else    warning('!*NOT* recording: opt.filename is empty');  end  ppTrigger(251);    %set(h_msg, 'String',opt.msg_relax);  pause(opt.duration_intro/1000);  set(h_msg, 'String',' ');  pause(1);  for ii= opt.countdown:-1:1,    if isempty(opt.pahandle),      wavplay(sound_counting(ii).wav, sound_counting(ii).fs, 'async');    else      stimutil_playMultiSound(sound_counting(ii).wav, 'placement', opt.use_speaker, 'pahandle', opt.pahandle, 'speakerCount', opt.speaker_number);    end        set(h_msg, 'String',sprintf('Start in %d s', ii));     drawnow;    pause(1);  end  set(h_msg, 'String',' ');  ppTrigger(252);  pause(1);endif opt.require_response,  response= zeros(N, 1);  correct= NaN*zeros(N, 1);  state= acquire_bv(1000, opt.bv_host);endwaitForSync;for i= 1:N,  if cue_sequence(i),    ci= ceil(rand*length(opt.cue_dev));    ppTrigger(opt.dev_marker_base + ci - 1);    if isempty(opt.pahandle),      wavplay(opt.cue_dev{ci}, opt.fs, 'async');    else      stimutil_playMultiSound(opt.cue_dev{ci}, 'placement', opt.use_speaker, 'pahandle', opt.pahandle, 'speakerCount', opt.speaker_number);    end         else    ci= ceil(rand*length(opt.cue_std));    ppTrigger(opt.std_marker_base + ci - 1);    if isempty(opt.pahandle),      wavplay(opt.cue_std{ci}, opt.fs, 'async');    else      stimutil_playMultiSound(opt.cue_std{ci}, 'placement', opt.use_speaker, 'pahandle', opt.pahandle, 'speakerCount', opt.speaker_number);    end         end  trial_duration= opt.isi + rand*opt.isi_jitter;  if opt.require_response,    t0= clock;    resp= [];    [dmy]= acquire_bv(state);  %% clear the queue    while isempty(resp) & 1000*etime(clock,t0)<trial_duration-50,      [dmy,bn,mp,mt,md]= acquire_bv(state);      for mm= 1:length(mt),        resp= strmatch(mt{mm}, opt.response_markers);        if ~isempty(resp),          continue;        end      end      pause(0.001);  %% this is to allow breaks    end    response(i)= etime(clock,t0);    if ~isempty(resp),      correct(i)= (resp==2-cue_sequence(i));    end    fprintf('%d:%d  (%d missed)\n', sum(correct==1), sum(correct==0), ...      sum(isnan(correct(1:i))));  end  waitForSync(trial_duration);endppTrigger(253);pause(1);if opt.require_response,  iGood= find(correct==1);  iBad= find(correct==0);  msg= sprintf('%d hits  :  %d errors  (%d missed)', ...               length(iGood), length(iBad), sum(isnan(correct)));  set(h_msg, 'String',msg, 'FontSize',0.5*get(h_msg,'FontSize'));    fprintf('%s\n', msg);  fprintf('|  average response time:  ');  if ~isempty(iGood),    fprintf('%.2f s on hits  | ', mean(response(iGood)));  end  if ~isempty(iBad),    fprintf('%.2f s on errors  |', mean(response(iBad)));  end  fprintf('\n');else  set(h_msg, 'String',opt.msg_fin);endppTrigger(254);pause(1);if ~opt.test & ~isempty(opt.filename),  bvr_sendcommand('stoprecording');end%play a tone to mark the end of a trial% --> participant knows that he is allowed to tell us his countswavplay(opt.cue_std{ci}, opt.fs/2, 'async');% pause(3);delete(h_msg);