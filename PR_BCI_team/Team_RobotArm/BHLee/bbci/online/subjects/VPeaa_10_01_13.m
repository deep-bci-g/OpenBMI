%bbci.train_file='VPeaa_10_01_13/imag_fbarrow_pmeanVPeaa'
bbci.train_file='VPeaa_10_01_13/imag_fbarrow_pcovmeanVPeaa'
%bbci.train_file='VPeaa_10_01_13/real_movementVPeaa'
bbci.classDef = {1,2;'left','right'};
bbci.player = 1;
bbci.setup = 'cspauto';
%bbci.save_name = 'VPeaa_10_01_13/imag_fbarrow_pmeanVPeaa';
bbci.save_name = 'VPeaa_10_01_13/imag_fbarrow_pcovmeanVPeaa';
%bbci.save_name = 'VPeaa_10_01_13/real_movenmentVPeaa';
bbci.feedback = '1d';
bbci.classes = {'left','right'};
bbci.setup_opts.reject_artifacts=0;
bbci.withgraphics=0;