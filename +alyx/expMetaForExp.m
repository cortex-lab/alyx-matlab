function expMets = expMetaForExp(ai, expUrl)

allMeta = alyx.getData(ai, 'http://alyx.cortexlab.net/exp-metadata');

isThisExp = cell2mat(cellfun(@(x)strcmp(x.experiment, expUrl), allMeta, 'uni', false));

expMets = allMeta(isThisExp);