stim= [];stim.cue= struct('string', {'L','R','F'});[stim.cue.nEvents]= deal(15);[stim.cue.timing]= deal([4000 3500 0]);stim.msg_intro= 'Entspannen';opt= [];opt.filename= 'imag_lett';opt.breaks= [15 15];opt.break_msg= 'Kurze Pause (%d s)';opt.msg_fin= 'Ende';%opt.position= [-1279 1 1280 1005];opt.position= [1600 1 1280 1005];fprintf('for testing:\n  stim_visualCues(stim, opt, ''test'',1);\n');fprintf('stim_visualCues(stim, opt);\n');