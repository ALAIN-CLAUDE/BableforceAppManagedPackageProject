public with sharing class BableForceDialerController { 
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
    
   @AuraEnabled
    public static void updateLastFocusedUrl(String newLocation){
        // Enforce CRUD and FLS on bcConnectConfig__c object and its fields
        Schema.DescribeSObjectResult describeResult = bcConnectConfig__c.sObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
        if (Schema.sObjectType.bcConnectConfig__c.isUpdateable() &&
            Schema.sObjectType.bcConnectConfig__c.isAccessible() &&
            fieldMap.get('LastFocusedUrl__c').getDescribe().isUpdateable() &&
            fieldMap.get('LastFocusedUrl__c').getDescribe().isAccessible() ) {
            bcConnectConfig__c mc = bcConnectConfig__c.getValues('bcConnectConfigs');
            if(mc != null && string.isNotBlank(newLocation)){
                mc.LastFocusedUrl__c = newLocation;
                try{
                    update mc;
                } catch(Exception e){}
            }
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
                Task newTask = new Task();
                newTask.Priority = 'Normal';
                newTask.Status = 'Not Started';
                newTask.Subject = callInfo.type == 'inbound' ? callInfo.type+' call from '+callInfo.from_x : callInfo.type+' call to '+callInfo.to ;
                newTask.CallType = callInfo.type;
                newTask.whoId = ParentId;
                newTask.TaskSubtype = 'Call';

                // Check if the user has create permission on the Task object
                if (Schema.sObjectType.Task.isCreateable()) {
                    try{
                        insert newTask;
                        return newTask.id;
                    }catch(exception e){
                        return e.getMessage();
                    }
                } else {
                    return 'You do not have permission to create Task records.';
                }
            } else {
                // if the option is set to false we just create a new task and redirect to that task.

                Task newTask = new Task();
                newTask.Priority = 'Normal';
                newTask.Status = 'Not Started';
                newTask.Subject = callInfo.type == 'inbound' ? callInfo.type+' call from '+callInfo.from_x : callInfo.type+' call to '+callInfo.to ;
                newTask.CallType = callInfo.type;
                newTask.TaskSubtype = 'Call';

                // Check if the user has create permission on the Task object
                if (Schema.sObjectType.Task.isCreateable()) {
                    try{
                        insert newTask;
                        return newTask.id;
                    }catch(exception e){
                        return e.getMessage();
                    }
                } else {
                    return 'You do not have permission to create Task records.';
                }
            }

        } else {
            return 'No Call Information Provided';
        }

    }

    
   // It looks up a record in saelsforce based on the phone number..
    @AuraEnabled
    public Static String findSobjectRecords(string callInformation,String phoneNumber,string currentSetUrlForComponent){
        // Get configuration settings from custom settings object
        bcConnectConfig__c mc = bcConnectConfig__c.getValues('bcConnectConfigs');

        // Remove any non-numeric characters from the phone number
        if (String.isNotBlank(phoneNumber)) {
            phoneNumber = phoneNumber.replaceAll('[^0-9]', '');
        }

        // Initialize empty lists for Contact and Lead objects
        List<Lead> leads = new List<Lead>();
        List<Contact> contacts = new List<Contact>();

        // Check if Contact and Lead objects are accessible and perform search using given phone number
        if (Schema.sObjectType.Lead.isAccessible() && Schema.sObjectType.Contact.isAccessible()) {
            List<List<SObject>> searchList = [FIND :phoneNumber IN PHONE FIELDS RETURNING Lead(Id ORDER BY CreatedDate DESC LIMIT 1), Contact(Id ORDER BY CreatedDate DESC LIMIT 1)];
            leads = searchList[0];
            contacts = searchList[1];
        }

        // If a Contact object is found, return its ID
        if (!contacts.isEmpty()) {
            return contacts[0].Id;
        }

        // If a Lead object is found, return its ID
        if (!leads.isEmpty()) {
            return leads[0].Id;
        }

        // If neither a Lead nor a Contact object is found, create a new Lead object if the configuration settings allow it
        if (mc.Create_Lead_Upon_Call__c && String.isNotBlank(callInformation)) {
            // Replace "from" with "from_x" to avoid JSON parsing errors
            callInformation = callInformation.replace('"from"', '"from_x"');

            // Deserialize the call information JSON string
            callParameters callInfo = (callParameters) JSON.deserialize(callInformation, callParameters.class);

            // Check if Lead object is createable and create new Lead object with appropriate data
            if (Schema.sObjectType.Lead.isCreateable()) {
                Lead lead = new Lead();
                lead.Company = 'Default Company';

                // Set last name based on configuration setting or call information
                if (String.isNotBlank(mc.New_Lead_Name__c)) {
                    lead.LastName = callInfo.type == 'inbound' ? mc.New_Lead_Name__c + '-' + callInfo.from_x : mc.New_Lead_Name__c + '-' + callInfo.to;
                } else {
                    lead.LastName = callInfo.type == 'inbound' ? callInfo.type + ' call from ' + callInfo.from_x : callInfo.type + ' call to ' + callInfo.to;
                }

                // Set phone number based on call information
                lead.Phone = callInfo.type == 'inbound' ? callInfo.from_x : callInfo.to;

                // Insert new Lead object and return its ID
                try {
                    insert lead;
                    return lead.id;
                } catch (Exception e) {
                    return e.getMessage();
                }
            } else {
                // return user does not have permission to create new Lead object
                return 'The current user does not have permission to create a new Lead object';
            }
        }

        // Return null if no record is found and Lead creation is not allowed
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