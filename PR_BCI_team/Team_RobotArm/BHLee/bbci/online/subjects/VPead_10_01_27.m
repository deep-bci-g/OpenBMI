%bbci.train_file='VPead_10_01_27/imag_fbarrow_pmeanVPead'
bbci.train_file='VPead_10_01_27/imag_fbarrow_pcovmeanVPead'
%bbci.train_file='VPead_10_01_27/real_movementVPead'
bbci.classDef = {1,2;'left','right'};
bbci.player = 1;
bbci.setup = 'cspauto';
%bbci.save_name = 'VPead_10_01_27/imag_fbarrow_pmeanVPead';
bbci.save_name = 'VPead_10_01_27/imag_fbarrow_pcovmeanVPead';
%bbci.save_name = 'VPead_10_01_27/real_movementVPead';
bbci.feedback = '1d';
bbci.classes = {'left','right'};
bbci.setup_opts.reject_artifacts=0;
bbci.withgraphics=0;