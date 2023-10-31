# frozen_string_literal: true

require 'active_support/callbacks'
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
    if !config[:on_failure] || !config[:on_failure].respond_to?(:call) || config[:on_failure].arity != 2
      raise ArgumentError, 'EventHub configuration must have `on_failure` callable options with arity == 2'
    end

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
      handler.handle
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
    @config[:subscribe].each_value { |subscription| subscription[:handler] = Object.const_get(subscription[:handler]) }
  end

  def adapter
    @adapter ||= Adapters.const_get(@config[:adapter]).new(@config)
  end
end
