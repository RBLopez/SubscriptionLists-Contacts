/*
	Tests subscription list logic on contact insert & update, and on unsubscribing from a campaignMember
*/

@isTest
public class Test_Subscriptions {
	
	//create method that will give you a new subscriptionList object, with one option 'baked in'
	public static Subscription_List__c newSubscriptionList(String listname) {
    	Subscription_List__c thelist = new Subscription_List__c(Name=listname);
    	if (listname=='Calendar') {
    		thelist.Checkbox_Field__c = 'EM_Calendar__c';
    		thelist.Picklist_Field__c = 'EMList_Calendar__c';
    		thelist.Start_Date_Field__c = 'EMStartDate_Calendar__c';
    		thelist.End_Date_Field__c = 'EMEndDate_Calendar__c';	
    	}
    	return thelist;
    }
	
	static testmethod void testSubscriptionInsert() {
    	Subscription_List__c thelist = newSubscriptionList('Calendar');
    	insert thelist;
    	Contact con = new Contact (LastName='Test');
    	con.EMList_Calendar__c = 'Subscribed';
    	Test.startTest();
    	insert con;
    	Test.stopTest();
    	con = [Select Id, EM_Calendar__c, EMStartDate_Calendar__c from Contact where Id=:con.Id];
    	system.assertEquals(true, con.EM_Calendar__c);
    	system.assertEquals(date.today(), con.EMStartDate_Calendar__c);
    }
    
    static testmethod void testSubscriptionUpdate() {
    	Subscription_List__c thelist = newSubscriptionList('Calendar');
    	insert thelist;
    	Contact con1 = new Contact (LastName='Test1');
    	con1.EM_Calendar__c = true;
    	Contact con2 = new Contact (LastName='Test2');
    	insert con1;
    	insert con2;
		con1 = [Select Id, EMList_Calendar__c from Contact where Id=:con1.Id];
		con2 = [Select Id, EMList_Calendar__c from Contact where Id=:con2.Id];
		system.assertequals('Subscribed', con1.EMList_Calendar__c);
		con1.EM_Calendar__c = false;
		con2.EMList_Calendar__c = 'Subscribed';
		List<Contact> conlist = new List<Contact>{con1, con2};
		Test.startTest();
		update conlist;
		Test.stopTest();
    	con1 = [Select Id, EMList_Calendar__c, EMEndDate_Calendar__c from Contact where Id=:con1.Id];
		con2 = [Select Id, EMList_Calendar__c, EMStartDate_Calendar__c from Contact where Id=:con2.Id];
		system.assertequals(date.today(), con1.EMEndDate_Calendar__c);
		system.assertequals('Unsubscribed', con1.EMList_Calendar__c);
		system.assertequals(date.today(), con2.EMStartDate_Calendar__c);
		system.assertequals('Subscribed', con2.EMList_Calendar__c);
    }
    
    private static testmethod void testCampaignUnsubscribe () {
		//create the calendar subscription
		Subscription_List__c thelist = newSubscriptionList('Calendar');
    	insert thelist;
    	//create a new email with that subscription attached
    	Campaign email = new Campaign(Name='Test Campaign');
    	email.Email_Preference__c = thelist.Id;
    	insert email;
    	//create a contact that is subscribed to that list and a member in the email campaign
    	Contact con = new Contact (LastName='Test', EMList_Calendar__c = 'Subscribed');
    	insert con;
    	CampaignMember member = new CampaignMember(ContactId=con.Id, CampaignId = email.Id);
    	insert member;
    	//now, unsubscribe the contact throught the campaign member
    	member.sbm__sbx_EmailUnsubscribed__c = true;
    	Test.startTest();
    	update member;
    	Test.stopTest();
		//show that the contact is unsubscribed
		con = [Select Id, EMList_Calendar__c, EMEndDate_Calendar__c from Contact where Id=:con.Id];
		system.assertEquals('Unsubscribed', con.EMList_Calendar__c);
		system.assertEquals(date.today(), con.EMEndDate_Calendar__c);		
	}

}