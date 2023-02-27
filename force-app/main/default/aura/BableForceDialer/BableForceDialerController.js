({
    
    doInit: function(component, event, helper) {
        var action = component.get("c.getBcConnectConfigs");
        var  region = '';
        action.setCallback(this, function(response){
            if(response.getState() === 'SUCCESS'){
                var results = response.getReturnValue();
                component.set("v.config",results);
                region = results.Region;
                component.set("v.ifameUrlWithRegion",results.Region);

                sforce.opencti.onNavigationChange({
                    listener: function(payload) {
                        let data=JSON.parse(JSON.stringify(payload));
                        component.set('v.lasturl',data.url);
                        var vfWindow = component.find("vfFrame").getElement().contentWindow;
                        var vfOrigin =component.get("v.ifameUrlWithRegion");
                        vfWindow.postMessage({
                            type: 'connect',
                            module: 'context',
                            name: 'set',
                            args: {
                                mostRecentUrl: data.url
                            }
                        }, vfOrigin);
                    }
                }); 

        } 
       })
        $A.enqueueAction(action);
        
        
    },
    
    demomethod : function(component, event, helper) {
    },
    
    handleEVent : function(component, event, helper) {
        component.set('v.mostrecenturl',event.getParam("callInformation"));
    }
})