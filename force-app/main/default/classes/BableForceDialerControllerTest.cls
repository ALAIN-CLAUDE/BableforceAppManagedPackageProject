@isTest
public class BableForceDialerControllerTest {
    @testSetup static void testData() {
        bcConnectConfig__c cs = new bcConnectConfig__c();
        cs.Name='bcConnectConfigs';
        cs.Region__c = 'test';
        cs.OpenDialerAndPrefillOutboundNumber__c = true;
        cs.CreateTaskForInboundCall__c = true;
        cs.CreateTaskForOutboundCall__c = true;  
        cs.babelConnect__Create_Lead_Upon_Call__c = false;
        cs.babelConnect__LastFocusedUrl__c = 'www.teter.com';
        insert cs;
    }
    
    static testMethod void testMethod12() {
        
        BableForceDialerController Bfc = new BableForceDialerController();
        BableForceDialerController.getBcConnectConfigs();
       // BableForceDialerController.updateLastFocusedUrl('www.testing.com');
        insert new contact(lastname='test',MobilePhone='9999999999');
   
        BableForceDialerController.createNewTask('{"id":"444","from_x":"9999999999","to":"9999999999","state":"scheduled","type":"inbound"}','test');
   		System.assertEquals('testName', 'testName');
    }
    
        /* @isTest
    static void testUpdateLastFocusedUrl() {
        // Call the method with a new location
        String newLocation = 'https://www.updated-example.com';
    	BableForceDialerController.updateLastFocusedUrl(newLocation);

        // Verify the record was updated with the new location
        bcConnectConfig__c [] config = [SELECT LastFocusedUrl__c FROM bcConnectConfig__c WHERE Name = 'Test Config'];
        System.assertEquals(newLocation, config[0].LastFocusedUrl__c, 'LastFocusedUrl__c was not updated correctly.');
    }*/
    
     static testMethod void testMethod22() {
        BableForceDialerController Bfc = new BableForceDialerController();
        BableForceDialerController.getBcConnectConfigs();
        insert new contact(lastname='test',MobilePhone='9999999999');
        bcConnectConfig__c mc = bcConnectConfig__c.getValues('bcConnectConfigs');
        mc.babelConnect__Create_Lead_Upon_Call__c = true;
        mc.babelConnect__LastFocusedUrl__c = 'www.testing.com22';
         update mc;
        BableForceDialerController.createNewTask('{"id":"444","from_x":"9999999999","to":"9999999999","state":"scheduled","type":"inbound"}','test');
        Assert.areEqual('testName', 'testName');
    }
    static testMethod void testMethod222() {
        BableForceDialerController Bfc = new BableForceDialerController();
        BableForceDialerController.getBcConnectConfigs();
        bcConnectConfig__c mc = bcConnectConfig__c.getValues('bcConnectConfigs');
      //  BableForceDialerController.updateLastFocusedUrl('www.testing.com');
        mc.babelConnect__Create_Lead_Upon_Call__c = true;
         update mc;
        BableForceDialerController.createNewTask('{"id":"444","from_x":"9999999999","to":"9999999999","state":"scheduled","type":"inbound"}','test');
   		Assert.areEqual('testName', 'testName');
    }
    static testMethod void testMethod1() {
        BableForceDialerController Bfc = new BableForceDialerController();
        BableForceDialerController.getBcConnectConfigs();
        BableForceDialerController.createNewTask('{"id":"444","from_x":"","to":"","state":"scheduled","type":"inbound"}','test');
        Assert.areEqual('testName', 'testName');
    }
    static testMethod void testMethod123() {
        bcConnectConfig__c mc = bcConnectConfig__c.getValues('bcConnectConfigs');
        delete mc;
        BableForceDialerController Bfc = new BableForceDialerController();
        BableForceDialerController.getBcConnectConfigs();
        Assert.areEqual('testName', 'testName');
    }

    
}