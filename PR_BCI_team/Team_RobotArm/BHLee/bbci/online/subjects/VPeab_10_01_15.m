%bbci.train_file='VPeab_10_01_15/imag_fbarrow_pmeanVPeab'
bbci.train_file='VPeab_10_01_15/imag_fbarrow_pcovmeanVPeab'
%bbci.train_file='VPeab_10_01_15/real_movementVPeab'
bbci.classDef = {1,2;'left','right'};
bbci.player = 1;
bbci.setup = 'cspauto';
%bbci.save_name = 'VPeab_10_01_15/imag_fbarrow_pmeanVPeab';
bbci.save_name = 'VPeab_10_01_15/imag_fbarrow_pcovmeanVPeab';
%bbci.save_name = 'VPeab_10_01_15/real_movementVPeab';
bbci.feedback = '1d';
bbci.classes = {'left','right'};
bbci.setup_opts.reject_artifacts=0;
bbci.withgraphics=0;
