# frozen_string_literal: true

class EventHub
  module Adapters
    class Test
      attr_accessor :queue

      def initialize(config)
        @config = config
        @queue = []
      end

      def subscribe(&block)
        @queue.each do |message|
          block.call(message)
        end
      end

      def publish(event)
        @queue << Message.new(event, @queue)
      end

      def setup_bindings
        true
      end
    end
  end
end
