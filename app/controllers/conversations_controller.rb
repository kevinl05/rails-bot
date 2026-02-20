class ConversationsController < ApplicationController
  PER_PAGE = 15

  def index
    page = [ params.fetch(:page, 1).to_i, 1 ].max
    offset = (page - 1) * PER_PAGE

    records = Conversation.order(updated_at: :desc).offset(offset).limit(PER_PAGE + 1).to_a
    @has_more = records.size > PER_PAGE
    @conversations = records.first(PER_PAGE)
    @next_page = page + 1

    if page > 1
      render partial: "conversations_page", locals: { conversations: @conversations, has_more: @has_more, next_page: @next_page, page: page }
    end
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
