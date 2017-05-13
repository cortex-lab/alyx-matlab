

function postWaterForMouse(mouseName, thisDate)

if nargin<2
    thisDate = floor(now);
else
    thisDate = floor(datenum(thisDate));
end

[expRefs, expDates] = dat.listExps(mouseName);

nExps = sum(expDates==thisDate);
expRefs = expRefs(expDates==thisDate);

if nExps==0
    fprintf(1, 'no experiments for %s on %s\n', mouseName, datestr(thisDate, 'yyyy-mm-dd'));
else
    fprintf(1, 'trying to connect to alyx\n')
    ai = alyx.getToken([], 'Experiment', '123');
    fprintf(1, 'success\n')
    % load the blocks and total up reward delivery sizes
    rewardTotals = zeros(1, nExps);
    for b = 1:nExps
        bPath = dat.expFilePath(expRefs{b}, 'block', 'master');
        if exist(bPath, 'file')
            clear block
            load(bPath);
            if isfield(block, 'rewardDeliveredSizes')
                rew = block.rewardDeliveredSizes;
                if size(rew,2)==1
                    rewardTotals(b) = sum(rew);
                elseif size(rew,2)==2 %laser and water "rewards"
                    % assume water is first
                    rewardTotals(b) = sum(rew(:,1));
                end
                fprintf(1, '%d: %.2f for %s\n', b, rewardTotals(b), expRefs{b});

                clear d
                d.subject = mouseName;
                d.water_administered = rewardTotals(b)/1000; %units of mL
                d.user = 'Experiment';
                %d.date_time = datestr(block.endDateTime, 30);
                d.date_time = datestr(block.endDateTime, 'yyyy-mm-ddTHH:MM:SS');
                newWater = alyx.postData(ai, 'water-administrations', d)

            end
        end
    end

end
