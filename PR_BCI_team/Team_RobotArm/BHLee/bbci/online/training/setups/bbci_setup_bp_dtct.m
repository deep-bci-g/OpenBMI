opt = [];
opt.clab = {'not','E*','Fp*','AF*','I*'};
opt.ival = [-1300 0]-120;
opt.rest_shift = -1000;
opt.band = [0.8 4];
opt.fftparams = {128,150};
opt.jMeans = 5;
opt.model = 'LDA';
opt.laplace = 0;
opt.dar_ival = [-1500 1000];
opt.ilen_apply = diff(opt.ival);
opt.classiclab = {'P5-6','CP5-6','C5-6','FC5-6'};