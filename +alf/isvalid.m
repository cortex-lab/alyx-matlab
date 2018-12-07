function TF = isvalid(fileName)
% Returns a True for a given file name if it is an ALF file, otherwise
% returns False
%     Examples:
%         match = is_alf('trials.feedbackType.npy')
%         match == True
%         >> True
%         match = is_alf('config.txt')
%         match == False
%         >> True
%
%     Args:
%         fileName (str): The name of the file
%
%     Returns:
%         bool
%
pattern = '^(?<obj>.+)\.(?<typ>.+)\.(?<ext>.+)$';
TF = ~isempty(regexp(fileName, pattern, 'once'));