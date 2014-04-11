/*
    Created by Rosalind Lopez
    0.8 (2013)
    Currently, accounts for Cvent registration and/or cancellation
*/

trigger CampaignMemberAFTER on CampaignMember (after update) {
    CampaignMember_Utilities utils = new CampaignMember_Utilities();
    utils.updateFromTrigger(Trigger.newMap, Trigger.oldMap);
    
    Subscriptions subs = new Subscriptions();
    subs.unsubscribeMembers(trigger.new);

}