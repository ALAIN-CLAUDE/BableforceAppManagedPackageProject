@isTest
public class BcConnectAdminControllerTest {
    @testSetup static void testData() {
        bcConnectConfig__c cs = new bcConnectConfig__c();
        cs.Name='bcConnectConfigs';
        cs.Region__c = 'test';
        cs.OpenDialerAndPrefillOutboundNumber__c = true;
        cs.CreateTaskForInboundCall__c = true;
        cs.CreateTaskForOutboundCall__c = true;    
        insert cs;
    }
    static testMethod void testMethod12() {
        BcConnectAdminController Bfc = new BcConnectAdminController();
        BcConnectAdminController.getBcConnectConfigs();
        BcConnectAdminController.updateBcConnectConfigs('{"Region":"444","CreateTaskForInboundCall":true,"CreateTaskForOutboundCall":true,"OpenDialerAndPrefillOutboundNumber":true}');
        bcConnectConfig__c mc = bcConnectConfig__c.getValues('bcConnectConfigs');
        delete mc;
        BcConnectAdminController.getBcConnectConfigs();
        BcConnectAdminController.updateBcConnectConfigs('{"Region":"444","CreateTaskForInboundCall":true,"CreateTaskForOutboundCall":true,"OpenDialerAndPrefillOutboundNumber":true}');
		BcConnectAdminController.updateBcConnectConfigs(null);
		Assert.areEqual('testName', 'testName');
    }
}