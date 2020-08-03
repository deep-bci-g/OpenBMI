
%declareglobals
global ontime; global offtime;
global conversion_tactors_LR; global conversion_tactors_RL;
global socke; global nTactors;
global targets_rounds_designated;
global VP_NUMBER;
global orders_stim2resp;


%% For tactile communication
% Init UDP connection
input ('Start VestByUDP. Press Enter to continue')
path(path, [BCI_DIR 'import/tcp_udp_ip']); socke= pnet('udpsocket', 1111); if socke==-1,
   error('udp communication failed');
end
pnet(socke, 'udpconnect','127.0.0.1', 55555);
nTactors=[]; %?!? nTactors being.. the total amount to control?

%% preperation
ontime=0.2;
offtime=0.15; 
pp_index_nr=mod((VP_NUMBER-1),6)+1;
practice_tactor_nr=0;

conversion_tactors_LR=[27:-1:24, 35:-1:33]; %From left to right
conversion_tactors_RL=[33:35, 24:27]; %From right to left

target_sequence=[1:7];
% load_ExpFiles_Path= 'D:\WERK\Wearable tactile interface project\3_ExperimentPreparation\Exp_Files_Load';
load_ExpFiles_Path='C:\DATA\WearableTactileInterface\1_DATA\Exp_Files_Load'; %'D:\Exp_Files_Load';
cd (load_ExpFiles_Path)
load conditions_order_balanced_list
load condition_stimuli_order;

% Conditions/order
condition_tags= {'Cond1','Cond2','Cond3'};
block_tags= {'Block1','Block2', 'Block3'};
% order= perms(1:length(condition_tags));
% conditionsOrder= uint8(order(1+mod(VP_NUMBER-1, size(order,1)),:));
condition_names={'RandomOrder', 'SemiRandomOrder', 'FixedOrder'};
tekst_block_instruction(1)={'Attend to targets mentally, no motor response is required now.'};
tekst_block_instruction(2)={'Attend to targets mentally, no motor response is required now.'};
tekst_block_instruction(3)={'Now motor response is required too. Respond to targets as fast and accurate as possible, by pressing the button.'};

tekst_condition_instruction(1)={'Stimuli are presented in random order.'};
tekst_condition_instruction(2)={'Stimuli are presented in (semi)random order, but two sequential stimuli are always spatially proximate.'};
tekst_condition_instruction(3)={'Stimuli are presented in a fixed and spatially adjacent order, from right to left and back.'};
tekst_condition_instruction_general='Keep spatial attention always to the current target location.';


%% Accostume to tactile stimuli
% no button responses or EEG recording, just stimulation
ActivateTactors; 

%% Baseline recording of motor responses
sufficient_responses=0;
while sufficient_responses==0;
    
    orders_stim2resp_all= [perms(1:7)];
    orders_stim2resp=[];
    for rand_rep=1:5
        orders_stim2resp_ind=1+round(rand*(5040-1));
        orders_stim2resp=[orders_stim2resp, orders_stim2resp_all(orders_stim2resp_ind,:)];  
    end

    filename_baserecording=bvr_startrecording(['tactile_' 'MotorRespBaseline'], 'impedances',0); %

    MotorRespBaseline
    bvr_sendcommand('stoprecording');

    %check sufficient responses

    [sufficient_responses, nr_responses, nr_pres_stimuli]=CheckResponses(filename_baserecording);

    if sufficient_responses==0
        fprintf ('Insuffient number of responses; there were %s responses.\n', int2str(nr_responses))
    elseif sufficient_responses==1
        fprintf ('Suffient number of responses! There were %s responses.\n', int2str(nr_responses))
    end
end
fprintf ('BaselineRecording was succesful. Press enter to continue.\n'); input('');


%% Practice trials


%% main experimental loop
for block_nr=1:3; %lster integreren
    if block_nr~=1
        fprintf ('Take a break, relax and enjoy some ''Probandenfutter''!\n\n')
    end
    
   
    fprintf ('This is block %s.\n\n%s.\n',  num2str(block_nr), char(tekst_block_instruction(block_nr)) )     
    fprintf ('Press enter when you are ready to start block %s.\n', num2str(block_nr));  input('');
    fprintf ('Block %s is starting.. \n\n', num2str(block_nr))   
    balanced_order=eval(['conditions_order_balanced_list', num2str(block_nr)]); 
    balanced_order_ind=balanced_order(pp_index_nr,:); 
    targets_rounds_designated=conversion_tactors_RL(target_sequence);
    
    for balanced_cond_nr= balanced_order_ind %conditionsOrder,
      fprintf ([num2str(balanced_order_ind) '\n']) %info for during experiment-file creation> to comment
      fprintf ('This is condition %s.\n\n%s\n%s\n',  char(condition_names(balanced_cond_nr)), char(tekst_condition_instruction(balanced_cond_nr)), tekst_condition_instruction_general )   
      fprintf ('Do you have questions? Press enter when you are ready to start the recording.\n'); input('');
      bvr_startrecording(['tactile_' condition_names{balanced_cond_nr} '_' block_tags{block_nr}], 'impedances',0); %
      switch(condition_tags{balanced_cond_nr}),
        case 'Cond1',
%           ConditionControl(Random_Order_LR, Random_Order_RL);
          Order_LR=Random_Order_LR;
          Order_RL=Random_Order_RL;
        case 'Cond2',
%           ConditionFixed (Fixed_Order_LR, Fixed_Order_RL);
          Order_LR=SemiRandom_Order_LR; 
          Order_RL=SemiRandom_Order_RL;
        case 'Cond3',
%           ConditionSemiRandom(SemiRandom_Order_LR, SemiRandom_Order_RL);
          Order_LR=Fixed_Order_LR;
          Order_RL=Fixed_Order_RL;
      end
      ConditionGeneral(Order_LR, Order_RL)
      bvr_sendcommand('stoprecording');
    end  
end

%% extra condition

extra_round=input('Do you want to do an extra condition? Condition is Fast Fixed.\n');

extra_round_wait=0;

while extra_round_wait==0;
    if strcmp(extra_round, 'y')==1
%         ontime=0.15;
        offtime=0; 
        extra_round_wait=1;
        fprintf ('This is condition Fast Fixed.\n\n' )   
        fprintf ('Do you have questions? Press enter when you are ready to start the recording.\n'); input('');
        bvr_startrecording(['tactile_' 'FastFixed' '_' ], 'impedances',0); %
        Order_LR=Fixed_Order_LR;
        Order_RL=Fixed_Order_RL;
        ConditionGeneral(Order_LR, Order_RL)
        bvr_sendcommand('stoprecording');
    elseif strcmp(extra_round, 'n')==1
        extra_round_wait=1;
        fprintf ('This was the experiment. Thank you for participating!\n')
    else
       fprintf ('This was the experiment. Thank you for participating!\n')
    end
end


%% --- - --- Session finished

acq_vpcounter(session_name, 'close');
fprintf('Session %s finished.\n', session_name);











  
%% Leftovers



%% ----- Oddball - 4 different ISIs, randomized order
%


%% Oddball - Practice
% pyff('init', 'VisualOddballVE'); pause(.5);
% pyff('load_settings', ODDBALL_file);
% pyff('setint','nTrials',10);
% stimutil_waitForInput('msg_next','to start Oddball practice.');
% pyff('play');
% stimutil_waitForMarker(RUN_END);
% fprintf('Oddball practice finished.\n')
% pyff('quit');
% 
%% Oddball - Recording
% pyff('init', 'VisualOddballVE'); pause(.5);
% pyff('load_settings', ODDBALL_file);
% stimutil_waitForInput('msg_next','to start Oddball recording.');
% pyff('play', 'basename', 'Oddball', 'impedances', 0);
% stimutil_waitForMarker(RUN_END);
% fprintf('Oddball recording finished.\n')
% pyff('quit');
% fprintf('Press <RETURN> to continue.\n'); pause;

