# frozen_string_literal: true

require_relative "event_hub/version"
require_relative "event_hub/event"
require_relative "event_hub/handler"
require_relative "event_hub/message"
require_relative "event_hub/adapters"

class EventHub
  def self.configure(config)
    @config = config
    @instance = nil
  end

  def self.instance
    @instance ||= new(@config)
  end

  def self.subscribe
    instance.adapter.subscribe do |message|
      @config.dig(:subscribe, message.event.to_sym, :handler).new(message).call
      message.ack
    rescue Exception => e
      @config[:on_failure].call(e, message) if @config[:on_failure]
      message.reject
    end
  end

  def self.publish(event)
    # TODO: add version to headers
    instance.adapter.publish(event.to_json, routing_key: event.class.event)
  end

  def self.adapter
    instance.adapter
  end

  def initialize(config)
    @config = config
    @config[:subscribe] ||= {}
    @config[:subscribe].each_value { |config| config[:handler] = config[:handler].constantize }
  end

  def adapter
    @adapter ||= Adapters.const_get(@config[:adapter].camelize).new(@config)
  end
end
