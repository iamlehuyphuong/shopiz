module ZaloPersonal
  class SyncLabelsJob < ApplicationJob
    queue_as :low

    def perform(inbox)
      ZaloPersonal::SyncLabelsService.new(inbox).perform
    end
  end
end
