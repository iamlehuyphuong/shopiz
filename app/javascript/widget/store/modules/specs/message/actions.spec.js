import { API } from 'widget/helpers/axios';
import { actions } from '../../message';

const commit = vi.fn();
vi.mock('widget/helpers/axios');

describe('#actions', () => {
  describe('#update', () => {
    it('sends correct actions', async () => {
      const user = {
        messageId: 10,
        submittedValues: [{ name: 'email', value: 'john@acme.inc' }],
      };
      API.patch.mockResolvedValue({
        data: { contact: { pubsub_token: '8npuMUfDgizrwVoqcK1t7FMY' } },
      });
      await actions.update(
        {
          commit,
          getters: {
            getUIFlags: {
              isUpdating: false,
            },
          },
        },
        user
      );
      expect(commit.mock.calls).toEqual([
        ['toggleUpdateStatus', true],
        [
          'conversation/updateMessage',
          {
            id: 10,
            content_attributes: {
              submitted_values: [{ name: 'email', value: 'john@acme.inc' }],
            },
          },
          { root: true },
        ],
        ['toggleUpdateStatus', false],
      ]);
    });

    it('blocks all new action calls when isUpdating', async () => {
      await actions.update(
        {
          commit,
          getters: {
            getUIFlags: {
              isUpdating: true,
            },
          },
        },
        {}
      );

      expect(commit.mock.calls).toEqual([]);
    });
  });
});
