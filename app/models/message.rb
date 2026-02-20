class Message < ApplicationRecord
  belongs_to :conversation

  enum :feedback, { thumbs_up: 1, thumbs_down: -1 }

  validates :role, inclusion: { in: %w[user assistant] }
  validates :content, presence: true

  scope :ordered, -> { order(:created_at) }

  after_create_commit -> { broadcast_append_to conversation, target: "messages", partial: "messages/message" }, if: :assistant?

  def assistant?
    role == "assistant"
  end
end
