function marker_reveiced= bvr_checkparport(varargin)%BVR_CHECKPARPORT - Check that Parport is connected to BrainAmp System %%Description:% If used with no output arguments, an error produced if no proper% connection is found. Otherwise the result is returned.%%Synopsis:% bvr_checkparport(OPT)% marker_received= bvr_checkparport(OPT)%%Arguments% OPT: struct or property/value list of optional arguments%  'type': Required Marker Type, 'S' or 'R' or 'SR' if both are fine,%      default: 'SR'%  'bv_host': IP or host name of computer on which BrainVision Recorder%      is running, default 'localhost'%%Returns% marker_received: 1 is successful, 0 otherwise%%Note:% Ignore the "Warning: acquire_bv: open a connection first!"% blanker@cs.tu-berlin.de, Jul-2007opt= propertylist2struct(varargin{:});opt= set_defaults(opt, ...                  'type', 'SR', ...                  'bv_host', 'localhost', ...                  'trigger', 2.^[0:7]);if ~iscell(opt.trigger),  opt.trigger= num2cell(opt.trigger);endbvr_sendcommand('viewsignalsandwait');%bbciclose;  %% just to be sure%pause(0.2);state= acquire_bv(100, opt.bv_host);for tt= 1:length(opt.trigger),  trig= opt.trigger{tt},  pause(0.1);  ppTrigger(trig);  marker_received= 0;  tic;  while toc<1 & ~marker_received,    [dmy,bn,mp,mt,md]= acquire_bv(state);    for mm= 1:length(mt),      if str2num(mt{mm}(2:4))==trig,        if ~ismember(mt{mm}(1), opt.type),          justwrongtype= 1;  %% what should we do in this case?        else          marker_received= 1;        end      end    end  endendacquire_bv('close');if nargout==0 && ~marker_received,  msg= 'Parport of this computer not connected to ';  if length(opt.type)==1,    msg= [msg opt.type '-'];  end  msg= [msg 'marker input of BrainAmps'];  error(msg);end