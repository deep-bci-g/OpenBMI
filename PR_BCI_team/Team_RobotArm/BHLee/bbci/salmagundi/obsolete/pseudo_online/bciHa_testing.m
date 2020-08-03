%% ...

test_len= ceil((test_end - test_begin + 1)/feedback_opt.step);
dtct_out= zeros(test_len, 1);
dscr_out= zeros(test_len, 1);
goal= zeros(test_len, 1);
comb_out= zeros(test_len, 1);
evt= nTrains+1:length(mrk.pos);
mrkpos_decimate= round((mrk.pos(evt)-test_begin+1)/feedback_opt.step);
goal(mrkpos_decimate)= [-1 1]*mrk.y(:,evt);
time_line= linspace(test_begin/cnt.fs, test_end/cnt.fs, test_len);

%% initialize feedback animation
feedback_opt.fs= cnt.fs/feedback_opt.step;
feedback_opt= animate_feedback(feedback_opt, 'init', dscr_out);


ptr= 1;
pp= test_begin;
first_test_event= min(find(mrk.pos>pp));  %% = nTrains+1
while pp<=test_end,
  
  dscr_wnd.x= cnt.x(pp+dscr.iv_apply, dscr.chans);
  epo= dscr_wnd;
  eval(dscr.proc_apply);
  fv.x= reshape(fv.x, [prod(size(fv.x)) 1 1]);
  out= applyClassifier(fv, dscr.model, dscr.C);
  if length(out)==2, out=[-1 1]*out; end
  dscr_out(ptr)= out * dscr.scale;

%  if ismember(pp, mrk.pos),
%    keyboard
%  end
  
  if exist('dtct', 'var'),
    dtct_wnd.x= cnt.x(pp+dtct.iv_apply, dtct.chans);
    epo= dtct_wnd;
    eval(dtct.proc_apply);
    fv.x= reshape(fv.x, [prod(size(fv.x)) 1 1]);
    out= applyClassifier(fv, dtct.model, dtct.C);
    if length(out)>1, out= max(out(2:end)) - out(1); end
    dtct_out(ptr)= out * dtct.scale;
  
    comb_out(ptr)= feval(feedback_opt.combiner_fcn, feedback_opt, ...
                         ptr, dscr_out, dtct_out, comb_out);

    animate_feedback(feedback_opt, ptr, dscr_out, dtct_out, comb_out);
    
  else
    animate_feedback(feedback_opt, ptr, dscr_out);
  end

  ptr= ptr + 1;
  pp= pp + feedback_opt.step;
end
