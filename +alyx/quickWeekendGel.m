function postWeekendGel = 
    properties (Access=public)
        weekendDates;
    end
    
    properties (Access=private)
        alyxInstance
    end
    
    methods
        function obj = quickWeekendGel(saturdayDate)
            obj.weekendDates = {saturdayDate datestr(1 + datenum(saturdayDate,'yyyy-mm-dd'),'yyyy-mm-dd')};
            
            %Create alyx login instance
            obj.alyxInstance = alyx.loginWindow();
        end
        
        function post(obj,name,gels)
            
            for d = 1:length(obj.weekendDates)
                alyx.postWater(obj.alyxInstance,name,gels(d),[obj.weekendDates{d} 'T12:00:00'],1);
            end
            
        end
        
    end
    
end