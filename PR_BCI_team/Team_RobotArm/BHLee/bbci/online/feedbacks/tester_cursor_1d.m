clear opt
opt.trials_per_run= 20;
%opt.cursor_on= 0;
opt.log= 0;
opt.center_size= 0.15;
opt.response_at= 'cursor';
opt.timeout_policy= 'hitiflateral';
opt.show_score= 0;
speedup= 1;

opi= set_defaults(opt, 'status','play', 'changed',1);
opt= feedback_cursor_1d(gcf, opi, 0);
waitForSync;
for ii= 1:50;
  waitForSync(1000/25/speedup);
  ctrl= -1;
  opt= feedback_cursor_1d(gcf, opt, ctrl);
end
for ii= 1:50;
  waitForSync(1000/25/speedup);
  ctrl= 1;
  opt= feedback_cursor_1d(gcf, opt, ctrl);
end

while 1,
C= interp(randn(1,500), 8);
for cc= 1:length(C),
  ws= waitForSync(1000/25/speedup);
  if ws>0,
    fprintf('lost: %.1f ms\n', ws);
  end
  ctrl= max(-1, min(1, ctrl + C(cc)/5));
  if cc<100,
    ctrl= ctrl*0.1;
  end
  opt= feedback_cursor_1d(gcf, opt, ctrl);
end
end
