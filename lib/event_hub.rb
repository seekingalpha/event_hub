# frozen_string_literal: true

require_relative 'event_hub/version'
require_relative 'event_hub/event'
require_relative 'event_hub/handler'
require_relative 'event_hub/message'
require_relative 'event_hub/adapters'

class EventHub
  class NoHandlerDefined < StandardError; end
  class IncorrectVersion < StandardError; end
  class IgnoreMessage < StandardError; end
  class RejectMessage < StandardError; end

  def self.configure(config)
    @config = config
    @instance = nil
  end

  def self.instance
    @instance ||= new(@config)
  end

  def self.subscribe
    instance.adapter.subscribe do |message|
      handler_class = @config.dig(:subscribe, message.event.to_sym, :handler)
      raise NoHandlerDefined unless handler_class

      handler = handler_class.new(message)
      handler.validate!

      handler.call
      message.ack
    rescue IgnoreMessage
      message.ack
    rescue RejectMessage
      message.reject
    rescue Exception => e # rubocop:disable Lint/RescueException
      @config[:on_failure]&.call(e, message)
      message.reject
    end
  end

  def self.publish(event)
    instance.adapter.publish(event)
  end

  def self.adapter
    instance.adapter
  end

  def initialize(config)
    @config = config
    @config[:subscribe] ||= {}
    @config[:subscribe].each_value { |subscription| subscription[:handler] = subscription[:handler].constantize }
  end

  def adapter
    @adapter ||= Adapters.const_get(@config[:adapter].camelize).new(@config)
  end
end
