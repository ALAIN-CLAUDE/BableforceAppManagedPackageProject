({
    handleEventsFromIframe : function(component,newEvent) {
        //console.log('Url recieved');
        //console.log(newEvent.context.mostRecentUrl);
        let lastUrl = component.get('v.lasturl');
        
        //console.log('Url we have');
        //console.log(lastUrl);
        
        if(newEvent.event == 'babelconnect.init'){
            //bableconnect initialised code goes here.......
            this.handleSoftPhoneInitialisation(component,newEvent);
        }else if(newEvent.event == 'babelconnect.user.loaded'){
            //User just logged in, enable click to dial...
            this.handleSoftPhoneUserLoading(component,newEvent);
            
        }else if(newEvent.event == 'babelconnect.user.logoff'){
            //User just logged out, disable click to dial...
            this.handleSoftPhoneUserLoggingOff(component,newEvent);
            
        }else if(newEvent.event == 'babelconnect.cti.call'){
            //whenever an inbound or outbound call is made using babbleconnect CTI.
            //if(newEvent.context.mostRecentUrl == lastUrl){
            	this.handleSoftPhoneCall(component,newEvent);
           // }
        }
    },
    
    handleSoftPhoneInitialisation : function(component,newEvent) {
        
    },
    
    //This method will be called whenever a user is loaded or is signed in to the softphone.
    handleSoftPhoneUserLoading : function(component,newEvent) {
        // Here we assign the value of this into the self variable
        var self = this;
        
        sforce.opencti.enableClickToDial({
            callback: function() {
                //Once the click to dial is enabled, listen for all the dial clicks and dial them feom bc-connect.
                self.addClickToDialListner(component);
            }
        });
    },
    
    //This method will be called whenever a user loggs out of the softphone.
    handleSoftPhoneUserLoggingOff : function(component,newEvent) {
        sforce.opencti.disableClickToDial({
            callback: function() {
                console.log('changed');
            }  
        });
    },
    
    //Adds a listener for all the click to dial events and sends a new event to dial the clicked number.
    addClickToDialListner : function(component) {
        var self = this;
        sforce.opencti.onClickToDial({
            listener: function(payload){
                sforce.opencti.setSoftphonePanelVisibility({
                    visible:true, 
                    callback:function(){
                        let configs = component.get('v.config');
                        
                        if(configs.OpenDialerAndPrefillOutboundNumber){
                            //Called when we only need to prefill the number instead of directly calling it.
                            self.handleClickToDial(component,payload.number,false);
                        }else{
                            // Called when we need to call the number directly using click to dial.
                            self.handleClickToDial(component,payload.number,true);
                        }
                    }  
                });
            }
        })
    },
    
    // this method will either directly call the clicked number or prefill it in case of click to dial.
    //preFillNumber parameter decides if it will only prefill the number or call it.
    handleClickToDial : function(component,PhoneNumber, preFillNumber){
        var vfWindow = component.find("vfFrame").getElement().contentWindow;
        var vfOrigin =component.get("v.ifameUrlWithRegion");///newly added
        // start click2call by sending an event
        vfWindow.postMessage({
            type: 'connect',
            module: 'calls',
            name: 'dial',
            args: {
                to: PhoneNumber,
                dial : preFillNumber
            }
        }, vfOrigin);
    },
    
    // Called where there is a call made or recieved by the dialer.
    handleSoftPhoneCall : function(component, newEvent){
        var self = this;
        console.log(newEvent);
        if(newEvent.data && newEvent.data.call){
            let callInfo = newEvent.data.call;
            let configs = component.get('v.config');
            
            if(callInfo.type == 'outbound' && callInfo.state == 'in-progress'){
                // when a new call is made from salesforce..
                self.handleOutboundCall(component, callInfo, configs);
                
                
            }else if(callInfo.type == 'inbound' && callInfo.state == 'in-progress'){
               // when a new call is recieved in salesforce..
               console.log('going to handle inbound call.');
                self.handleInboundCall(component, callInfo, configs);
            }
        }
        
    },
    
    
    // Called where there is an outbound call is in progress.
    handleOutboundCall : function(component, callInfo, configs){
        //Process outbound call only if we have an outbound call in "in-Progree" state as we recieve different call events for all states of a call.
        console.log('task creation allowed == '+configs.CreateTaskForOutboundCall);
        if(configs.CreateTaskForOutboundCall){
            // if task creation is configured for outbound call, we create a new task and open the detail page for that task.
            this.callApextoCreateTask(component,callInfo);
        }else{
            // if task creation is not selected, open the detail page for the contact or lead record.
            this.callApextogetParentRecord(component,callInfo);
        }
                
    },
    
    // Called where there is an inbound call in progress.
    handleInboundCall : function(component, callInfo, configs){
         // when a new call is recieved in salesforce..
        var self = this;        
        sforce.opencti.setSoftphonePanelVisibility({
            visible:true, 
            callback:function(){
                if(configs.CreateTaskForInboundCall){
                    // if task creation is configured for outbound call, we create a new task and open the detail page for that task.
                    self.callApextoCreateTask(component,callInfo);
                }else{
                    // if task creation is not selected, open the detail page for the contact or lead record.
                    self.callApextogetParentRecord(component,callInfo);
                }
            }
        });
    },
    
    callApextoCreateTask : function(component, callInfo){
		debugger;
        console.log('apexmethodcalled');
        $A.getCallback(function() {
            var createTaskAction = component.get("c.createNewTask");
            
            createTaskAction.setParams({
                callInformation : JSON.stringify(callInfo),
                currentSetUrlForComponent : component.get('v.lasturl')
            });
            
            createTaskAction.setCallback(this, function(response){
                if(response.getState() === "SUCCESS"){
                    var result = response.getReturnValue();
                    console.log(result);
                    if(result.startsWith('00T')){
                        
                        sforce.opencti.screenPop({
                            type : sforce.opencti.SCREENPOP_TYPE.SOBJECT,
                            params : { recordId : result },
                            callback : function(response) {
                            }
                        }); 
                        
                    } 
                }
            });
            
            
            $A.enqueueAction(createTaskAction); 
        })();    
    },
    
    //this method will get the contact or lead id using apex, when create a task option is not selected.
    callApextogetParentRecord : function(component, callInfo){
        debugger;
        let clientNumber = callInfo.type == 'inbound' ? callInfo.from : callInfo.to ;
        $A.getCallback(function() {
            var findRecordAction = component.get("c.findSobjectRecords");
            
            findRecordAction.setParams({
                callInformation : JSON.stringify(callInfo),
                phoneNumber : clientNumber,
                currentSetUrlForComponent : component.get('v.lasturl')
            });
            
            findRecordAction.setCallback(this, function(response){
                if(response.getState() === "SUCCESS"){
                    var result = response.getReturnValue();
                    console.log(result);
                    if(result.startsWith('00Q') || result.startsWith('003')){
                        console.log('result confirmed as contact or lead.');
                        
                        sforce.opencti.screenPop({
                            type : sforce.opencti.SCREENPOP_TYPE.SOBJECT,
                            params : { recordId : result },
                            callback : function(response) {}
                        }); 
                           
                    } 
                }
            });
        
        
            console.log('in get callback for recxord');
            $A.enqueueAction(findRecordAction); 
        })();
    }
    
    
    
})