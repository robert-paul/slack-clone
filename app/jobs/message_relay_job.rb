class MessageRelayJob < ApplicationJob
  queue_as :default

  def perform(message)
    ActionCable.server.broadcast "chatroom:#{message.chatroom.id}", {
      message: MessagesController.render(message),
      chatroom_id: message.chatroom.id
    }
    # Do something later
  end
end
