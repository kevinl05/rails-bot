class MessagesController < ApplicationController
  def create
    @conversation = Conversation.find(params[:conversation_id])
    user_message = params[:message][:content]

    return head(:unprocessable_entity) if user_message.blank?

    chat = RailsBot::Chat.new(@conversation)
    chat.call(user_message)

    head :ok
  rescue StandardError => e
    @conversation.messages.create!(role: "assistant", content: error_message_for(e))
    head :ok
  end

  def feedback
    message = Message.find(params[:id])
    message.update!(feedback: params[:feedback])
    head :ok
  end

  def retry
    @conversation = Conversation.find(params[:conversation_id])
    assistant_message = @conversation.messages.find(params[:id])
    return head(:unprocessable_entity) unless assistant_message.role == "assistant"

    user_message = @conversation.messages.where(role: "user").where("id < ?", assistant_message.id).order(id: :desc).first
    return head(:unprocessable_entity) unless user_message

    assistant_message.destroy!

    chat = RailsBot::Chat.new(@conversation)
    chat.regenerate(user_message.content)

    head :ok
  rescue StandardError => e
    @conversation.messages.create!(role: "assistant", content: error_message_for(e))
    head :ok
  end

end
