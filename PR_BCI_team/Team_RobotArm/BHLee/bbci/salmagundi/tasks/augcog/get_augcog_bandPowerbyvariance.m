function [fv,apply] = get_augcog_bandPowerbyvariance(blk,varargin);
%GET_AUGCOG_BANDENERGY OPENS AN AUGCOG FILE AND CALCULATES BANDENERGY
%
% usage:
%     fv = get_augcog_bandPowerbyvariance(file,<task=all available,ivallen=1000,band=[3 40],spatial='diagonal',channels={'not','E*','M*'});
%     fv = get_augcog_bandPowerbyvariance(blk,<task=all available,ivallen=1000,band=[3 40],spatial='diagonal',channels={'not','E*','M*'});
%     fv = get_augcog_bandPowerbyvariance(cnt,mrk,<ivallen=1000,band=[3 40],spatial='diagonal',channels={'not','E*','M*'});
%
% input:
%     file     -  the name of an augcog file
%     blk      -  a usual augcog blk structure
%     cnt,mrk  -  as usual
%     task     -  the task of the subject, e.g. '*auditory' 
%                 (for more than one as a cell array)
%     ivallen  -  the length of the ival (to make epochs)
%     band     -  the band spectral information should be given back
%                 can have more than one row
%     spatial  -  a spatial filter:
%                 see proc_spatialFilter for documentation
%
%
% output:
%     fv       - the resulting feature vector as a struct with fields:
%                .x    a spec*channel*trials matrix
%                .y    the logical 2xtrials matrix
%                .className  = {'low','high'};
%                .t    the spectral bin
%                .clab a cell array consisting of the channel names
%                .task a logical array to divide into different sessions
%                .taskname a cell array of task names concerning .task
%
% Guido Dornhege, 27/04/2004


% load the file, if necessary
if ~isstruct(blk)
  blk = getAugCogBlocks(blk);
end

% set defaults
opt = setdefault(varargin,{'task','ivallen','band','spatial','channels'},...
                          {[],[1000,1000],[3 40],'diagonal',{'not','E*','M*'}});

if length(opt.ivallen) == 1
  opt.ivallen = [1,1]*opt.ivallen;
end

% Choose the task
if ~isempty(opt.task) & ~isstruct(opt.task)
  if ~iscell(opt.task), opt.task = {opt.task};end
  blk = blk_selectBlocks(blk,opt.task{:});
end

% read the blocks
if ~isstruct(opt.task)
  [cnt,mrk] = readBlocks(blk);
else
  cnt = blk;
  mrk = opt.task;
end
clear apply;

% choose channels
if ~isempty(opt.channels)
  apply.chans = chanind(cnt,opt.channels{:});
  cnt = proc_selectChannels(cnt,apply.chans);
end

% spatial filtering
[h,apply.cnt_apply] = proc_spatial_filtering_augcog(cnt,opt.spatial);
if isstruct(h);
  cnt = h;
end

% epoching
mrk = separate_markers(mrk);
mrk = mrk_setMarkers(mrk,opt.ivallen);

par = {};
for i = 1:size(opt.band,1)
  [b,a] = butter(5,[opt.band(i,:)]/cnt.fs*2);
  par = {par{:},b,a};
end

cnt = proc_filtconcat(cnt,par{:});
apply.cnt_apply(length(apply.cnt_apply)+1) = struct('fcn','proc_filtconcat','param',{par});

nchans = size(cnt.x,2);
epo = makeEpochs(cnt,mrk,[0 opt.ivallen(2)]);
clear cnt mrk blk

make_proc_apply('init')
% $$$ % maybe spatialling again???
% $$$ if isnumeric(h)
% $$$   [epo,proc_apply] = proc_spatial_filtering_augcog(epo,opt.spatial);
% $$$   make_proc_apply(proc_apply);
% $$$ end

epo.task = epo.y; epo.taskname = epo.className;
epo.bidx = (1:size(epo.task,1))*epo.task;

epo.indexedByEpochs = {'task','bidx'};
clInd0 = getClassIndices(epo,'base*');
clInd = getClassIndices(epo,'low*');
clInd2 = getClassIndices(epo,'high*');

epo.y = zeros(3,size(epo.y,2));
epo.className = {'base','low','high'};

ind0 = find(sum(epo.task(clInd0,:),1));
ind = find(sum(epo.task(clInd,:),1));
ind2 = find(sum(epo.task(clInd2,:),1));

epo.y(1,ind0) = 1;
epo.y(2,ind) = 1;
epo.y(3,ind2) = 1;

indi = find(sum(epo.y,2)>0);
epo.y = epo.y(indi,:);
epo.className = epo.className(indi);


fv = proc_logarithm(proc_variance(epo));

str = sprintf('fv = proc_logarithm(proc_variance(epo));');


make_proc_apply(str);

apply.proc_apply = make_proc_apply('get');




