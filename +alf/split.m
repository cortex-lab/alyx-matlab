function parts = split(fileName, outkey)
%     Return the object, type and extention for a given ALF file name
%
%     Example:
%         alf_parts('trials.choice.npy')
%         {'', 'trials', 'choice', 'npy'}
%         alf_parts('_misc_trials.choice.npy')
%         {'misc', 'trials', 'choice', 'npy'}
%
%     Args:
%         fileName (str): The name of the file
%
%     Returns:
%         nsp (str): ALF namespace
%         obj (str): ALF object
%         typ (str): The ALF attribute
%         ext (str): The file extension

if nargin < 2; outkey = 'tokens'; end
pattern = '((?:_)(?<nsp>.+)(?:_))?(?<obj>.+)\.(?<typ>.+)\.(?<ext>.+)';
parts = regexp(fileName, pattern, outkey);