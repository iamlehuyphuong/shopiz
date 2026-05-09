class DeleteObjectJob < ApplicationJob
  queue_as :low

  BATCH_SIZE = 5_000

  rescue_from(StandardError) do |exception|
    object = arguments.first
    if object.is_a?(Inbox)
      $alfred.with { |conn| conn.srem("deleted_inboxes_#{object.account_id}", object.id) }
    end
    raise exception
  end

  def perform(object, user = nil, ip = nil)
    # Pre-purge heavy associations for large objects to avoid
    # timeouts & race conditions due to destroy_async fan-out.
    purge_heavy_associations(object)
    object.destroy!
    process_post_deletion_tasks(object, user, ip)
  end

  def process_post_deletion_tasks(object, user, ip); end

  private

  def heavy_associations
    {
      Account => %i[conversations contacts inboxes reporting_events],
      Inbox => %i[conversations contact_inboxes contact_optins reporting_events]
    }.freeze
  end

  def purge_heavy_associations(object)
    klass = heavy_associations.keys.find { |k| object.is_a?(k) }
    return unless klass

    heavy_associations[klass].each do |assoc|
      next unless object.respond_to?(assoc)

      batch_destroy(object.public_send(assoc))
    end
  end

  def batch_destroy(relation)
    relation.in_batches(of: BATCH_SIZE, &:destroy_all)
  end
end

DeleteObjectJob.prepend_mod_with('DeleteObjectJob')
