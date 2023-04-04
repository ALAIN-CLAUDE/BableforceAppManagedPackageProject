/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-31-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@RestResource(UrlMapping='/SyncCustomerDetails/*')
global class  RestSyncCustomerDetails {
    /*
    @HttpGet 
    global static List<sObject> httpGetCustomers(){
        
        try{
            List<Account> retrieveList = [select id ,Syspro_Id__c, name from Account ];
            String searchCustomerId =RestContext.request.requestURI.substringAfterLast('/');
            
            if(!string.isBlank(searchCustomerId)){
                retrieveList = [select id ,Syspro_Id__c,name from Account WHERE Syspro_Id__c != null and Syspro_Id__c = :searchCustomerId];
            }
            return  retrieveList;   
        }catch(Exception ex){
            
            system.debug('Error Message LineNumber==================> '+ex.getLineNumber());
            system.debug('Error Message ==================> '+ex.getMessage());
            return new List<sObject>{};
                }
        
        
        
        
    }
    */
    
    @HttpPut
    global static void httpPutCustomers(){
        respJson respon = new respJson('','');
        RestResponse response = RestContext.response;
        RestRequest request = RestContext.request;
        
        try{
            
            String requestBody = request.requestBody.toString();
            
            system.debug('@@requestBody================> '+requestBody);
            
            
            
            // Convert string to Object
            bodyFromRequest bodyDetails = (bodyFromRequest) System.JSON.deserialize(requestBody, bodyFromRequest.class);
            system.debug('bodyDetails======================> '+JSON.serialize(bodyDetails));
            
            
            map<string,Object> addressMap = new Map<String,Object>();
            map<string,string> addressMap2 = new Map<String,string>();
            map<string,MultipleAddresses> addressMap3 = new Map<String,MultipleAddresses>();
              map<string,Object> addressMap4 = new Map<String,Object>();
            set<string>  KeyCode = new set<string>();
            if(bodyDetails.MultipleAddresses != null){
                for(MultipleAddresses addr : bodyDetails.MultipleAddresses){
                    
                    string keys = addr.AddrCode.removeStart('0');
                    KeyCode.add(keys);
                    system.debug('addr ===============> '+addr.AddrCode.removeStart('0'));
        
                    addressMap.put(string.valueOf(addr.AddrCode.removeStart('0')).trim() , addr);
                    addressMap2.put(keys,json.serialize(addr));
                addressMap3.put(keys,addr);
                     addressMap4.put(addr.AddrCode, addr);
                }
            }
              system.debug(' addressMap ===================> '+addressMap);
             system.debug(' addressMap2 ===================> '+addressMap2);
            system.debug('KeyCode===================> '+ KeyCode);
             system.debug(' addressMap4 ===================> '+addressMap4);
            
            list<account> existingAccountRecord = [select id ,Syspro_Id__c, name from Account where Syspro_Id__c = :bodyDetails.Customer];
                   system.debug('existingAccountRecord===================> '+existingAccountRecord);
            // Map<id,account> existingAccountRecordMap = new Map<id,account>([select id ,Syspro_Id__c, name from Account where Syspro_Id__c = :bodyDetails.Customer]);  
            Map<string,RetailStore> accountRetailStoreMap = new Map<string,RetailStore>();
            for(RetailStore rs:[SELECT Id, Name, AccountId, LocationId, Street, State, City, PostalCode, Country, Shipping_Instructions_Code__c, Description FROM RetailStore where AccountId = : existingAccountRecord[0].id] ){//and Shipping_Instructions_Code__c in : KeyCode
                accountRetailStoreMap.put(rs.Id,rs);
            }
            
             system.debug('accountRetailStoreMap==================> '+accountRetailStoreMap);
            list<account> upsertAccount = new  list<account>();
            
            
            list<RetailStore> updateRetailStore = new  list<RetailStore>();
                list<RetailStore> insertRetailStore = new  list<RetailStore>();
            if(!existingAccountRecord.isEmpty()){  
                
                if(!accountRetailStoreMap.isEmpty()){
                    
                    for(Id recId: accountRetailStoreMap.keySet()){
                        RetailStore curRec = accountRetailStoreMap.get(recId);
                         system.debug('curRec  ======================> '+curRec); 
                        
                     
                        string  requestCode = string.valueOf(curRec.Shipping_Instructions_Code__c);
                        system.debug('requestCode ======================> '+requestCode);   
                   
                        if(requestCode != null){
                          /*  for(MultipleAddresses addressDetails : addressMap3.values()){
                                system.debug('requestCode inner ======================> '+requestCode); 
                               system.debug('ob.postal===================> '+addressDetails.AddrCode);//AddrCode
                                system.debug('remove first zero same ======> '+string.valueOf(addressDetails.AddrCode.removeStart('0')));
                           string jsonKey = string.valueOf(addressDetails.AddrCode.removeStart('0')).trim();
                             integer reqCod = integer.valueOf(requestCode);
                             integer formCod = integer.valueOf(jsonKey);
                                  system.debug('reqCod===========> '+addressDetails);
                                  system.debug('formCod ===========> '+addressDetails);
                                //if(integer.valueOf(requestCode) == integer.valueOf(jsonKey)){
                                //    system.debug('addressDetails===========> '+addressDetails);
                                //}
                            }*/
                               system.debug('addressMap.get(requestCode)====> '+addressMap.get(requestCode));
                            string addressValues =Json.serialize(addressMap.get(requestCode));
                          MultipleAddresses addressDetails = (MultipleAddresses)System.JSON.deserialize(addressValues, MultipleAddresses.class);
                    
                       system.debug('addressDetails tip tip postal====> '+ addressDetails.MShipPostalCode);
                        system.debug('addressDetails json ====> '+Json.serializePretty(addressDetails));
                         updateRetailStore.add(new RetailStore(id=curRec.Id, Street=addressDetails.MShipToAddr2 ,City =addressDetails.MShipToAddr3 ,PostalCode= addressDetails.MShipPostalCode));
                        } 
                else{
                     RetailStore rs = new RetailStore();
                    rs.Name = addressDetails.ShipToName;
                    rs.AccountId = existingAccountRecord[0].id;
                    rs.City = addressDetails.MShipToAddr3;
                    rs.Street = addressDetails.MShipToAddr2;
                    rs.PostalCode= addressDetails.MShipPostalCode;
                    insertRetailStore.add(rs);
                }
                    }
                }
            
                if(!insertRetailStore.isEmpty()){
                     insert insertRetailStore;  
                }
            	
                if(!updateRetailStore.isEmpty()){
                      update updateRetailStore;  
                }
              
                 system.debug(' insertRetailStore======================> '+ insertRetailStore);
                system.debug('updateRetailStore======================> '+JSON.serialize(updateRetailStore));
                system.debug('existingAccountRecordMap======================> '+JSON.serialize(existingAccountRecord[0]));
                upsertAccount.add(new account(Id=existingAccountRecord[0].id,Name = bodyDetails.Name));
        }
             else{
                //insert new account
                Account newAcc = new Account();
                newAcc.Name = bodyDetails.Name;
                newAcc.Syspro_Id__c = bodyDetails.Customer;
                upsertAccount.add(newAcc);
            }
            
            if(!upsertAccount.isEmpty()){
                upsert upsertAccount;
                system.debug('upsertAccount===========> '+upsertAccount);
                respon = new respJson('Success',upsertAccount);
            }
            
            
            
        }catch(Exception ex){
            system.debug('@@Ex'+ex.getLineNumber() +ex.getMessage());
            respon = new respJson(ex.getMessage(),'Line number '+ex.getLineNumber());            
        }
        
        response.addHeader('Content-Type', 'application/json');
        response.responseBody = blob.valueof(json.serialize(respon));   
        
        
    }
    
    
    public class bodyFromRequest{
        public String Customer;	//400003
        public String Name;	//PERKY PETS
        public String ShortName;	//PERKY PETS
        public String CustomerType;	// 
        public String MasterAccount;	// 
        public String StoreNumber;	// 
        public String CreditStatus;	//1
        public Integer CreditLimit;	//400000
        public String Salesperson;	//BP
        public String Salesperson1;	// 
        public String Salesperson2;	// 
        public String Salesperson3;	// 
        public String PriceCode;	//A
        public String CustomerClass;	//IND
        public String Branch;	//HQ
        public String TermsCode;	//01
        public String InvDiscCode;	// 
        public String Area;	//WC
        public String SpecialInstrs;	//BERCO
        public String Telephone;	//021-712-8283
        public String Contact;	//EILEEN
        public String AddTelephone;	// 
        public String Fax;	// 
        public String TelephoneExtn;	//     
        //public String Currency;	//R  
        public String ContractPrcReqd;	//Y
        public String BuyingGroup1;	//A
        public String BuyingGroup2;	// 
        public String BuyingGroup3;	// 
        public String BuyingGroup4;	// 
        public String BuyingGroup5;	// 
        public String ShippingInstrs;	//BERCO
        public String ShippingInstrsCod;	// 
        public String StateCode;	//   
        public String CustomerOnHold;	//N
        public String SoDefaultType;	//  
        public String SoldToAddr1;	//BARAKA PTY LTD T/A PERKY PETS
        public String SoldToAddr2;	//186 MAIN ROAD
        public String SoldToAddr3;	//DIEP RIVER
        public String SoldToAddr3Loc;	//DIEP RIVER
        public String SoldToAddr4;	//WESTERN CAPE
        public String SoldToAddr5;	//SOUTH AFRICA
        public String SoldPostalCode;	//7800
        public String ShipToAddr1;	// 
        public String ShipToAddr2;	//186 MAIN ROAD
        public String ShipToAddr3;	//AVONDALE GARDENS
        public String ShipToAddr3Loc;	//DIEP RIVER
        public String ShipToAddr4;	//WESTERN CAPE
        public String ShipToAddr5;	//SOUTH AFRICA
        public String ShipPostalCode;	//7800
        public String State;	//  
        public String CountyZip;	//     
        public String City;	//   
        public String DeliveryTerms;	//   
        public MultipleAddresses[] MultipleAddresses;
        
    }
    public class MultipleAddresses {
        public String AddrCode;	//02   
        public String ShipToName;	//PERKY PETS - CAPE TOWN
        public String MShipToAddr1;	//PERKY PETS - CAPE TOWN
        public String MShipToAddr2;	//C/O ATLAS ANIMAL FEEDS
        public String MShipToAddr3;	//186 MAIN ROAD
        public String MShipToAddr43Loc;	// 
        public String MShipToAddr4;	// 
        public String MShipToAddr5;	//DIEP RIVER
        public String MShipPostalCode;	//7800
        public String MArea;	// 
        public String MState;	//  
        public String MCountryZip;	//     
        public String MCity;	//   
    }
    
    
    public class respJson {
        public string message{get;set;}
        public object data{get;set;}
        
        public respJson(string message,object data){
            this.message = message;
            this.data = data;
        }
    }
    
    
    
    
}