%bbci.train_file='VPeaf_10_03_24/imag_fbarrow_pmeanVPeaf'
bbci.train_file='VPeaf_10_03_24/imag_fbarrow_pcovmeanVPeaf'
%bbci.train_file='VPeaf_10_03_24/real_movementVPeaf'
bbci.classDef = {1,2;'left','right'};
bbci.player = 1;
bbci.setup = 'cspauto';
%bbci.save_name = 'VPeaf_10_03_24/imag_fbarrow_pmeanVPeaf';
bbci.save_name = 'VPeaf_10_03_24/imag_fbarrow_pcovmeanVPeaf';
%bbci.save_name = 'VPeaf_10_03_24/real_movementVPeaf';
bbci.feedback = '1d';
bbci.classes = {'left','right'};
bbci.setup_opts.reject_artifacts=0;
bbci.setup_opts.withgraphics=0;
