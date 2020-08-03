%% Run the Sony 3D Flicker 2 Study
% The acquisition computer and the Sony computer communicate via TCP/IP
% Sony computer:
% - Connect a CRT monitor
% - run 3dserver_flicker2.py 
% - qres.exe must be installed to change the frequency
% - all possible frequencies must have been manually entered in the Nvidia Control 
% Acquisition computer:
% - connect the Sony screen as second monitor via HDMI

% Perception threshold has to be determined first with pilotstudy.m and saved in the TODAY_DIR
tic
record=1 % 1: amplifier connected, record EEG data, 0: testing

VP_CODE=input('Enter VP_CODE used in a previous experiment \nin quotation marks and press <ENTER>. \nIf not known: Only press <ENTER>\n');
%acq_makeDataFolder;

% check that VP_CODE is set and TODAY_DIR exists
if isempty(VP_CODE); error('Define VP_CODE!'); end
if isempty(TODAY_DIR); error('Define TODAY_DIR!'); end

display('Server started?'),pause
setup_sony3d_flicker2

display('Turn off CRT!'),pause
display('Turn on shutter glasses!'),pause

% load perception threshold determined previously
clear freqs, clear f_mean;
filename = strcat([TODAY_DIR 'pilot_' VP_CODE,'-jungle']);
load(filename,'f_mean')
fprintf('Perception threshold of participant %s: %d Hz\n',VP_CODE, f_mean);

% Individual frequencies
perceptionthreshold=f_mean;
upperlimit=97;
lowerlimit=39;
u = lowerlimit + [0 .4 .7]*(perceptionthreshold-lowerlimit); 
o = perceptionthreshold + [.1 .2 .4 .6 .8 1]*(upperlimit-perceptionthreshold);
freqs=[u perceptionthreshold o];
freqs=round((freqs + 1)/2)*2 - 1  
num_freqs = numel(freqs);

% Options
num_repetitions  = 20;
pause_before_pic = 2; % [s]
pause_during_pic = 10; % [s] 

% Duration of the experiment
estimated_time_to_answer = 2; %[s]
estimated_time_between_runs = 15; %[s]
duration = (num_repetitions * estimated_time_between_runs) + num_repetitions * num_freqs * (pause_before_pic + pause_during_pic + 2);
display(['Estimated duration: ', num2str(duration/60), ' minutes']);

% Markers
freq_markers = 2:2:2*num_freqs;
marker_start = 0;
marker_end   = 1;
marker_user_entry = 200;

% Save in TODAY_DIR *.csv-file with markers <--> individual frequencies
fid = fopen([TODAY_DIR 'frequency_list.csv'],'w');
for i=1:num_freqs
  fprintf(fid, '%d, %i\n', freq_markers(i), freqs(i));
end
fclose(fid);

% Load sounds and picture
picture= imread('jungle_normal','jpg');
[ding, Fsd, nbits, readinfo] = wavread('AirPlaneDing');
[bell, Fsb, nbits, readinfo] = wavread('ShipBell');

%% Experiment
rep_start = input('Start with which run? (In case the subject has completed some already) [1]? ');
if isempty(rep_start), rep_start=1; end

display('Hand keybord over to participant..')
pause()

for i = rep_start:num_repetitions
  
  fprintf('Press enter to start run nr. %d/%d!\n', i, num_repetitions);
  pause
  soundsc(ding,Fsd)
   
  %start recording
  if record,  bvr_startrecording(['sony3d_' VP_CODE], 'impedances', 0); end
  pause(3);

  p = randperm(num_freqs);
  for j=1:num_freqs
    
    % Switch frequency (CRT frequency is two times the shutter frequency)
    pnet(tcp_conn, 'printf', 'freq %d %d %d\n', 640,480 , 2 * freqs(p(j)));
    fprintf('Shutter glasses frequency %d Hz, %i/%i\n', freqs(p(j)), j , num_freqs)
    
    %display_message((freqs(p(j))/2)),pause(4),continue 
    
    % Black screen, long enough until frequency is switched
    pause(pause_before_pic); 
    
    % Display image
    fullscreen(picture,2)
    
    % Set marker, when image appears
    ppTrigger(freq_markers(p(j))+ marker_start);
        
    pause(pause_during_pic);
    
    % Blackscreen
    closescreen()
    ppTrigger(freq_markers(p(j))+marker_end);

    user_entry = yesno_input();
    %user_entry = ceil(2.*rand(1,1)); pause(ceil(2.*rand(1,1)));
    
    ppTrigger(marker_user_entry + user_entry);
    soundsc(ding,Fsd)
  end

  pause(1)
  if record,  bvr_sendcommand('stoprecording'); end
  pause(1)
  soundsc(bell,Fsb)
end

%% Close connection
pnet(tcp_conn, 'printf', 'freq %d %d %d\n', 800, 600 ,85);
pnet(tcp_conn, 'close');
fprintf('done!\n');
toc