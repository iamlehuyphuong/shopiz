import { buildPortalArticleURL, buildPortalURL } from '../portalHelper';

describe('PortalHelper', () => {
  describe('buildPortalURL', () => {
    it('returns the correct url', () => {
      window.shopizConfig = {
        hostURL: 'https://www.shopiz.pro',
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
        hostURL: 'https://www.shopiz.pro',
        helpCenterURL: 'https://help.shopiz.pro',
      };
      expect(
        buildPortalArticleURL('handbook', 'culture', 'fr', 'article-slug')
      ).toEqual(
        'https://help.shopiz.pro/hc/handbook/articles/article-slug'
      );
      window.shopizConfig = {};
    });

    it('returns the correct url with custom domain', () => {
      window.shopizConfig = {
        hostURL: 'https://app.shopiz.pro',
        helpCenterURL: 'https://help.shopiz.pro',
      };
      expect(
        buildPortalArticleURL(
          'handbook',
          'culture',
          'fr',
          'article-slug',
          'custom-domain.dev'
        )
      ).toEqual('https://custom-domain.dev/hc/handbook/articles/article-slug');
    });

    it('handles https in custom domain correctly', () => {
      window.shopizConfig = {
        hostURL: 'https://app.shopiz.pro',
        helpCenterURL: 'https://help.shopiz.pro',
      };
      expect(
        buildPortalArticleURL(
          'handbook',
          'culture',
          'fr',
          'article-slug',
          'https://custom-domain.dev'
        )
      ).toEqual('https://custom-domain.dev/hc/handbook/articles/article-slug');
    });

    it('uses hostURL when helpCenterURL is not available', () => {
      window.shopizConfig = {
        hostURL: 'https://app.shopiz.pro',
        helpCenterURL: '',
      };
      expect(
        buildPortalArticleURL('handbook', 'culture', 'fr', 'article-slug')
      ).toEqual('https://app.shopiz.pro/hc/handbook/articles/article-slug');
    });
  });
});
