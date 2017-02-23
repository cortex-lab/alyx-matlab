

function expTimelinePlot(ai, exp, ax)
% function expTimelinePlot(ai, exp, ax)
% Plots a timeline of the experiment given by the alyx struct exp into axes
% ax. 

expMets = alyx.expMetaForExp(ai, exp.url);
nowTime = (now-alyx.datenum(exp.start_time))*24*3600;

classNames = cellfun(@(x)x.classname, expMets, 'uni', false);
startTimes = cell2mat(cellfun(@(x)x.start_time, expMets, 'uni', false));
endTimes = cellfun(@(x)x.end_time, expMets, 'uni', false);
endTimes = cell2mat(cellfun(@(x)thenOrNow(x,nowTime), endTimes, 'uni', false));

hold off;
for q = 1:length(expMets)
    plot(ax, [startTimes(q) endTimes(q)], [q q], 'LineWidth', 2.0);
    hold on;
end
ylim([0 length(expMets)+1]);
set(ax, 'YTick', 1:length(expMets), 'YTickLabel', classNames);
xlim([0 nowTime]);
xlabel('time since experiment start (sec)');
box off; 

function thisTime = thenOrNow(endTime, nowTime)
if isempty(endTime)
    thisTime = nowTime;
else
    thisTime = endTime;
end
