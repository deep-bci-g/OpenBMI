function update_pcode_repository(varargin)%UPDATE_PCODE_REPOSITORY - Convert Matlab SVN to pcode% Authors: Konrad Grzeska, Benjamin Blankertzglobal BCI_DIR%warning('svn password has to be entered once before running this');opt= propertylist2struct(varargin{:});opt= set_defaults(opt, ...                  'filelist', [BCI_DIR ...                              'toolbox/misc/include_pcode_bbcisvn.txt'], ...                  'rootdir', BCI_DIR(1:end-1), ...                  'pcode_dir', [BCI_DIR(1:end-1) '_pcode'], ...                  'exclude', [BCI_DIR ...                              'toolbox/misc/exclude_pcode_bbcisvn.txt'], ...                  'recursive', 1, ...                  'pcoding', 1, ...                  'test', 0);%                  'exclude_regexp', {'.*~$'}, ...if iscell(opt.filelist),  for ff= 1:length(opt.filelist),    update_pcode_repository(opt, ...                            'filelist', opt.filelist{ff}, ...                            'pcode_dir', opt.pcode_dir{ff});  end  return;endif ischar(opt.exclude) & exist(opt.exclude, 'file'),  opt.exclude= textread(opt.exclude, '%s', ...                        'commentstyle','shell');endfprintf('\n*** Processing filelist %s.\n', opt.filelist);if opt.test,  fprintf('*** TESTING MODE: Changes are only displayed.\n');endwhile opt.rootdir(end)=='/',  opt.rootdir(end)= [];endwhile opt.pcode_dir(end)=='/',  opt.pcode_dir(end)= [];endfilelist= textread(opt.filelist, '%s', ...                   'commentstyle','shell');olddir= pwd;memo_opt.pcoding= opt.pcoding;for i = 1:length(filelist)    filespec = filelist{i};  if isempty(filespec),    continue;  end      opt.pcoding= memo_opt.pcoding;  nopcode_tag= '[nopcoding]';  if strncmp(nopcode_tag, filespec, length(nopcode_tag)),    opt.pcoding= 0;    filespec= deblank(filespec(length(nopcode_tag)+1:end));  end  fullfilespec= [opt.rootdir '/' filespec];  do_update_pcode(fullfilespec, opt);endif ~opt.test,  cmd= sprintf('cd %s; svn add --force *', opt.pcode_dir);  unix_cmd(cmd, 'could not add to svn');  [dmy,user]= unix('whoami');  msg= sprintf('auto pcode update issued by %s', user(1:end-1));  cmd= sprintf('cd %s; svn commit -m "%s" *', opt.pcode_dir, msg);  unix_cmd(cmd, 'could not commit to svn');endcd(olddir);return;function do_update_pcode(fullfilespec, opt)[sourcepath, source]= fileparts(fullfilespec);targetpath= strrep(sourcepath, opt.rootdir, opt.pcode_dir);sourcepathrel= strrep(sourcepath, [opt.rootdir '/'], '');if ~exist(targetpath, 'dir'),  fprintf('making new directory %s.\n', targetpath);  if ~opt.test,    mkdir_rec(targetpath);  endenddd= dir(fullfilespec);dd(strmatch('.',{dd.name},'exact'))= [];dd(strmatch('..',{dd.name},'exact'))= [];for j = 1:length(dd),  filename= dd(j).name;  if ~isempty(strpatternmatch(opt.exclude, [sourcepathrel '/' filename])),    fprintf('excluding %s.\n', [sourcepath '/' filename]);    continue;  end% This works also (optional?):%  if any(apply_cellwise2(regexp(filename, opt.exclude_regexp,'once'), ...%                         'isempty'))%    continue;%  end    if (dd(j).isdir),    if opt.recursive && dd(j).name(1)~='.',      fprintf('recursing into %s.\n', [sourcepath '/' dd(j).name]);      do_update_pcode([sourcepath '/' dd(j).name '/*'], opt);    else      fprintf('skipping directory %s.\n', [sourcepath '/' dd(j).name]);    end    continue;  end  ip= find(filename=='.', 1, 'last');  fileext= filename(ip+1:end);  sourcefile= [sourcepath '/' filename];    if strcmp(fileext, 'm') & opt.pcoding,    targetfile= [targetpath '/' filename(1:ip) 'p'];  else    targetfile= [targetpath '/' filename];  end    if exist(targetfile, 'file') && ~fileisnewer(sourcefile, targetfile),    %fprintf('skipping file %s.\n', sourcefile);    continue;  end  fprintf('  %s', sourcefile);    if ~opt.test,    if strcmp(fileext, 'm') && opt.pcoding,      cd(targetpath);  %% pcode will place all files into the current directory      pcode(sourcefile);      fprintf('  [pcoded]');    else      copyfile(sourcefile, targetfile);      fprintf('  [copied]');    end%    unix_cmd(sprintf('svn add %s', targetfile));  end  fprintf('\n');end