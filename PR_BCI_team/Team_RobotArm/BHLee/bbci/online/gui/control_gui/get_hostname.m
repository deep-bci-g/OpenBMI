function sss = get_hostname;if ~isunix    [aaa,sss] = system('hostname');    while strcmp(sss(1),sprintf('\n'))        sss = sss(2:end);    end    sss = sss(1:end-1);    % this is actually 'gethostbyname'.    [b,c] = dos(['tracert ' sss]);    ind1 = strfind(c,'[');    ind2 = strfind(c,']');    if length(ind1)>=1&length(ind2)>=1       sss = c(ind1(1)+1:ind2(1)-1);     endelse    [aaa,sss] = system('hostname -i');    sss= deblank(sss);end