class Conversation < ApplicationRecord
  has_many :messages, dependent: :destroy

  before_create :set_default_title

  private

  def set_default_title
    self.title ||= "New Conversation"
  end
end
