%BBCI_BET_ANALYZE_CSPAUTO - Analysis of SMR Modulations for CSP-based BBCI
%
%Description.
% Analyzes data provided by bbci_bet_prepare according to the
% parameters specified in the struct 'bbci'.
% It provides features for bbci_bet_finish_cspauto
%
%Input (variables defined before calling this function):
% Cnt, mrk, mnt:  (loaded by bbci_bet_prepare)
% bbci:   struct, the general setup variable from bbci_bet_prepare
% bbci_memo: internal use
% opt    (copied by bbci_bet_analyze from bbci.setup_opts) a struct with fields
%  reject_artifacts:
%  reject_channels:
%  reject_opts: cell array of options which are passed to
%     reject_varEventsAndChannels.
%  reject_outliers:
%  check_ival: interval which is checked for artifacts/outliers
%  ival: interval on which CSP is performed, 'auto' means automatic selection.
%  band: frequency band on which CSP is performed, 'auto' means
%     automatic selection.
%  nPat: number of CSP patterns which are considered from each side of the
%     eigenvalue spectrum. Note that not neccessarily all of these are
%     used for classification, see opt.usedPat.
%  usedPat: vector specifying the indices of the CSP filters that should
%     be used for classification, 'auto' means automatic selection.
%  do_laplace: do Laplace spatial filtering for automatic selection
%     of ival/band. If opt.do_laplace is set to 0, the default value of
%     will also be set to opt.visu_laplace 0 (but can be overwritten).
%  visu_laplace: do Laplace filtering for grid plots of Spectra/ERDs.
%     If visu_laplace is a string, it is passed to proc_laplace. This
%     can be used to use alternative geometries, like 'vertical'.
%  visu_band: Frequency range for which spectrum is shown.
%  visu_ival: Time interval for which ERD/ERS curves are shown.
%  visu_classes: Classes for which Spectra and ERD curves are drawn,
%     default '*'.
%  grd: grid to be used in the grid plots of spectra and ERDs.
%
%Output:
%   analyze  struct, will be passed on to bbci_bet_finish_csp
%   bbci : updated
%   bbci_memo : updated

% blanker@cs.tu-berlin.de, Aug-2007
% Guido Dornhege, 07/12/2004
% Johannes Hoehne, 07/2011


% Everything that should be carried over to bbci_bet_finish_csp must go
% into a variable of this name:
analyze = []; analyze_csp = []; analyze_LRP = [];


%TODO: DOCUMENTATION OF THIS SCRIPT

%default_grd= ...
%    sprintf('scale,FC1,FCz,FC2,legend\nC3,C1,Cz,C2,C4\nCP3,CP1,CPz,CP2,CP4');
default_grd= ...
    sprintf('F5,F3,F1,Fz,F2,F4,F6\nscale,FC3,FC1,FCz,FC2,FC4,legend\nC5,C3,C1,Cz,C2,C4,C6\nCP5,CP3,CP1,CPz,CP2,CP4,CP6\nP5,P3,P1,Pz,P2,P4,P6');

default_colDef= {'left', 'right',   'foot',  'rest'; ...
    [0.8 0 0.8], [0 0.7 0], [0 0 1], [0 0 0]};

[opt, isdefault]= ...
    set_defaults(opt, ...
    'reject_artifacts', 1, ...
    'reject_channels', 1, ...
    'reject_opts', {}, ...
    'reject_outliers', 0, ...
    'check_ival', [-250 5000], ...
    'lpass_LRP', [6 7], ... % bounds for the LRP low-pass filter
    'ival', {'auto', 'auto'}, ...
    'default_ival', [1000 3500], ...
    'min_ival_length', 300, ...       % changed!
    'enlarge_ival_append', 'end', ...  % changed!
    'repeat_bandselection', 1, ...
    'selband_opt', [], ...
    'selival_opt', [], ...
    'usedPat', 'auto', ...
    'do_laplace', 1, ...
    'visu_laplace', 1, ...
    'do_LRP', 1, ...
	'do_csp', 1, ...
    'visu_band', [5 35], ...
    'visu_ival', [-500 5000], ...
    'visu_classes', '*', ...
    'grd', default_grd, ...
    'colDef', default_colDef, ...
    'verbose', 1);
%% TODO: optional visu_specmaps, visu_erdmaps

bbci_bet_memo_opt= ...
    set_defaults(bbci_bet_memo_opt, ...
    'nPat', NaN, ...
    'usedPat', NaN, ...
    'band', NaN);

if isdefault.default_ival & opt.verbose,
    msg= sprintf('default ival not defined in bbci.setup_opts, using [%d %d]', ...
        opt.default_ival);
    warning(msg);
end
if isdefault.visu_laplace & ~opt.do_laplace,
    opt.visu_laplace= 0;
end



%% Prepare visualization
 
mnt= mnt_setGrid(mnt, opt.grd);
opt_grid= defopt_erps('scale_leftshift',0.075);
%% TODO: extract good channel (like 'CPz' here) from grid
opt_grid_spec= defopt_spec('scale_leftshift',0.075, ...
    'xTickAxes','CPz');
clab_gr1= intersect(scalpChannels, getClabOfGrid(mnt));
if isempty(clab_gr1),
    clab_gr1= getClabOfGrid(mnt);
end
opt_grid.scaleGroup= {clab_gr1, {'EMG*'}, {'EOG*'}};
fig_opt= {'numberTitle','off', 'menuBar','none'};
if length(strpatternmatch(mrk.className, opt.colDef(1,:))) < ...
        length(mrk.className),
    if ~isdefault.colDef,
        warning('opt.colDef does not match with mrk.className');
    end
    nClasses= length(mrk.className);
    cols= mat2cell(cmap_rainbow(nClasses), ones(1,nClasses), 3)';
    opt.colDef= {mrk.className{:}; cols{:}};
end

%% when nPat was changed, but usedPat was not, define usedPat
if bbci_bet_memo_opt.nPat~=opt.nPat ...
        & ~strcmpi(opt.usedPat, 'auto') ...
        & isequal(bbci_bet_memo_opt.usedPat, opt.usedPat),
    opt.usedPat= 1:2*opt.nPat;
end


%% Analysis starts here
clear fv*
clab= Cnt.clab(chanind(Cnt, opt.clab{1}));

%% artifact rejection (trials and/or channels)
flds= {'reject_artifacts', 'reject_channels', ...
    'reject_opts', 'check_ival', 'clab'};
if bbci_memo.data_reloaded | ...
        ~fieldsareequal(bbci_bet_memo_opt, opt, flds),
    clear anal
    anal.rej_trials= NaN;
    anal.rej_clab= NaN;
    if opt.reject_artifacts | opt.reject_channels,
        if opt.verbose,
            fprintf('checking for artifacts and bad channels\n');
        end
        if bbci.withgraphics,
            handlefigures('use', 'Artifact rejection', 1);
            set(gcf, fig_opt{:},  ...
                'name',sprintf('%s: Artifact rejection', Cnt.short_title));
        end
        [mk_clean , rClab, rTrials]= ...
            reject_varEventsAndChannels(Cnt, mrk, opt.check_ival, ...
            'clab',clab, ...
            'do_multipass', 1, ...
            opt.reject_opts{:}, ...
            'visualize', bbci.withgraphics, ...
            'clab', clab); %nur ausgewaehlte channels
        if bbci.withgraphics,
            handlefigures('next_fig','Artifact rejection');
            drawnow;
        end
        if opt.reject_artifacts,
            if length(rTrials)>0 | opt.verbose,
                %% TODO: make output class-wise
                fprintf('rejected: %d trial(s).\n', length(rTrials));
            end
            anal.rej_trials= rTrials;
        end
        if opt.reject_channels,
            if length(rClab)>0 | opt.verbose,
                fprintf('rejected channels: <%s>.\n', vec2str(rClab));
            end
            anal.rej_clab= rClab;
        end
    end
end
if iscell(anal.rej_clab),   %% that means anal.rej_clab is not NaN
    clab(strpatternmatch(anal.rej_clab, clab))= [];
end

if opt.reject_outliers,
    %% TODO: execute only if neccessary
    if opt.verbose,
        bbci_bet_message('checking for outliers\n');
    end
    fig1 = handlefigures('use', 'trial-outlierness', 1);
    fig2 = handlefigures('use', 'channel-outlierness', 1);
    %% TODO: reject_outliers only on artifact free trials?
    %%  clarify relation of reject_articfacts and reject_outliers
    fv= cntToEpo(Cnt, mrk, opt.check_ival, 'clab',clab);
    [fv, anal.outl_trials]=  ...
        proc_outl_var(fv, ...
        'display', bbci.withclassification,...
        'handles', [fig1,fig2], ...
        'trialthresh',bbci.setup_opts.threshold);
    %% TODO: output number of outlier trials (class-wise)
    clear fv
    handlefigures('next_fig', 'trial-outlierness');
    handlefigures('next_fig', 'channel-outlierness');
else
    anal.outl_trials= NaN;
end

kickout_trials= union(anal.rej_trials, anal.outl_trials);
kickout_trials(find(isnan(kickout_trials)))= [];
this_mrk= mrk_chooseEvents(mrk, setdiff(1:length(mrk.pos), kickout_trials));


if ~isequal(bbci.classes, 'auto'),
    class_combination= strpatternmatch(bbci.classes, this_mrk.className);
    if length(class_combination) < length(bbci.classes),
        error('not all specified classes found');
    end
    if opt.verbose,
        fprintf('using classes <%s> as specified\n', vec2str(bbci.classes));
    end
else
    class_combination= nchoosek(1:size(this_mrk.y,1), 2);
    if size(class_combination,1) == 1
        bbci.classes = this_mrk.className(class_combination(1,:));
        sprintf('only one set of classes (%s) was specified, thus bbci.classes = ''auto'' doesnt have any meaning and was changed to ''%s''', [(bbci.classes{:})], [(bbci.classes{:})])
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% Start CSP analysis %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Specific investigation of binary class combination(s) start
if opt.do_csp

memo_opt.band= opt.band{1};
memo_opt.ival= opt.ival{1};
clear analyze mean_loss std_loss analyze_csp analyze_LRP
for ci= 1:size(class_combination,1),

    classes= this_mrk.className(class_combination(ci,:));
    if strcmp(classes{1},'right') | strcmp(classes{2},'left'),
        class_combination(ci,:)= fliplr(class_combination(ci,:));
        classes= this_mrk.className(class_combination(ci,:));
    end
    if size(class_combination,1)>1,
        fprintf('\ninvestigating class combination <%s> vs <%s>\n', classes{:});
    end
    mrk2= mrk_selectClasses(this_mrk, classes);
    opt_grid.colorOrder= choose_colors(this_mrk.className, opt.colDef);
    opt_grid.lineStyleOrder= {'--','--','--'};
    clidx= strpatternmatch(classes, this_mrk.className);
    opt_grid.lineStyleOrder(clidx)= {'-'};
    opt_grid_spec.lineStyleOrder= opt_grid.lineStyleOrder;
    opt_grid_spec.colorOrder= opt_grid.colorOrder;


    %% Automatic selection of parameters (band, ival)
    band_fresh_selected= 0;
    if isequal(opt.band{1}, 'auto') | isempty(opt.band{1});
        bbci_bet_message('No band specified, select an optimal one: ');
        if ~isequal(opt.ival{1}, 'auto') & ~isempty(opt.ival{1}),
            ival_for_bandsel= opt.ival{1};
        else
            ival_for_bandsel= opt.default_ival{1};
            if ~opt.repeat_bandselection,
                bbci_bet_message('\nYou should run bbci_bet_analyze a 2nd time.\n pre-selection of band: ');
            end
        end
        opt.band{1}= select_bandnarrow(Cnt, mrk2, ival_for_bandsel, ...
            opt.selband_opt, 'do_laplace',opt.do_laplace);
        bbci_bet_message('[%g %g] Hz\n', opt.band{1});
        band_fresh_selected= 1;
    end

    [filt_b,filt_a]= butter(opt.filtOrder, opt.band{1}/Cnt.fs*2);
    clear cnt_flt_csp
    cnt_flt_csp= proc_filt(Cnt, filt_b, filt_a);
    %  if opt.verbose>=2,
    %    bbci_bet_message('Data filtered\n');
    %  end
    %elseif opt.verbose>=2,
    %  bbci_bet_message('Filtered data reused\n');
    %end

    if isequal(opt.ival{1}, 'auto') | isempty(opt.ival{1}),
        bbci_bet_message('No ival specified, automatic selection: ');
        opt.ival{1}= select_timeival(cnt_flt_csp, mrk2, ...
            opt.selival_opt, 'do_laplace',opt.do_laplace);
        bbci_bet_message('[%i %i] msec.\n', opt.ival{1});
    end

    if opt.repeat_bandselection & band_fresh_selected & ...
            ~isequal(opt.ival{1}, ival_for_bandsel),
        bbci_bet_message('Redoing selection of frequency band for new interval: ');
        first_selection= opt.band{1};
        opt.band{1}= select_bandnarrow(Cnt, mrk2, opt.ival{1}, ...
            opt.selband_opt, 'do_laplace',opt.do_laplace);
        bbci_bet_message('[%g %g] Hz\n', opt.band{1});
        if ~isequal(opt.band{1}, first_selection),
            clear cnt_flt_csp
            [filt_b,filt_a]= butter(opt.filtOrder, opt.band{1}/Cnt.fs*2);
            cnt_flt_csp= proc_filt(Cnt, filt_b, filt_a);
        end
    end
    anal.band= opt.band{1};
    anal.ival= opt.ival{1};

    %% Visualization of spectra and ERD/ERS curves

    if bbci.withgraphics
        disp_clab= getClabOfGrid(mnt);
        if opt.visu_laplace,
            requ_clab= getClabForLaplace(Cnt, disp_clab);
        else
            requ_clab= disp_clab;
        end
        if diff(opt.ival{1})>=opt.min_ival_length,
            spec= cntToEpo(Cnt, this_mrk, opt.ival{1}, 'clab',requ_clab);
        else
            bbci_bet_message('Enlarging interval to calculate spectra\n');
            if strcmpi(opt.enlarge_ival_append, 'start')
                spec= cntToEpo(Cnt, this_mrk, opt.ival{1}(2)+[-opt.min_ival_length 0], 'clab',requ_clab);
            elseif strcmpi(opt.enlarge_ival_append, 'end')
                spec= cntToEpo(Cnt, this_mrk, opt.ival{1}(1)+[0 opt.min_ival_length], 'clab',requ_clab);
            else
                error('opt.enlarge_ival_append option unknown.')
            end
        end
        if opt.verbose>=2,
            bbci_bet_message('Creating figure for spectra\n');
        end
        handlefigures('use','Spectra',1);
        set(gcf, fig_opt{:}, 'name',...
            sprintf('%s: spectra in [%d %d] ms', Cnt.short_title, opt.ival{1}));
        if opt.visu_laplace,
            if ischar(opt.visu_laplace),
                spec= proc_laplacian(spec, opt.visu_laplace);
            else
                spec= proc_laplacian(spec);
            end
        end

        if Cnt.fs>size(spec.x,1)
            Win = size(spec.x,1);
        else
            Win = Cnt.fs;
        end
        spec= proc_spectrum(spec, opt.visu_band, kaiser(Win,2));
        spec_rsq= proc_r_square_signed(proc_selectClasses(spec,classes));

        h= grid_plot(spec, mnt, opt_grid_spec);
        grid_markIval(opt.band{1});
        grid_addBars(spec_rsq, ...
            'h_scale', h.scale, ...
            'box', 'on', ...
            'colormap', cmap_posneg(31), ...
            'cLim', 'sym');
        drawnow;

        clear spec_rsq spec
        handlefigures('next_fig','Spectra');
        drawnow;


        if opt.verbose>=2,
            bbci_bet_message('Creating figure(s) for ERD\n');
        end
        handlefigures('use','ERD',size(opt.band{1},1));
        set(gcf, fig_opt{:},  ...
            'name',sprintf('%s: ERD for [%g %g] Hz', ...
            Cnt.short_title, opt.band{1}));
        erd= proc_selectChannels(cnt_flt_csp, requ_clab);
        if opt.visu_laplace,
            if ischar(opt.visu_laplace),
                erd= proc_laplacian(erd, opt.visu_laplace);
            else
                erd= proc_laplacian(erd);
            end
        end
        erd= proc_envelope(erd, 'ms_msec', 200);
        erd= cntToEpo(erd, this_mrk, opt.visu_ival);
        erd= proc_baseline(erd, [], 'trialwise',0);
        erd_rsq= proc_r_square_signed(proc_selectClasses(erd, classes));

        h = grid_plot(erd, mnt, opt_grid);
        grid_markIval(opt.ival{1});
        grid_addBars(erd_rsq, ...
            'h_scale',h.scale, ...
            'box', 'on', ...
            'colormap', cmap_posneg(31), ...
            'cLim', 'sym');
        drawnow;

        clear erd erd_rsq;
        handlefigures('next_fig','ERD');
    end

    fv= cntToEpo(cnt_flt_csp, mrk2, opt.ival{1}, 'clab',clab);
    clear cnt_flt_csp

    if opt.verbose>=2,
        bbci_bet_message('calculating CSP\n');
    end

    %% make hlp_w global such that it can be accessed from xvalidation
    %% in order to match patterns with these ones
    global hlp_w
    if ischar(opt.usedPat) & strcmpi(opt.usedPat,'auto'),
        [fv2, hlp_w, la, A]= proc_csp_auto(fv, 'patterns',opt.nPat);
    else
        [fv2, hlp_w, la, A]= proc_csp3(fv, 'patterns',opt.nPat);
    end


    if bbci.withgraphics | bbci.withclassification,
        if opt.verbose>=2,
            bbci_bet_message('Creating Figure CSP\n');
        end
        handlefigures('use','CSP');
        set(gcf, fig_opt{:},  ...
            'name',sprintf('%s: CSP <%s> vs <%s>', Cnt.short_title, classes{:}));
        opt_scalp_csp= strukt('colormap', cmap_greenwhitelila(31));
        if ischar(opt.usedPat) & strcmpi(opt.usedPat,'auto'),
            plotCSPanalysis(fv, mnt, hlp_w, A, la, opt_scalp_csp, ...
                'row_layout',1, 'title','');
        else
            plotCSPanalysis(fv, mnt, hlp_w, A, la, opt_scalp_csp, ...
                'mark_patterns', opt.usedPat);
        end
        drawnow;
    end


    features= proc_variance(fv2);
    features= proc_logarithm(features);
    if ~ischar(opt.usedPat) | ~strcmpi(opt.usedPat,'auto'),
        features.x= features.x(:,opt.usedPat,:);
        hlp_w= hlp_w(:,opt.usedPat);
    end


    %% BB: I propose a different validation. For test samples always take a
    %%  FIXED interval, e.g. opt.default_ival. Practically this can be done
    %%  with bidx, train_jits, test_jits.
    remainmessage = '';
    if bbci.withclassification,
        opt_xv= strukt('sample_fcn',{'chronKfold',8}, ...
            'std_of_means',0, ...
            'verbosity',0, ...
            'progress_bar',0);
        [loss,loss_std] = xvalidation(features, opt.model{1}, opt_xv);
        bbci_bet_message('CSP global: %4.1f +/- %3.1f\n',100*loss,100*loss_std);
        remainmessage= sprintf('CSP global: %4.1f +/- %3.1f', ...
            100*loss,100*loss_std);
        if ischar(opt.usedPat) & strcmpi(opt.usedPat,'auto'),
            proc= struct('memo', 'csp_w');
            proc.train= ['[fv,csp_w]= proc_csp_auto(fv, ' int2str(opt.nPat) '); ' ...
                'fv= proc_variance(fv); ' ...
                'fv= proc_logarithm(fv);'];
            proc.apply= ['fv= proc_linearDerivation(fv, csp_w); ' ...
                'fv= proc_variance(fv); ' ...
                'fv= proc_logarithm(fv);'];
            [loss,loss_std] = xvalidation(fv, opt.model{1}, opt_xv, 'proc',proc);
            bbci_bet_message('CSP auto inside: %4.1f +/- %3.1f\n', ...
                100*loss,100*loss_std);
            remainmessage = sprintf('%s\nCSP auto inside: %4.1f +/- %3.1f', ...
                remainmessage, 100*loss,100*loss_std);
        else
            proc= struct('memo', 'csp_w');
            proc.train= ['[fv,csp_w]= proc_csp3(fv, ' int2str(opt.nPat) '); ' ...
                'fv= proc_variance(fv); ' ...
                'fv= proc_logarithm(fv);'];
            proc.apply= ['fv= proc_linearDerivation(fv, csp_w); ' ...
                'fv= proc_variance(fv); ' ...
                'fv= proc_logarithm(fv);'];
            [loss,loss_std] = xvalidation(fv, opt.model{1}, opt_xv, 'proc',proc);
            bbci_bet_message('CSP inside: %4.1f +/- %3.1f\n',100*loss,100*loss_std);
            remainmessage = sprintf('%s\nCSP inside: %4.1f +/- %3.1f', ...
                remainmessage, 100*loss,100*loss_std);

            if ~isequal(opt.usedPat, 1:2*opt.nPat),
                proc.train= ['global hlp_w; ' ...
                    '[fv,csp_w]= proc_csp3(fv, ''patterns'',hlp_w, ' ...
                    '''selectPolicy'',''matchfilters''); ' ...
                    'fv= proc_variance(fv); ' ...
                    'fv= proc_logarithm(fv);'];
                proc.apply= ['fv= proc_linearDerivation(fv, csp_w); ' ...
                    'fv= proc_variance(fv); ' ...
                    'fv= proc_logarithm(fv);'];
                [loss,loss_std]= xvalidation(fv, opt.model{1}, opt_xv, 'proc',proc);
                bbci_bet_message('CSP selPat: %4.1f +/- %3.1f\n', 100*loss,100*loss_std);
                remainmessage = sprintf('%s\nCSP setPat: %4.1f +/- %3.1f', ...
                    remainmessage, 100*loss,100*loss_std);
            end
        end
        mean_loss(ci,1)= loss;
        std_loss(ci,1)= loss_std;
    end
    clear fv
    clear fv2

    % Gather all information that should be saved in the classifier file
    analyze_csp(ci)= merge_structs(anal, strukt('clab', clab, ...
        'csp_a', filt_a, ...
        'csp_b', filt_b, ...
        'csp_w', hlp_w, ...
        'features', features, ...
        'message', remainmessage));

end  %% for ci


if opt.verbose>=2,
    bbci_bet_message('Finished analysis for csp-auto\n pres <ENTER> to continue with LRP-analysis');
    pause
end


end

%% LRP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% Start LRP analysis %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if opt.do_LRP
bbci_bet_message('start with LRP Filter\n');

Cnt = proc_selectChannels(Cnt, chanind(Cnt.clab, opt.clab{2}));
Cnt =  proc_commonAverageReference(Cnt,scalpChannels(Cnt));

    Wps= opt.lpass_LRP/Cnt.fs*2;
    db_attenuation=30;
    [n, Wn]= cheb2ord(Wps(1), Wps(2), 3, db_attenuation);
    [filt_b, filt_a]= cheby2(n, db_attenuation, Wn);
    cnt_flt_LRP= proc_filt(Cnt, filt_b, filt_a);


for ci= 1:size(class_combination,1),

    classes= this_mrk.className(class_combination(ci,:));
    if strcmp(classes{1},'right') | strcmp(classes{2},'left'),
        class_combination(ci,:)= fliplr(class_combination(ci,:));
        classes= this_mrk.className(class_combination(ci,:));
    end
    if size(class_combination,1)>1,
        fprintf('\ninvestigating class combination <%s> vs <%s>\n', classes{:});
    end
    mrk2= mrk_selectClasses(this_mrk, classes);
    opt_grid.colorOrder= choose_colors(this_mrk.className, opt.colDef);
    opt_grid.lineStyleOrder= {'--','--','--'};
    clidx= strpatternmatch(classes, this_mrk.className);
    opt_grid.lineStyleOrder(clidx)= {'-'};
    opt_grid_spec.lineStyleOrder= opt_grid.lineStyleOrder;
    opt_grid_spec.colorOrder= opt_grid.colorOrder;

    epo= cntToEpo(cnt_flt_LRP, mrk2, opt.visu_ival, 'clab',opt.clab{2});
    clear cnt_flt_LRP

    %% Visualization of LRP

    if bbci.withgraphics
        disp_clab= getClabOfGrid(mnt);
        requ_clab= disp_clab;

        if opt.verbose>=2,
            bbci_bet_message('Creating figure(s) for LRP\n');
        end
        epo = proc_baseline(epo, opt.baseline);

        epo_r= proc_r_square_signed(proc_selectClasses(epo, classes));
        handlefigures('use','INTERVAL');

        if strcmp(opt.ival{2},  'auto')
            bbci_bet_message('LRP intervals are chosen by heuristic. Manual setting through bbci.setup_opts.ival !\n')
            % Heuristic: Find good time intervals
            [opt.ival{2} nfo] = select_time_intervals(proc_selectIval(epo_r, [300 opt.visu_ival(2)-1000]), 'nIvals',1, 'visualize', 1, 'visu_scalps', 0);
            chan_plot = nfo.peak_clab;
        
        else 
            chan_plot = epo.clab(find(sum(epo_r.x == max(epo_r.x(:))))); %find the clab with max abs value in epo_r!
        end
        % manual setting!!
%          opt.ival{2} = [500 4000];

        
        bbci_bet_message('using [%g %g] as ivals for LRP\n', opt.ival{2} );
        handlefigures('use','LRP',size(opt.band{2},1));
        set(gcf, fig_opt{:},  ...
            'name',sprintf('%s: ERD for [%g %g] Hz', ...
            Cnt.short_title, opt.band{2}));

        h = grid_plot(epo, mnt, opt_grid);
        grid_markIval(opt.ival{2});
        grid_addBars(epo_r, ...
            'h_scale',h.scale, ...
            'box', 'on', ...
            'colormap', cmap_posneg(31), ...
            'cLim', 'sym');
        drawnow;
        %set(h,'MenuBar','figure');
        handlefigures('next_fig','LRP');

        myH=handlefigures('use','ScalpPicture')
        scalpEvolutionPlusChannel(epo, mnt, chan_plot , opt.ival{2}, 'legend_pos',2 , 'extrapolate', 1,'shading','interp','extrapolateToMean',1, 'globalCLim', 1, 'renderer', 'contourf');
        grid_addBars(epo_r)
        set(myH,'MenuBar','figure');

        myH=handlefigures('use','ScalpPictureR');
        scalpEvolutionPlusChannel(epo_r, mnt, chan_plot , opt.ival{2}, 'legend_pos',2 , 'extrapolate', 1,'shading','interp','extrapolateToMean',1, 'globalCLim', 1, 'renderer', 'contourf');
        set(myH,'MenuBar','figure');
    end


    if opt.verbose>=2,
        bbci_bet_message('calculating LRP\n');
    end

    fv= proc_jumpingMeans(epo, opt.ival{2}); % chance to mean


    remainmessage = '';
    if bbci.withclassification,
        % skalierung der Ausgabe auf 1 und store_means ist bereits im run
        % script run_Fissler aktiviert worden, daher dies unn�tz:
        % classy={opt.model,  struct('scaling',1)}
        opt_xv= strukt('sample_fcn',{'chronKfold',8}, ...
            'std_of_means',0, ...
            'verbosity',0, ...
            'progress_bar',0);
        [loss,loss_std] = xvalidation(fv, opt.model{2}, opt_xv);
        bbci_bet_message('LRP Common Average: %4.1f +/- %3.1f\n',100*loss,100*loss_std);


    end
    mean_loss(ci,2)= loss;
    std_loss(ci,2)= loss_std;

    % Gather all information that should be saved in the classifier file
    clab = Cnt.clab(chanind(Cnt, opt.clab{2}));
    analyze_LRP(ci)= strukt('clab', clab, ...
        'filt_a', filt_a, ...
        'filt_b', filt_b, ...
        'features', fv, ...
        'ival', opt.ival{2}, ...
        'band', opt.band{2}, ...
        'baseline', opt.baseline, ...
        'outl_trials', anal.outl_trials,...
        'rej_trials', anal.outl_trials, ...
        'message', remainmessage);
end %over ci

    disp('Classification performance \n');
    disp('    CSP    LRP');
    disp(mean_loss)

    bi = NaN; %init
    if isequal(bbci.classes, 'auto'),
        [dmy, bi]= min(mean_loss + 0.1*std_loss);
        if dmy(1) < dmy(2), bi = bi(1), else bi = bi(2); end;
        bbci.classes= this_mrk.className(class_combination(bi,:));
        bbci_bet_message(sprintf('\nCombination <%s> vs <%s> chosen.\n', ...
            bbci.classes{:}));
    else
        bi = 1;
    end
    bbci.class_selection_loss= [mean_loss; std_loss];
    analyze= {analyze_csp(bi), analyze_LRP(bi)};

%     if bi<size(class_combination,1),
%         opt.ival= analyze_csp{1}.ival;    %% restore selection of best class combination
%         opt.band= analyze_csp{1}.band;
%         bbci_bet_message('Rerun bbci_bet_analyze again to see corresponding plots\n');
%     end

if opt.verbose>=2,
    bbci_bet_message('Finished analysis for LRPs\n');
end

end