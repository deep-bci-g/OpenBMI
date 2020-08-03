function H= feedback_cursor_1d_init(fig, opt);

%% most of those things do not really help
fast_fig= {'Clipping','off', 'HitTest','off', 'Interruptible','off'};
fast_axis= {'Clipping','off', 'HitTest','off', 'Interruptible','off', ...
            'DrawMode','fast'};
fast_obj= {'EraseMode','xor', 'HitTest','off', 'Interruptible','off'};
fast_text= {'HitTest','off', 'Interruptible','off', 'Clipping','off', ...
            'Interpreter','none'};

clf;
set(fig, 'Menubar','none', 'Renderer','painters', 'DoubleBuffer','on', ...
	 'Position',opt.position, ...
	 'Color',opt.background, ...
	 'Pointer','custom', 'PointerShapeCData',ones(16)*NaN, fast_fig{:});
set(gca, 'Position',[0 0 1 1], ...
         'XLim',[-1 1], 'YLim',[-1 1], fast_axis{:});
axis off;

d= 2*opt.target_dist;
w= 2*opt.target_width;
nw= opt.next_target_width*w;
target_rect= [-1  -1+d -1+w 1-d;
              1-w -1+d 1 1-d];
target_rect2= [-1   -1+d -1+nw 1-d;
               1-nw -1+d 1 1-d];

for tt= 1:2,
  H.target(tt)= patch(target_rect(tt,[1 3 3 1]), ...
                      target_rect(tt,[2 2 4 4]), ...
                      opt.color_nontarget);
  H.next_target(tt)= patch(target_rect2(tt,[1 3 3 1]), ...
                           target_rect2(tt,[2 2 4 4]), ...
                           opt.color_nontarget);
end
H.center= patch([-1 1 1 -1]*opt.center_size, ...
                [-1 -1 1 1]*opt.center_size, opt.color_center);

set([H.target H.next_target H.center], 'EdgeColor','none', fast_obj{3:end});
H.fixation = line(0, 0, 'Color','k', 'LineStyle','none');
set(H.fixation, fast_obj{3:end}, opt.fixation_spec{:}, 'Visible','off');

if opt.rate_control,
  set(H.center, 'Visible','off');
end

H.msg= text(0, 0, ' ');
set(H.msg,'HorizontalAli','center', 'VerticalAli','middle', ...
          'FontUnits','normalized', opt.msg_spec{:}, fast_text{:});

H.points= text(-0.5, 0.98, 'HIT: 0');
H.points(2)= text(0.5, 0.98, 'MISS: 0');
set(H.points, 'VerticalAli','top', 'HorizontalAli','center', ...
          'FontUnits','normalized', opt.points_spec{:}, fast_text{:});

H.cursor = line(0, 0, 'Color','k', 'LineStyle','none');
set(H.cursor, fast_obj{:}, opt.cursor_inactive_spec{:});

if opt.next_target==0
  set(H.next_target, 'Visible','off');
end
