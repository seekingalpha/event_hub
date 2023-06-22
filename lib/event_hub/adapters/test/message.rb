# frozen_string_literal: true

class EventHub
  module Adapters
    class Test
      class Message < EventHub::Message
        def initialize(event, queue, attributes = {})
          @event = event
          @body = event.body
          @attributes = attributes
          @queue = queue
        end

        attr_reader :attributes, :body

        def event
          @event.class.event
        end

        def version
          @event.class.version
        end

        def ack
          @ack = true
          @queue.delete(self)
        end

        def reject
          @rejected = true
          @queue.delete(self)
        end

        def ack?
          !!@ack
        end

        def rejected?
          !!@rejected
        end
      end
    end
  end
end
