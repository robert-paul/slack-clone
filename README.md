# Slack-Clone for Sac Ruby Meetup on Action Cable

I was going to have us build the app together from scratch but quickly realized it would take way too long. So here's a functional basic messaging app that we are going to integrate websockets into.

### For people fresh to Ruby on Rails

If you've never used ruby or Ruby on Rails before, http://installrails.com/ has a fantastic guide to get you up and running. 

Then clone the repo to your desktop, open up the project in your favorite text editor, open up the terminal and type `cd desktop/slack-clone-master`. Now just migrate the database with `rails db:migrate` and you're ready to go.

Message me at robert.na.paul@gmail.com if you have questions!

Here's what we did:

# Code for Action Cable demo

## Make our form submit via javascript / AJAX, add remote: true

### app/views/chatrooms/show.html.erb
```
<%= form_for [@chatroom, Message.new], remote: true do |f| %>
        <%= f.text_area :body, rows: 1, class: "form-control", autofocus: true, placeholder: "Message ##{@chatroom.name}" %>
<% end %>
```

----------------------------

## Remove redirect_to in create action in messages controller

### app/controllers/messages_controller.rb

```
def create
  message = @chatroom.messages.new(message_params)
  message.user = current_user
  message.save
```
  ~~redirect_to @chatroom~~
```
end
```

--------------------------

## Make a create.js.erb file in messages to reset form after submitting message

### app/views/messages/create.js.erb
add this code in that file

```
$("#new_message")[0].reset()
```

--------------------------

## Establish who "in general" is allowed to connect to our websockets
## Because using devise, we'll be using their cookie/session system with Warden
## Also will be creating logger tags so we can see in the server logs when Action Cable connections happen.


### app/channels/application_cable/connection.rb

```
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      logger.add_tags "ActionCable", "User #{current_user.id}"
    end

    protected

    def find_verified_user
      if current_user = env['warden'].user
        current_user
      else
        reject_unauthorized_connection
      end
    end

  end
end
```

--------------------------

## Create our channel for our chatrooms in the terminal
### will create chatrooms_channel.rb file and a coffeescript file in app/assets/javascripts/channels/

```
rails g channel Chatrooms
```

--------------------------

## Now we need to tell our chatrooms channel what exactly we want our webocket to listen to
### app/channels/chatrooms_channel.rb

```
class ChatroomsChannel < ApplicationCable::Channel
  def subscribed
    current_user.chatrooms.each do |chatroom|
      stream_from "chatroom:#{chatroom.id}"
    end
  end

  def unsubscribed
    stop_all_streams
  end

end
```

--------------------------

## Now we need to work on injecting those new messages into our browser via websockets.
## Because servers processing these websocket processes could potentially be slow, we can create a job specifically for use with injecting messages via websockets

### app/controllers/messages_controller.rb
add in our job right after message.save in our controller, and pass in that message into the job

```
def create
    message = @chatroom.messages.new(message_params)
    message.user = current_user
    message.save
    MessageRelayJob.perform_later(message)
end
```

--------------------------
## Now actually create that job in the terminal

```
rails g job MessageRelay
```
--------------------------

## Now in the job we are going to pass in that message again and broadcast it out to our chatrooms_channel
### app/jobs/message_relay_job.rb

```
class MessageRelayJob < ApplicationJob
  queue_as :default

  def perform(message)
    ActionCable.server.broadcast "chatroom:#{message.chatroom.id}", {
      message: MessagesController.render(message),
      chatroom_id: message.chatroom.id
    }
  end
end
```

--------------------------

## Now we need to add html data attributes to correctly communicate to our websockets where to inject new messages into our page.
### app/views/chatrooms/show.html.erb

```
<div data-behavior='message' data-chatroom-id='<%= @chatroom.id %>' style="border-top: thin solid lightgrey; padding-top: 8px; padding-bottom: 8px;">
  <% @message.each do |message| %>
      <%= render message %>
  <% end %>
</div>
```

--------------------------

## Now we need to tell our channel subscription what to do when new data passes through
### app/assets/javascripts/channels/chatrooms.coffee

# THIS IS COFFEESCRIPT. YOU GOTTA TAB IT.

```
App.chatrooms = App.cable.subscriptions.create "ChatroomsChannel",
  connected: ->
    # Called when the subscription is ready for use on the server

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    $("[data-behavior='message'][data-chatroom-id='#{data.chatroom_id}']").append(data.message)
    # Called when there's incoming data on the websocket for this channel
```


--------------------------

# FIN
