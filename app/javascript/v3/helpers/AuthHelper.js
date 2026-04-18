import Cookies from 'js-cookie';
import { isCompanyEmail } from 'company-email-validator';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import { frontendURL } from 'dashboard/helper/URLHelper';
export const hasAuthCookie = () => {
  return !!Cookies.get('cw_d_session_info');
};

const getSSOAccountPath = ({ ssoAccountId, user }) => {
  const { accounts = [], account_id = null } = user || {};
  const ssoAccount = accounts.find(
    account => account.id === Number(ssoAccountId)
  );
  let accountPath = '';
  if (ssoAccount) {
    accountPath = `accounts/${ssoAccountId}`;
  } else if (accounts.length) {
    // If the account id is not found, redirect to the first account
    const accountId = account_id || accounts[0].id;
    accountPath = `accounts/${accountId}`;
  }
  return accountPath;
};

const capitalize = str =>
  str
    .split(/[._-]+/)
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');

const extractDomainName = email => {
  const domain = email.split('@')[1];
  if (!domain) return 'My Store';
  const domainName = domain.split('.')[0];
  return capitalize(domainName);
};

export const getCredentialsFromEmail = email => {
  const [localPart] = email.split('@');
  const namePart = localPart.split('+')[0];
  const isCompany = isCompanyEmail(email);

  return {
    fullName: capitalize(namePart),
    accountName: isCompany ? extractDomainName(email) : 'My Store',
  };
};

export const getLoginRedirectURL = ({
  ssoAccountId,
  ssoConversationId,
  user,
}) => {
  const accountPath = getSSOAccountPath({ ssoAccountId, user });
  if (accountPath) {
    if (ssoConversationId) {
      return frontendURL(`${accountPath}/conversations/${ssoConversationId}`);
    }
    return frontendURL(`${accountPath}/dashboard`);
  }
  return DEFAULT_REDIRECT_URL;
};
