default_grd= sprintf(['scale,FC3,FC1,FCz,FC2,FC4,legend\n' ...
                     'C5,C3,C1,Cz,C2,C4,C6\n' ...
                     'CP5,CP3,CP1,CPz,CP2,CP4,CP6\n' ...
                     'P7,P5,P3,Pz,P4,P6,P8\n' ...
                     'PO7,PO3,O1,Oz,O2,PO4,PO8']);

default_crit= strukt('maxmin', 100, ...
                     'clab', {'EOG*','F9,10','Fp*'}, ...
                     'ival', [100 800]);
default_crit.ival(1)= max(opt.disp_ival(1), default_crit.ival(1));
default_crit.ival(2)= min(opt.disp_ival(2), default_crit.ival(2));

[opt, isdefault]= ...
    set_defaults(opt, ...
                 'clab', '*', ...
                 'cfy_maxival', [], ...
                 'reject_artifacts', 1, ...
                 'reject_artifacts_opts', {}, ...
                 'reject_channels', 1, ...
                 'reject_eyemovements', 0, ...
                 'reject_eyemovements_crit', default_crit, ...
                 'grd', default_grd, ...
                 'clab_erp', {'CPz'}, ...
                 'clab_rsq', {'CPz','PO7'}, ...
                 'widely_nontarget', 0, ...
                 'withclassification', 1);

clear fv*
clab= Cnt.clab(chanind(Cnt, opt.clab));
mnt= mnt_setGrid(mnt, opt.grd);
opt_scalp_erp= defopt_scalp_erp('colorOrder', [0.9 0 0.9; 0.4 0.4 0.4], ...
                                'extrapolate', 1, ...
                                'renderer', 'contourf', ...
                                'legend_pos','NorthWest');
opt_scalp_r= defopt_scalp_r('lineWidth', 2, ...
                            'channelAtBottom',1, ...
                            'extrapolate', 1, ...
                            'renderer', 'contourf', ...
                            'legend_pos','NorthWest');
opt_fig= {'numberTitle','off', 'menuBar','none'};

%% artifact rejection (trials and/or channels)
flds= {'reject_artifacts', 'reject_channels', ...
       'reject_artifacts_opts', 'clab'};
if bbci_memo.data_reloaded | ...
      ~fieldsareequal(bbci_bet_memo_opt, opt, flds),
  clear anal
  anal.rej_trials= NaN;
  anal.rej_clab= NaN;
  if opt.reject_artifacts | opt.reject_channels,
    handlefigures('use', 'Artifact rejection', 1);
    set(gcf, 'Visible','off', ...
             'name',sprintf('%s: Artifact rejection', Cnt.short_title));
%     rClab = []; rTrials = [];     %% ENTFERNEN!
    [mk_clean , rClab, rTrials]= ...
        reject_varEventsAndChannels(Cnt, mrk, [0 1000], ...
                                    'clab',clab, ...
                                    'do_multipass', 1, ...
                                    opt.reject_artifacts_opts{:}, ...
                                    'visualize', bbci.withgraphics);
    set(gcf,  'Visible','on');
    if opt.reject_artifacts,
      if not(isempty(rTrials)),
        %% TODO: make output class-wise
        fprintf('rejected: %d trial(s).\n', length(rTrials));
      end
      anal.rej_trials= rTrials;
    end
    if opt.reject_channels,
      if not(isempty(rClab)),
        fprintf('rejected channels: <%s>.\n', vec2str(rClab));
      end
      anal.rej_clab= rClab;
    end
  end
end
if iscell(anal.rej_clab),   %% that means anal.rej_clab is not NaN
  clab(strpatternmatch(anal.rej_clab, clab))= [];
end

if opt.widely_nontarget,
  % select subgroup of non-targets (save memory and avoid overlap)
  target= find(mrk.y(1,:));
  widely_nontarget= find(mrk.y(2,:) & ...
                         [mrk.y(2,2:end), 1] & ...
                         [mrk.y(2,3:end), 1, 1] & ...
                         [1, mrk.y(2,1:end-1)] & ...
                         [1, 1, mrk.y(2,1:end-2)] & ...
                         [1, 1, 1, mrk.y(2,1:end-3)]);
  mrk= mrk_chooseEvents(mrk, union(target, widely_nontarget));
end

% segmentation
clear epo
epo= cntToEpo(Cnt, mrk, opt.disp_ival);
%epo= proc_baseline(epo, opt.ref_ival, 'classwise',1, 'pos','beginning_exact');
epo= proc_channelwise(epo, 'baseline', opt.ref_ival, 'pos','beginning_exact');

%% rejection of eyemovements based on max-min criterium 
if opt.reject_eyemovements & opt.reject_eyemovements_crit.maxmin>0,
  epo_crit= proc_selectIval(epo, opt.reject_eyemovements_crit.ival);
  iArte= find_artifacts(epo_crit, opt.reject_eyemovements_crit.clab, ...
                        opt.reject_eyemovements_crit);
  fprintf('%d artifact trials removed (max-min>%d uV)\n', ...
          length(iArte), opt.reject_eyemovements_crit.maxmin);
  clear epo_crit
  epo= proc_selectEpochs(epo, 'not',iArte);
  anal.eyemovement_trials= iArte;
else
  anal.eyemovement_trials= NaN;
end

%epo_r= proc_r_square_signed(epo);
epo_r= proc_channelwise(epo, 'r_square_signed');
epo_r= rmfields(epo_r, {'V','p'});
epo_r.className= {'sgn r^2 ( T , NT )'};  %% just make it shorter

handlefigures('use','r^2 Matrix',1);
if isempty(opt.cfy_ival) | isequal(opt.cfy_ival, 'auto'),
  set(gcf, opt_fig{:}, 'Visible','off', 'name',...
           sprintf('%s: r^2 Matrixt', Cnt.short_title));
  [opt.cfy_ival, nfo]= ...
      select_time_intervals(epo_r, 'visualize', 1, 'visu_scalps', 1, ...
                            'sort', 1, ...
                            'clab_pick_peak',opt.cfy_clab, ...
                            'ival_pick_peak', opt.cfy_pick_peak, ...
                            'ival_max', opt.cfy_maxival);
  ival_scalps= visutil_correctIvalsForDisplay(opt.cfy_ival, 'fs',epo.fs);
  bbci_bet_message('[%g %g] ms\n', opt.cfy_ival');
else
  addpath([BCI_DIR 'investigation/teaching/ss09_analysis_of_neuronal_data']);
  ival_scalps= visutil_correctIvalsForDisplay(opt.cfy_ival, 'fs',epo.fs);
  clear nfo
  for ii= 1:size(opt.cfy_ival, 1);
    nfo(ii).ival= ival_scalps(ii,:);
  end
  visualize_score_matrix(epo_r, nfo);
end
set(gcf,  'Visible','on');
anal.ival= opt.cfy_ival;

handlefigures('use','ERPs',1);
set(gcf, opt_fig{:}, 'Visible','off', 'name',...
         sprintf('%s: ERP grid plot', Cnt.short_title));
H= grid_plot(epo, mnt, defopt_erps, 'colorOrder',opt_scalp_erp.colorOrder);
grid_addBars(epo_r, 'h_scale',H.scale);
set(gcf,  'Visible','on');

handlefigures('use','ERP Maps',1);
set(gcf, opt_fig{:}, 'Visible','off', 'name',...
         sprintf('%s: ERP scalp maps', Cnt.short_title));
H= scalpEvolutionPlusChannel(epo, mnt, opt.clab_erp, ival_scalps, ...
                             opt_scalp_erp);
grid_addBars(epo_r);
set(gcf,  'Visible','on');

if isempty(opt.clab_rsq) | isequal(opt.clab_rsq,'auto'),
  opt.clab_rsq= unique_unsort({nfo.peak_clab}, 4);
end
handlefigures('use','ERP r^2 Maps',1);
set(gcf, opt_fig{:}, 'Visible','off', 'name',...
         sprintf('%s: ERP r^2 scalp maps', Cnt.short_title));
scalpEvolutionPlusChannel(epo_r, mnt, opt.clab_rsq, ival_scalps, ...
                            opt_scalp_r);
set(gcf,  'Visible','on');

clear epo
fv= cntToEpo(Cnt, mrk, opt.disp_ival);
fv= proc_selectChannels(fv, opt.cfy_clab);
fv= proc_channelwise(fv, 'baseline', opt.ref_ival, 'pos','beginning_exact');
fv= proc_jumpingMeans(fv, opt.cfy_ival);

if opt.withclassification,
  opt_xv= strukt('xTrials', [1 10], ...
                 'loss','rocArea');
  [dum,dum,outTe] = xvalidation(fv, opt.model, opt_xv);
  me= val_confusionMatrix(fv, outTe, 'mode','normalized');
  remainmessage = sprintf('Correct Hits: %2.1f, Correct Miss: %2.1f\n',100*me(1,1),100*me(2,2));
  bbci_bet_message(remainmessage,0);
else
  remainmessage= '';
end

analyze= strukt('features', fv, ...
                'ival', opt.cfy_ival, ...
                'ref_ival', opt.ref_ival, ...
                'message', remainmessage);
analyze= merge_structs(analyze, anal);

bbci_memo.data_reloaded= 0;
