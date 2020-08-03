setup_bbci_bet_unstable; %% needed for acquire_bv
% First of all check that the parllelport is properly conneted.

fprintf('\n\nWelcome to Labrotation 2007\n\n');
try,
  bvr_checkparport('type','S');
catch,
  fprintf('BrainVision Recorder must be running!\nStart it and rerun %s.\n\n', mfilename)
  return;
end

%% Load Workspace into the BrainVision Recorder
bvr_sendcommand('loadworkspace', 'EasyCap_64_motor_dense');
bvr_sendcommand('viewsignals');

acq_getDataFolder;

addpath([BCI_DIR 'stimulation/labrotation_07']);
addpath([BCI_DIR 'acquisition_setups/labrotation_07']);
