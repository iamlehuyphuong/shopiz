class InboxLabelMapping < ApplicationRecord
  belongs_to :inbox
  belongs_to :label

  validates :native_label_id, presence: true, uniqueness: { scope: :inbox_id }
  validates :native_label_name, presence: true
end
