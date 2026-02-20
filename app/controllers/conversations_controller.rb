class ConversationsController < ApplicationController
  def index
    @conversations = Conversation.order(updated_at: :desc)
  end

  def show
    @conversation = Conversation.find(params[:id])
    @messages = @conversation.messages.ordered
  end

  def create
    conversation = Conversation.create!
    redirect_to conversation
  end

  def destroy
    conversation = Conversation.find(params[:id])
    conversation.destroy
    redirect_to conversations_path
  end
end
