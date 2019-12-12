function data = loadFile(filepath, ai)
k = strfind(filepath,'.');
ext = filepath(k(end)+1:end);
if nargin > 1; ai = []; end
try
  f = getOr(ai.getData(['data-formats/' ext]), 'matlab_loader_function');
  data = feval(str2func(f), filepath);
catch
  switch lower(ext)
    case 'npy'
      data = readNPY(filepath);
    case {'csv', 'ssv', 'tsv'}
      data = fopen(filepath);
    case {'bin', 'ch', 'cbin'}
      data = fread(filepath);
    case {'mj2', 'mp4'}
      data = VideoReader(filepath);
    case {'m', 'mat', 'fig'}
      data = open(filepath);
    otherwise
      data = load(filepath);
  end
end