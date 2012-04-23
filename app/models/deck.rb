class Deck < ActiveRecord::Base
  set_primary_key 'uuid'

  before_create :generate_uuid

  attr_accessible :name, :user_id

  belongs_to :user
  has_many :cards

  def generate_uuid
    self.id = UUIDTools::UUID.random_create.to_s
  end
end
