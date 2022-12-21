public with sharing class BcConnectAdminController {
	@auraEnabled
    Public Static bcConnectconfig getBcConnectConfigs(){
        bcConnectconfig configs=new bcConnectconfig();
        
        //We use the protected custom setting to store the config values in salesforce
        bcConnectConfig__c mc = bcConnectConfig__c.getValues('bcConnectConfigs');
        
        if(mc != null){
            configs.Region = mc.Region__c;
            configs.CreateTaskForInboundCall = mc.CreateTaskForInboundCall__c;
            configs.CreateTaskForOutboundCall = mc.CreateTaskForOutboundCall__c;
            configs.OpenDialerAndPrefillOutboundNumber = mc.OpenDialerAndPrefillOutboundNumber__c;
            configs.CreateLeadForNewCall = mc.Create_Lead_Upon_Call__c;
            configs.NewLeadName = mc.New_Lead_Name__c;
        }else{
            configs.Region = '';
            configs.CreateTaskForInboundCall = false;
            configs.CreateTaskForOutboundCall = false;
            configs.OpenDialerAndPrefillOutboundNumber = false;
            configs.CreateLeadForNewCall = false;
            configs.NewLeadName = '';
        }
        
        return configs;
    }
    
    @auraEnabled
    Public Static string updateBcConnectConfigs(string updatedConfigString){
        if(string.isNotBlank(updatedConfigString)){
            bcConnectconfig configs=(bcConnectconfig)JSON.deserialize(updatedConfigString, bcConnectconfig.class);
            
            //We use the protected custom setting to store the config values in salesforce
        	bcConnectConfig__c mc = bcConnectConfig__c.getValues('bcConnectConfigs');
            
            if(mc==null){
                mc = new bcConnectConfig__c();
            }
            
            mc.Name='bcConnectConfigs';
            mc.Region__c=configs.Region;
            mc.CreateTaskForInboundCall__c=configs.CreateTaskForInboundCall;
            mc.CreateTaskForOutboundCall__c=configs.CreateTaskForOutboundCall;
            mc.OpenDialerAndPrefillOutboundNumber__c=configs.OpenDialerAndPrefillOutboundNumber;
            mc.Create_Lead_Upon_Call__c = configs.CreateLeadForNewCall;
            mc.New_Lead_Name__c = configs.NewLeadName;
            
            try{
                SObjectAccessDecision securityDecision = Security.stripInaccessible(
                    AccessType.UPSERTABLE,
                    new List<bcConnectConfig__c>{ mc },
                    true
                );
                upsert securityDecision.getRecords();
                
                return 'ConfigsUpdatedSuccessfully';
            }catch(exception e){
                return e.getMessage();
            }
        }
        return 'No Data passed back to Controller.';
    }
    
    public class bcConnectconfig{
        @auraEnabled public string Region;
        
        // if set to true, a new lead will be created for any inbound or outbound call.
        @auraEnabled public boolean CreateLeadForNewCall; 
        
        // Will decide the name of the new lead that we need to create.
        @auraEnabled public String NewLeadName; 
        
        // if set to true, a new task will be created for all inbound calls.
        @auraEnabled public boolean CreateTaskForInboundCall; 
        
        // if set to true, a new task will be created for all outbound calls.
        @auraEnabled public boolean CreateTaskForOutboundCall; 
        
        // if set to true, click to dial will only fill the number and not dial it directly.
        @auraEnabled public boolean OpenDialerAndPrefillOutboundNumber; 
    }
}