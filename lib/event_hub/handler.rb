# frozen_string_literal: true

class EventHub
  class Handler
    include ::ActiveSupport::Callbacks
    define_callbacks :handle

    attr_reader :message

    def handle
      run_callbacks :handle do
        validate!
        call
        @message.ack
      end
    end

    def self.version(version = nil)
      @version = version if version
      @version
    end

    def initialize(message)
      @message = message
    end

    def on_incorrect_version
      raise IncorrectVersion
    end

    def validate!
      on_incorrect_version if @message.version != self.class.version
    end
  end
end
