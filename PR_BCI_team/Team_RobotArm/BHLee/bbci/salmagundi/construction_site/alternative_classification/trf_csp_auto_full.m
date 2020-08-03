res_dir= [DATA_DIR 'results/alternative_transfer/'];

subdir_list= textread([BCI_DIR 'studies/season2/session_list_ext'], '%s');

clear perf
memo= cell(1,length(subdir_list));

for vp= 1:length(subdir_list),

  sub_dir= [subdir_list{vp} '/'];
  is= min(find(sub_dir=='_'));
  sbj= sub_dir(1:is-1);

  if ~exist([EEG_MAT_DIR sub_dir 'imag_1drfb' sbj '.mat'], 'file'),
    perf(vp)= NaN;
    continue;
  end

  %% load data of calibration (training) session
  clear cnt
  if strcmp(sbj, 'VPco'),
    [cnt,mrk,mnt]= eegfile_loadMatlab([sub_dir 'real' sbj]);
  else
    [cnt,mrk,mnt]= eegfile_loadMatlab([sub_dir 'imag_lett' sbj]);
  end

  %% get the two classes that have been used for feedback
  bbci= eegfile_loadMatlab([sub_dir 'imag_1drfb' sbj], 'vars','bbci');
  classes= bbci.classes;
  mrk= mrk_selectClasses(mrk, classes);
  
  %% preprocess data
  cnt= proc_selectChannels(cnt, 'not','E*');  %% do NOT use EMG, EOG
  csp_clab= {'not','Fp*','AF*','FT9,10','T9,10','TP9,10','OI*','I*'};
  cnt= proc_selectChannels(cnt, csp_clab);
  [mrk_clean, rClab, dmy, nfo]= ...
      reject_varEventsAndChannels(cnt, mrk, [500 4500]);
  fprintf('rejected: /%s/ -> %d trials and channels /', ...
          vec2str(apply_cellwise2(nfo.trials, 'length'), '%d', '/'), ...
          length(mrk.pos)-length(mrk_clean.pos));
  for cc= 1:length(nfo.chans),
    fprintf('%s/', vec2str(cnt.clab(nfo.chans{cc}),'%s',','));
  end
  cnt= proc_selectChannels(cnt, 'not', rClab);
  clear cnt_lap cnt_flt
%  [filt_b,filt_a]= butter(5, [7 30]/cnt.fs*2);
%  cnt_flt= proc_filt(cnt, filt_b, filt_a);
%  fv= makeEpochs(cnt_flt, mrk, [750 4000]);
%  clear cnt_flt
%  [fv, outl_idx]= proc_outl_var(fv, 'log',1, 'display',0);
%  mrk_clean= mrk_chooseEvents(mrk_clean, 'not',outl_idx);
%  fprintf('. %d outliers rejected', length(outl_idx));
  cnt_lap= proc_laplace(cnt);
  cnt_flt= proc_filt(cnt_lap, filt_b, filt_a);
  csp_ival= select_timeival(cnt_flt, mrk_clean);
  clear cnt_flt
  csp_band= select_bandnarrow(cnt_lap, mrk_clean, csp_ival);
  clear cnt_lap
  [filt_b,filt_a]= butter(5, csp_band/cnt.fs*2);
  cnt= proc_filt(cnt, filt_b, filt_a);
  csp_ival= select_timeival(cnt, mrk_clean);
  fv= makeEpochs(cnt, mrk_clean, csp_ival);
  clear cnt
  [fv, outl_idx]= proc_outl_var(fv, 'log',1, 'display',0);
  fprintf('. %d outliers rejected', length(outl_idx));
  csp_opt= struct('patterns', 3, ...
                  'score', 'fisher', ...
                  'selectPolicy', 'directorscut');
  [fv, csp_w, dmy, dmy, fi]= proc_rcsp(fv, csp_opt);
  fprintf('. Chose filters %s. ', vec2str(fi));
  fv= proc_variance(fv);
  fv= proc_logarithm(fv);

  C= trainClassifier(fv, 'LSR');

  %% evaluation of transfer: calibration -> feedback
  %% load and preprocess data of feedback session
  cnt= eegfile_loadMatlab([sub_dir 'imag_1drfb' sbj], 'vars','cnt');
  S= load([EEG_MAT_DIR sub_dir 'imag_1drfb' sbj '_mrk_1000']);
  mrk= S.mrk;  %% use markers for short-time windows
  ilen= S.opt_stw.win_len;
  cnt= proc_selectChannels(cnt, 'not','E*');
  cnt= proc_selectChannels(cnt, csp_clab);
  cnt= proc_selectChannels(cnt, 'not', rClab);
  cnt= proc_linearDerivation(cnt, csp_w, 'prependix','csp');
  cnt= proc_filt(cnt, filt_b, filt_a);

  fv= makeEpochs(cnt, S.mrk, [0 ilen]);
  fv= proc_variance(fv);
  fv= proc_logarithm(fv);
  memo{vp}.out= applyClassifier(fv, 'LSR', C);
  memo{vp}.label= fv.y;
  perf(vp)= loss_rocArea(fv.y, memo{vp}.out);
  fprintf('\n%10s  ->  %4.1f%%\n', sbj, 100*perf(vp));
end
save([res_dir 'csp_auto_full'], 'perf', 'memo', 'subdir_list');
