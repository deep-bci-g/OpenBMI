global TODAY_DIR REMOTE_RAW_DIR VP_CODE
acq_makeDataFolder('log_dir',1);
REMOTE_RAW_DIR= TODAY_DIR;

[dmy, subdir]= fileparts(TODAY_DIR(1:end-1));
bbci= [];
bbci.setup= 'AEP';
bbci.train_file= strcat(subdir, '\OnlineTrainFile',VP_CODE, '*');
% bbci.train_file= strcat(subdir, '\OnlineTrainShortToneFile',VP_CODE, '*');
% bbci.clab= {'FC3-4', 'F5-6', 'PCP5-6', 'C5-6','CP5-6','P5-6', 'P9,7,8,10','PO7,8', 'E*'};
bbci.clab = {'*'};
% bbci.classDef = {[11:21], [1:8]; 'Target', 'Non-target'};
bbci.func_mrk = 'mrk_helper';
bbci.feedback= '1d_AEP';
bbci.save_name= strcat(TODAY_DIR, 'bbci_classifier');
bbci.fs = 100;
bbci.fb_machine = '127.0.0.1'; 
bbci.host = '127.0.0.1';
bbci.fb_port = 12345;

bbci.allowed_files = {'oddballStandardMessung', 'OnlineTrainFile', 'OnlineRun_no_fb', 'OnlineRun_fake_fb', 'OnlineRun_mask_fb', 'OnlineRun_free_fb'};

bbci.filt.b = [];bbci.filt.a = [];
Wps= [40 49]/1000*2;
[n, Ws]= cheb2ord(Wps(1), Wps(2), 3, 50);
[bbci.filt.b, bbci.filt.a]= cheby2(n, 50, Ws);