import { buildPortalArticleURL, buildPortalURL } from '../portalHelper';

describe('PortalHelper', () => {
  describe('buildPortalURL', () => {
    it('returns the correct url', () => {
      window.salesmanConfig = {
        hostURL: 'https://salesman.effiai.pro',
        helpCenterURL: 'https://help.salesman.effiai.pro',
      };
      expect(buildPortalURL('handbook')).toEqual(
        'https://help.salesman.effiai.pro/hc/handbook'
      );
      window.salesmanConfig = {};
    });
  });

  describe('buildPortalArticleURL', () => {
    it('returns the correct url', () => {
      window.salesmanConfig = {
        hostURL: 'https://salesman.effiai.pro',
        helpCenterURL: 'https://help.salesman.effiai.pro',
      };
      expect(
        buildPortalArticleURL('handbook', 'culture', 'fr', 'article-slug')
      ).toEqual(
        'https://help.salesman.effiai.pro/hc/handbook/articles/article-slug'
      );
      window.salesmanConfig = {};
    });
  });
});
