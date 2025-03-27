import { buildPortalArticleURL, buildPortalURL } from '../portalHelper';

describe('PortalHelper', () => {
  describe('buildPortalURL', () => {
    it('returns the correct url', () => {
      window.chatwootConfig = {
        hostURL: 'https://salesman.effiai.one',
        helpCenterURL: 'https://help.salesman.effiai.one',
      };
      expect(buildPortalURL('handbook')).toEqual(
        'https://help.salesman.effiai.one/hc/handbook'
      );
      window.chatwootConfig = {};
    });
  });

  describe('buildPortalArticleURL', () => {
    it('returns the correct url', () => {
      window.chatwootConfig = {
        hostURL: 'https://salesman.effiai.one',
        helpCenterURL: 'https://help.salesman.effiai.one',
      };
      expect(
        buildPortalArticleURL('handbook', 'culture', 'fr', 'article-slug')
      ).toEqual(
        'https://help.salesman.effiai.one/hc/handbook/articles/article-slug'
      );
      window.chatwootConfig = {};
    });
  });
});
