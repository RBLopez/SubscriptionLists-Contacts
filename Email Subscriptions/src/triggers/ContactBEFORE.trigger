/*
	Created by Rosalind Lopez
	1.0 (2014)
	triggers email subscription updates
*/

trigger ContactBEFORE on Contact (before insert, before update) {

	Subscriptions subs = new Subscriptions();
	if (Trigger.isInsert) {
		subs.insertSubscriptionsfromTrigger(trigger.new);
	}
	if (Trigger.isUpdate) {
		subs.updateSubscriptionsfromTrigger(trigger.newMap, trigger.oldMap);
	}
	

}