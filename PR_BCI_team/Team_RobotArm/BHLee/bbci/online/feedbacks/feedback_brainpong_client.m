function handle = feedback_brainpong_client(fig,fb_opt);% acts as init for brainpong clients
% is called by matlab_feedbacks_client
% 31.1.2006 by Guido
player = fb_opt.client_player;
global werbung werbung_opt
if isempty(werbung)
  werbung = 0;
end
fb_opt = set_defaults(fb_opt,'position',[1600 0 1280 1005],...
  'background_color',[1 1 1],...
  'bat_width',0.2,...
  'bat_height',0.1,...  'bat_color',0.9*[1 1 1],...  'radius',0.1, ...  'exchange_sides',0);
opti= set_defaults([], ...                   'field_color', 0.3*[1 1 1], ...
                   'msg_spec', {'FontSize',0.2, 'Color',0.9*[1 1 1]}, ...
                   'points_x', 0.5, ...
                   'ball_spec', {'FaceColor',0.9*[1 1 1]}, ...
                   'bat_spec', {'FaceColor',0.9*[1 1 1]}, ...
                   'points_spec', {'FontSize',0.1, 'Color',0.9*[1 1 1]}, ...
                   'centerline_spec', {'LineWidth',4, 'Color',0.9*[1 1 1]});
%-----------% init a matlab figure with all its beautyfast_axis= {'clipping','off', 'hitTest','off', 'interruptible','off', ...    'drawMode','fast'};fast_obj= {'EraseMode','xor','hitTest','off', 'interruptible','off'};fast_fig= {'Clipping','off', 'HitTest','off', 'Interruptible','off'};clf;set(fig, 'Menubar','none', 'Resize','off', ...         'position',fb_opt.position);hold on;set(gca, 'Position',[0 0 1 1], 'Color',opti.field_color);set(fig, 'Color',fb_opt.background_color);%-----------% init two bats, get handlesbat1 = patch([0 0 fb_opt.bat_width,fb_opt.bat_width], ...             [-1 -1 fb_opt.bat_height fb_opt.bat_height], 'r');bat2 = patch([0 0 fb_opt.bat_width,fb_opt.bat_width], ...             [1 1 fb_opt.bat_height fb_opt.bat_height], 'r');bat = [bat1,bat2];set(bat,'FaceColor',fb_opt.bat_color, 'EdgeColor','none', opti.bat_spec{:}, ...       fast_obj{3:end});% player 2 (blue) needs other orientation of pong windowif player==2 | (player==1 & fb_opt.exchange_sides),     set(gca,'XDir','reverse','YDir','reverse');  end% init balls, get handleball = patch(fb_opt.radius*cos(2*pi*(1:60)/60), ...             fb_opt.radius*sin(2*pi*(1:60)/60), 'r');set(ball,'EdgeColor','none', 'Visible','off', opti.ball_spec{:}, ...         fast_obj{3:end});set(gca, 'XLim',[-1,1]);set(gca, 'YLim',[-1,1]);% init scoresif player ==1    score(1) = text(-opti.points_x,0.98,'0');    score(2) = text(+opti.points_x,0.98,'0');    score(3) = text(-0.98,-opti.points_x,'0');    score(4) = text(-0.98,+opti.points_x,'0');else    score(2) = text(+opti.points_x,-0.98,'0');    score(1) = text(-opti.points_x,-0.98,'0');    score(3) = text(0.98,-opti.points_x,'0');    score(4) = text(0.98,+opti.points_x,'0');endset(score, 'VerticalAlignment','top', 'HorizontalAlignment','center', ...           'FontUnits','normalized', opti.points_spec{:});set(score([3 4]),'Rotation',90);% init countdowncou = text(0, 0, '5');set(cou,'HorizontalAlignment','center', ...        'FontUnits','normalized', opti.msg_spec{:});% init message field, e.g. for 'you win', 'you loose'win(1) = text(0,0,'');set(win,'HorizontalAlignment','center', ...        'FontUnits','normalized', 'Visible','off', opti.msg_spec{:});% who sees which message...if player==1  win = [nan,nan];else  win = [nan,nan];endl_horiz = line([-1,1],[0,0]);set(l_horiz, 'LineStyle','--', opti.centerline_spec{:});l_vert = line([0 0],[-1 1]);set(l_vert, 'LineStyle','--', opti.centerline_spec{:});set(fig,'DoubleBuffer','on', 'BackingStore','off',...        'Renderer','painters','RendererMode','auto',...        'Pointer','custom', 'PointerShapeCData',ones(16)*NaN,fast_fig{:});set(gca, 'XTick',[], 'YTick',[], ...         'XColor',opti.field_color, 'YColor',opti.field_color, ...         fast_axis{:});% order of handles does matter! (compare to brainpong_feedbacks_master)% give this back to brainpong_feedbacks_clienthandle = [ball, bat, cou, score, win, gca, fig, l_horiz, l_vert];set(setdiff(handle(~isnan(handle)),[gca fig l_vert]),'Visible','off');if werbung  werbung_opt= set_defaults(werbung_opt, ...                            'offset_logo1', 0, ...                            'offset_logo2', 0, ...                            'enlarge_field', 0, ...                            'gap', 8, ...                            'frame_width', 4, ...                            'frame_color',[0 0.5625 0]);                               back = gca;  im1 = imread(werbung_opt.pictures(1).image);  im2 = imread(werbung_opt.pictures(2).image);  sz1= size(im1);  sz2= size(im2);  fsz= get(fig, 'Position');  logo_ax(1)= axes('Position', [0 0 1 1]);  logo_ax(2)= axes('Position', [0 0 1 1]);  set(logo_ax, 'Units','pixel');  xx1= round(fsz(3)/2-sz1(2)/2) + werbung_opt.offset_logo1;  xx2= round(fsz(3)/2-sz2(2)/2) + werbung_opt.offset_logo2;  set(logo_ax(1), 'Position', [xx1 fsz(4)-sz1(1) sz1(2) sz1(1)]);  set(logo_ax(2), 'Position', [xx2 0 sz2(2) sz2(1)]);  field_pos= [round((fsz(3)-max(sz1(2),sz2(2))-werbung_opt.enlarge_field)/2) ...              sz2(1) + werbung_opt.gap + werbung_opt.frame_width ...              max(sz1(2),sz2(2)) + werbung_opt.enlarge_field ...              fsz(4) - sz2(1) - sz1(1) - ...                2*werbung_opt.gap - 2*werbung_opt.frame_width];  frame_pos= field_pos + [-1 -1 2 2]*werbung_opt.frame_width;  frame_ax= axes;  set(frame_ax, 'Units','pixel', 'Position', frame_pos, ...                'XTick',[], 'YTick',[], 'Color',werbung_opt.frame_color, ...                'XColor',werbung_opt.frame_color, ...                'YColor',werbung_opt.frame_color, ...                fast_axis{:});  set(back, 'Units','pixel', 'Position',field_pos);  axes(logo_ax(1));  logo(1)= imagesc(im1);  axes(logo_ax(2));  logo(2)= imagesc(im2);  set(logo_ax, 'Visible','off', fast_axis{:});  axes(back);end