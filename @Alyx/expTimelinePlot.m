function expTimelinePlot(obj, exp, ax)
% EXPTIMELINEPLOT(obj, exp, ax) Plots a timeline experiment events recorded
% by Alyx
%   TODO: Document!
%
% See also ALYX, EXPMETAFOREXP
%
% Part of Alyx

% 2017 -- created

expMets = obj.expMetaForExp(exp.url);
nowTime = (now-alyx.datenum(exp.start_time))*24*3600;

classNames = cellfun(@(x)x.classname, expMets, 'uni', false);
startTimes = cell2mat(cellfun(@(x)x.start_time, expMets, 'uni', false));
endTimes = cellfun(@(x)x.end_time, expMets, 'uni', false);
endTimes = cell2mat(cellfun(@(x) thenOrNow(x, nowTime), endTimes, 'uni', false));

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
%TODO: Document!
if isempty(endTime)
  thisTime = nowTime;
else
  thisTime = endTime;
end
