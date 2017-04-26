function expMets = expMetaForExp(ai, expUrl)

allMeta = alyx.getData(ai, 'exp-metadata');

isThisExp = cell2mat(cellfun(@(x)strcmp(x.experiment, expUrl), allMeta, 'uni', false));

expMets = allMeta(isThisExp);