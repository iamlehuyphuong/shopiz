import { buildPortalArticleURL, buildPortalURL } from '../portalHelper';

describe('PortalHelper', () => {
  describe('buildPortalURL', () => {
    it('returns the correct url', () => {
      window.shopizConfig = {
        hostURL: 'https://shopiz.pro',
        helpCenterURL: 'https://help.shopiz.pro',
      };
      expect(buildPortalURL('handbook')).toEqual(
        'https://help.shopiz.pro/hc/handbook'
      );
      window.shopizConfig = {};
    });
  });

  describe('buildPortalArticleURL', () => {
    it('returns the correct url', () => {
      window.shopizConfig = {
        hostURL: 'https://shopiz.pro',
        helpCenterURL: 'https://help.shopiz.pro',
      };
      expect(
        buildPortalArticleURL('handbook', 'culture', 'fr', 'article-slug')
      ).toEqual(
        'https://help.shopiz.pro/hc/handbook/articles/article-slug'
      );
      window.shopizConfig = {};
    });
  });
});
