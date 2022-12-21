({
    doInt : function(component, event, helper) {
        var action = component.get("c.getBcConnectConfigs");
        action.setCallback(this, function(response){
            if(response.getState() === 'SUCCESS'){
                var results = response.getReturnValue();
                component.set("v.config",results);
              
                //use the existing selected options to decide values for all available options on admin page.
                let selectedTaskOptions = component.get("v.taskCreationValues");
                if(results.CreateTaskForInboundCall){
                    selectedTaskOptions.push('CreateTaskForInboundCall');
                }
                if(results.CreateTaskForOutboundCall){
                    selectedTaskOptions.push('CreateTaskForOutboundCall');
                }
                if(results.CreateLeadForNewCall){
                    selectedTaskOptions.push('CreateLeadForNewCall');
                }
                component.set("v.taskCreationValues",selectedTaskOptions);
                
                
                //get existing values for click to dial options
                let selectedClickToDialOption = component.get("v.clickToDialValue");
                if(results.OpenDialerAndPrefillOutboundNumber){
                    selectedClickToDialOption='PrefillNumber';
                }else{
                    selectedClickToDialOption='CallDirectly';
                }
                component.set("v.clickToDialValue",selectedClickToDialOption);
                component.set("v.inputValueLink",component.get("v.config.Region"));

                    }
            
        });
        
        $A.enqueueAction(action);

        var workspaceAPI = component.find("workspace");
        workspaceAPI.getAllTabInfo().then(function(response) {
            console.log('opened tab size == '+response.length);
            for(let i=0;i<response.length;i++){
                if (response[i].url.indexOf('bableforce__babelConnect_Admin_Setup') > -1) {
                    workspaceAPI.setTabLabel({
                        tabId: response[i].tabId,
                        label: "babelConnect Admin Setup"
                    });
                }
            }
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    onTabCreated : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getAllTabInfo().then(function(response) {
            console.log('opened tab size == '+response.length);
            for(let i=0;i<response.length;i++){
                if (response[i].url.indexOf('bableforce__babelConnect_Admin_Setup') > -1) {
                    workspaceAPI.setTabLabel({
                        tabId: response[i].tabId,
                        label: "babelConnect Admin Setup"
                    });
                }
            }
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    
    
    updateConfigs : function(component, event, helper){
        
        var regionval = component.get("v.inputValueLink");
      
        var configs= component.get('v.config');
        
        configs.Region = regionval;
        
        var leadNameInput = component.find('leadNameInput');
        if(leadNameInput.get('v.value')){
            configs.NewLeadName = leadNameInput.get('v.value');
        }
        
        var taskCreationInput = component.find('taskCreationInput');
        var selectedInputs = taskCreationInput.get('v.value');
        configs.CreateTaskForInboundCall = false;
        configs.CreateTaskForOutboundCall = false;
        configs.CreateLeadForNewCall = false;
        for(let i=0;i<selectedInputs.length;i++){
            if(selectedInputs[i] == 'CreateTaskForInboundCall'){
                configs.CreateTaskForInboundCall = true;
            }else if(selectedInputs[i] == 'CreateTaskForOutboundCall'){
                configs.CreateTaskForOutboundCall = true;
            }else if(selectedInputs[i] == 'CreateLeadForNewCall'){
                configs.CreateLeadForNewCall = true;
            }
        }
        
        var clickToDialInput = component.find('clickToDialInput');
        if(clickToDialInput.get('v.value')){
            if(clickToDialInput.get('v.value') == 'CallDirectly'){
                configs.OpenDialerAndPrefillOutboundNumber = false;
            }else if(clickToDialInput.get('v.value') == 'PrefillNumber'){
                configs.OpenDialerAndPrefillOutboundNumber = true;
            }
        }
        
        let action = component.get('c.updateBcConnectConfigs');
        
        action.setParams({
            updatedConfigString : JSON.stringify(configs)
        });
        
        action.setCallback(this, function(response){
            if(response.getState() === 'SUCCESS'){
                console.log(response.getReturnValue());
                var toastEvent = $A.get("e.force:showToast");
                if(response.getReturnValue() == 'ConfigsUpdatedSuccessfully'){
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "Configurations has been updated successfully.",
                        "type" : "success"
                    });
                }else{
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": response.getReturnValue(),
                        "type" : "error"
                    });
                }
                toastEvent.fire();
            } 
        });
        
        $A.enqueueAction(action);
    }
})