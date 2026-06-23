require 'administrate/field/base'

class OnlineStatusField < Administrate::Field::Base
  def to_s
    data
  end
end
