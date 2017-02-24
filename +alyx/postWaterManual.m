

function wa = postWaterManual(mouseName, amount, thisDate, alyxInstance)

if isempty(alyxInstance)
    alyxInstance = alyx.loginWindow();
    if isempty(alyxInstance) % login failed or cancelled
        fprintf(1, 'login failed, no water posted\n');
        return
    end
end

clear d
d.subject = mouseName;
d.water_administered = amount; %units of mL
d.date_time = alyx.datestr(thisDate);
try
    wa = alyx.postData(alyxInstance, 'water-administrations/', d);
catch
    fprintf(1, 'posting failed\n');
end
