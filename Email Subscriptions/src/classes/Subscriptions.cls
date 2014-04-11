/*
	Created by Rosalind Lopez
	0.7 (2013)
	
	Used to manage subscriptions to various 'lists' via fields on a contact record.
	Also used from a trigger on the CampaignMember object to unsubscribe contacts from various 'lists'
*/

public class Subscriptions {

	//main maps of subscription checkbox and picklist fields
	public map<String,List<String>> checkboxMatching;
	public set<String> checkboxList;
	public map<String,List<String>> picklistMatching;
	public set<String> picklistList;
	
	
/** MAIN METHODS **/
	//Called from ContactBEFORE trigger to update any changed fields
	public void updateSubscriptionsfromTrigger (map<id, Contact> newCon, map <id, Contact> oldCon) {
		//generate all of the maps of subscription fields for updates
		createMatchingMaps();
    	for (Contact con : newCon.values()) {
    		//update contact values
    		updateContact(con, oldCon.get(con.Id));
    	}
    }
    
    //Called from ContactBEFORE trigger in the case of an insert
    public void insertSubscriptionsfromTrigger (List<Contact> newCon) {
    	//generate all of the maps of subscription fields for updates
		createMatchingMaps();
		for (Contact con : newCon) {
    		//update contact values
    		updateContact(con);
    	}
    }
    
    public void unsubscribeMembers(List<CampaignMember> members) {
    	//get a list of campaign members who are unsubscribed, and the associated campaign and contact Ids
    	List<CampaignMember> unsubscribers = new List<CampaignMember>();
    	Set<Id> CampaignIds = new Set<Id>();
    	Set<Id> ContactIds = new Set<Id>();    	
    	for (CampaignMember memb : members) {
    		if(memb.sbm__sbx_EmailUnsubscribed__c) {
    			unsubscribers.add(memb);
    			ContactIds.add(memb.ContactId);
    			CampaignIds.add(memb.CampaignId);
    		}
    	}
    	//continue if there are unsubscribed campaign members
    	if (!unsubscribers.isEmpty()) {
    		//first, get a list of all associated campaigns and the field that will unsubscribe contacts from them.
    		List<Campaign> campaignlist = [Select Id, Email_Preference__c, Email_Preference__r.Picklist_Field__c from Campaign where Email_Preference__c <> '' AND Id in :CampaignIds];
    		Map<Id, String> preferenceFields = new Map<Id, String>();
    		for (Campaign camp : campaignlist) {
    			preferenceFields.put(camp.Id, camp.Email_Preference__r.Picklist_Field__c);
    		}
    		if (!preferenceFields.isEmpty()) {
    			//if there are preferences being unsubscribed from, get all contacts and the picklist fields associated with subscription preferences and add them to a map
    			createMatchingMaps();
    			List<Contact> unsubContacts = Database.query(contactQuerywithPicklistFields());
    			Map<Id, Contact> contactsWithSubscriptions = new Map<Id, Contact>();
    			for (Contact con : unsubContacts) {
    				contactsWithSubscriptions.put(con.Id, con);
    			}
    			
    			List<Contact> updateList = new List<Contact>();
    			//go through the campaign members, and update contacts as appropriate
    			for (CampaignMember cm : unsubscribers) {    				
    				Contact con = contactsWithSubscriptions.get(cm.ContactId);
    				String field = preferenceFields.get(cm.CampaignId);
    				//if the unsubscriber contact is not already unsubscribed, update the correct field and add to the update list
    				if (con.get(field) <> 'Unsubscribed') {
    					con.put(field, 'Unsubscribed');
    					updateList.add(con);
    				}    				
    			}
    			//now that all of the contacts that need updating have updated fields, perform the DML operation
    			if (!updateList.isEmpty()) {
    				update updateList;
    			}    			
    		} //end if !preferenceFields.isEmpty   		  		
    	} //end if !unsubscribers.isEmpty	  	    	
    }
	
	
/** HELPER METHODS **/
	//used to create the maps and lists of each subscription's picklist and checkbox fields
	public void createMatchingMaps() {
		List<Subscription_List__c> subscriptions = new List<Subscription_List__c>();
		checkboxMatching = new map<String,List<String>>();
		picklistMatching = new map<String,List<String>>();
		checkboxList = new Set<String>();	
		picklistList = new Set<String>();	
		//pull the full list of subscriptions
		subscriptions = [Select Id, Checkbox_Field__c, Picklist_Field__c, Start_Date_Field__c, End_Date_Field__c from Subscription_List__c];
		//for each subscription, add it to the checkbox and picklist maps
		for (Subscription_List__c sub : subscriptions) {
			checkboxMatching.put(sub.Checkbox_Field__c, new List<String>{sub.Picklist_Field__c, sub.Start_Date_Field__c, sub.End_Date_Field__c});
			picklistMatching.put(sub.Picklist_Field__c, new List<String>{sub.Checkbox_Field__c, sub.Start_Date_Field__c, sub.End_Date_Field__c});					
		}	
		checkboxList = checkboxMatching.keyset();
		picklistList = picklistMatching.keyset();			
	}
	
	//used in an update trigger to update contact fields
	public void updateContact(Contact newcon, Contact oldcon) {
		//check each checkbox field for updates
		for (String checkbox : checkboxList) {
			//check for subscription changes through the checkbox field
			if (newcon.get(checkbox) <> oldcon.get(checkbox)) {
				//if the checkbox field is changed, see if the contact is being subscribed or unsubscribed and update accordingly
				if (newcon.get(checkbox)==true) {
					newcon = checkboxSubscribe(newcon, checkbox);
				}
				if (newcon.get(checkbox)==false) {
					newcon = checkboxUnsubscribe(newcon, checkbox);
				}
			}
		}
		//check each picklist field for updates
		for (String picklist : picklistList) {
			if(newcon.get(picklist) <> oldcon.get(picklist)) {
				//if the picklist field is changed, see if the contact is being subscribed or unsubscribed and update accordingly
				if (newcon.get(picklist)=='Subscribed') {
					newcon = picklistSubscribe(newcon, picklist);
				}
				if (newcon.get(picklist)=='Unsubscribed') {
					newcon = picklistUnsubscribe(newcon, picklist);
				}
			}
		}		
	}
	
	//used in an insert trigger to update contacts as appropriate
	public void updateContact(Contact con) {
		//check each checkbox field for updates
		for (String checkbox : checkboxList) {
			if (con.get(checkbox)==true) {
				con = checkboxSubscribe(con, checkbox);
			}			
		}
		//check each picklist field for updates
		for (String picklist : picklistList) {
			if (con.get(picklist)=='Subscribed') {
				con = picklistSubscribe(con, picklist);
			}
			if (con.get(picklist)=='Unsubscribed') {
				con = picklistUnsubscribe(con, picklist);
			}
		}
	}
	
	//updates the contact as subscribed via the given checkbox
	public Contact checkboxSubscribe(Contact con, String checkbox) {
		String picklistField = checkboxMatching.get(checkbox)[0];
		String startdateField = checkboxMatching.get(checkbox)[1];
		con.put(picklistField, 'Subscribed');
		con.put(startdateField, date.today());		
		return con;
	}
	
	//updates the contact as unsubscribed via the given checkbox
	public Contact checkboxUnsubscribe(Contact con, String checkbox) {
		String picklistField = checkboxMatching.get(checkbox)[0];
		String enddateField = checkboxMatching.get(checkbox)[2];
		con.put(picklistField, 'Unsubscribed');
		con.put(enddateField, date.today());		
		return con;
	}	
	
	//udpates the contact as subscribed via the given picklist
	public Contact picklistSubscribe(Contact con, String picklist) {
		String checkboxField = picklistMatching.get(picklist)[0];
		String startdateField = picklistMatching.get(picklist)[1];
		con.put(checkboxField, true);
		con.put(startdateField, date.today());		
		return con;
	}
	
	//updates the contact as unsubscribed via the given picklist
	public Contact picklistUnsubscribe(Contact con, String picklist) {
		String checkboxField = picklistMatching.get(picklist)[0];
		String enddateField = picklistMatching.get(picklist)[2];
		con.put(checkboxField, false);
		con.put(enddateField, date.today());		
		return con;
	}
	
/** QUERY METHODS **/			
	public String contactQuerywithPicklistFields() {
		String q = 'Select Id';
		for (String f : picklistList) {
			q += ', ' + f;
		}
		q += ' from Contact where Id in :ContactIds';
		return q;	
	}

}