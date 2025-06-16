import conversations from './sidebarItems/conversations';
import contacts from './sidebarItems/contacts';
import reports from './sidebarItems/reports';
import campaigns from './sidebarItems/campaigns';
import captain from './sidebarItems/captain';
import helpcenter from './sidebarItems/helpcenter';
import settings from './sidebarItems/settings';
import notifications from './sidebarItems/notifications';
import primaryMenu from './sidebarItems/primaryMenu';

export const getSidebarItems = accountId => ({
  primaryMenu: primaryMenu(accountId),
  secondaryMenu: [
    conversations(accountId),
    captain(accountId),
    contacts(accountId),
    reports(accountId),
    campaigns(accountId),
    //helpcenter(accountId),
    settings(accountId),
    notifications(accountId),
  ],
});
