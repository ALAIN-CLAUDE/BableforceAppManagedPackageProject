public class BableForceDialerController {
    @AuraEnabled
    Public Static bcConnectconfig getBcConnectConfigs(){
        bcConnectconfig configs=new bcConnectconfig();
        
        //We use the protected custom setting to store the config values in salesforce
        bcConnectConfig__c mc = bcConnectConfig__c.getValues('bcConnectConfigs');
        
        if(mc != null){
            configs.Region = mc.Region__c;
            configs.CreateTaskForInboundCall = mc.CreateTaskForInboundCall__c;
            configs.CreateTaskForOutboundCall = mc.CreateTaskForOutboundCall__c;
            configs.OpenDialerAndPrefillOutboundNumber = mc.OpenDialerAndPrefillOutboundNumber__c;
        }else{
            configs.Region = '';
            configs.CreateTaskForInboundCall = false;
            configs.CreateTaskForOutboundCall = false;
            configs.OpenDialerAndPrefillOutboundNumber = false;
        }
        
        return configs;
    }
    
    @AuraEnabled //this method will update the LastFocusedUrl__c field on the custom setting, so we can check which tab was focused last.
    Public Static void updateLastFocusedUrl(string newLocation){
        bcConnectConfig__c mc = bcConnectConfig__c.getValues('bcConnectConfigs');
        if(mc != null && string.isNotBlank(newLocation)){
            mc.LastFocusedUrl__c = newLocation;
            
            try{
                update mc;
            }catch(exception e){}
        }
    }
    
    //Methods creates a new task after seraching for record in salesofrce. It either finds a lead or contact and creates a task for it.
    @AuraEnabled
    Public Static string createNewTask(string callInformation,string currentSetUrlForComponent){
        String OriginalCallInformation = callInformation;
        //get the last focused url from custom setting and compare it with currentSetUrlForComponent to decide if task needs to be created.
        bcConnectConfig__c mc = bcConnectConfig__c.getValues('bcConnectConfigs');
        
        if(String.isNotBlank(callInformation)){
            callInformation=callInformation.replace('"from"','"from_x"');
            
            callParameters callInfo=(callParameters)JSON.deserialize(callInformation, callParameters.class);
            string clienPhoneNumber = callInfo.type == 'inbound' ? callInfo.from_x : callInfo.to ;
            //find the parent record in salesforce
            String ParentId = BableForceDialerController.findSobjectRecords(OriginalCallInformation,clienPhoneNumber,currentSetUrlForComponent);
            
            if(String.isNotBlank(ParentId)){
                // if existing record found in the system, create a new task 
                Task newTask=new Task();
                newTask.Priority = 'Normal';
                newTask.Status = 'Not Started';
                newTask.Subject=callInfo.type == 'inbound' ? callInfo.type+' call from '+callInfo.from_x : callInfo.type+' call to '+callInfo.to ;
                newTask.CallType = callInfo.type;
                newTask.whoId = ParentId;                     
                newTask.TaskSubtype = 'Call';
                
                try{
                    insert newTask;
                    return newTask.id;
                }catch(exception e){
                    return e.getMessage();
                }
            }else{
                // if the option is set to false we just create a new task and redirect to that task.
                
                Task newTask=new Task();
                newTask.Priority = 'Normal';
                newTask.Status = 'Not Started';
                newTask.Subject=callInfo.type == 'inbound' ? callInfo.type+' call from '+callInfo.from_x : callInfo.type+' call to '+callInfo.to ;
                newTask.CallType = callInfo.type;
                newTask.TaskSubtype = 'Call';
                try{
                    insert newTask;
                    return newTask.id;
                }catch(exception e){
                    return e.getMessage();
                }
            }
            
        }else{
            return 'No Call Information Provided';
        }
    }
    
    // It looks up a record in saelsforce based on the phone number..
    @AuraEnabled
    public Static String findSobjectRecords(string callInformation,String phoneNumber,string currentSetUrlForComponent){
        bcConnectConfig__c mc = bcConnectConfig__c.getValues('bcConnectConfigs');
        if(String.isNotBlank(phoneNumber)){
            phoneNumber=phoneNumber.replaceAll('[^0-9]', '');
            System.debug('phoneNumber==>'+phoneNumber);
            List<List<SObject>> searchList = [FIND :phoneNumber IN PHONE FIELDS RETURNING Lead(id order by createdDate desc limit 1), Contact(id order by createdDate desc limit 1)];
            System.debug('phoneNumber==>'+searchList);
            List<Lead> leads = (List<Lead>)searchList[0];
            List<Contact> Contacts = (List<Contact>)searchList[1];
            
            if(Contacts.size() > 0){
                return Contacts[0].id;
            }else if(leads.size() > 0){
                return leads[0].id;
            }else{
                // the admin configs will decide if we need to create a new lead or not.
                if(mc.Create_Lead_Upon_Call__c){                
                    //No record found in salesforce for the given number. Create a new Lead...
                    if(String.isNotBlank(callInformation)){
                        callInformation=callInformation.replace('"from"','"from_x"');
                        
                        callParameters callInfo=(callParameters)JSON.deserialize(callInformation, callParameters.class);
                        system.debug('==============> '+Json.serializePretty(callInfo));
                        Lead lead = new Lead();
                        lead.Company='Default Company';
                        
                        if(String.isNotBlank(mc.New_Lead_Name__c)){
                            lead.LastName=callInfo.type == 'inbound' ? mc.New_Lead_Name__c+ '-' +callInfo.from_x : mc.New_Lead_Name__c+ '-' +callInfo.to ;
                        }else{
                            lead.LastName=callInfo.type == 'inbound' ? callInfo.type+' call from '+callInfo.from_x : callInfo.type+' call to '+callInfo.to ;
                        }
                        
                        lead.Phone= callInfo.type == 'inbound' ? callInfo.from_x : callInfo.to ;
                        try{
                            insert lead;
                            system.debug('inserted lead idss=======> '+lead.Id);
                            return lead.id;
                        }catch(exception e){
                            return e.getMessage();
                        }
                    }
                }
            } 
            
        }
        
        return null;
    }
    
    public class bcConnectconfig{
        @auraEnabled public string Region;
        
        
        // if set to true, a new task will be created for all inbound calls.
        @auraEnabled public boolean CreateTaskForInboundCall; 
        
        // if set to true, a new task will be created for all outbound calls.
        @auraEnabled public boolean CreateTaskForOutboundCall; 
        
        // if set to true, click to dial will only fill the number and not dial it directly.
        @auraEnabled public boolean OpenDialerAndPrefillOutboundNumber; 
    }
    
    public class callParameters{
        // a unique id for the call generated by the system.
        @auraEnabled public string id; 
        
        // from number for the call.
        @auraEnabled public string from_x;
        
        // to number for the call.
        @auraEnabled public String to; 
        
        // what state the call is in right now, in-progress,scheduled,completed,ringing etc.
        @auraEnabled public string state; 
        
        // type of call, inbound or outbound.
        @auraEnabled public String type; 
    }
}