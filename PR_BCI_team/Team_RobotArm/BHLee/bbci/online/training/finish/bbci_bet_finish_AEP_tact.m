
% Generate all variables that are required in bbci_bet_apply:
% cont_proc, feature, cls

% Extract channel labels clab
% clab = Cnt.clab(chanind(Cnt,opt.clab));
% Cnt = proc_selectChannels(Cnt, 'not', 'E*');
cont_proc = struct('clab',{epo.clab});

marker_output = struct();
marker_output.marker = {1 2 3 4 5 6 7 8 11 12 13 14 15 16 17 18};
marker_output.value = [1 2 3 4 5 6 7 8 1 2 3 4 5 6 7 8];
marker_output.no_marker = 0;

feature = struct('cnt',1);
feature.ilen_apply = diff(opt.ival)+10; %10 to account for difference in marker position interpretation

feature.proc = {'proc_baseline','proc_jumpingMeans','proc_flaten','proc_subtractMean', 'proc_normalize'};
feature.proc_param = {{opt.baseline, 'beginning_exact'},{opt.selectival-opt.ival(2)},{struct('force_flaten', 1)},{opt.meanOpt},{opt.normOpt}}; % -800 

% feature.proc = {'proc_jumpingMeans'};
% feature.proc_param = {{opt.selectival-opt.ival(2)-10}}; % -800 

cls = struct('fv',1);
cls.applyFcn = getApplyFuncName(opt.model);
cls.C = trainClassifier(analyze.features,opt.model);
str1 = sprintf('%g,',[bbci.classDef{1,:}]);
%% WHY INTERVAL IN REVERSE ORDER?
cls.condition = sprintf('M({{%s},[%g %g]});',str1(1:end-1), opt.ival(end)*[1 1]);
% bbci.errorJit = opt.ival(end);