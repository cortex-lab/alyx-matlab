

function eyeToALF(processedResults, outputDir)
% function eyeToALF(processedResults, outputDir)
%
% Converts an "_processed.mat" file from Michael's etGUI into ALF format
%
% Input argument "processedResults" is the "results" struct from the
% _processed.mat file. 
%
% Is rather selective about which of the many things in this struct are
% actually output

xPos = processedResults.x;
yPos = processedResults.y;
area = processedResults.area;
blink = processedResults.blink;

writeNPY(xPos(:), fullfile(outputDir, 'eye.xPosition.npy'));
writeNPY(yPos(:), fullfile(outputDir, 'eye.yPosition.npy'));
writeNPY(area(:), fullfile(outputDir, 'eye.area.npy'));
writeNPY(blink(:), fullfile(outputDir, 'eye.blink.npy'));