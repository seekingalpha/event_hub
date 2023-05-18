# frozen_string_literal: true

require_relative "event_hub/version"
require_relative "event_hub/event"
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
    instance.adapter.subscribe do |delivery_info, properties, body|

      event = delivery_info[:routing_key].to_sym
      handler = @config.dig(:subscribe, event, :handler).new(body: JSON.parse(body)).call
      # event = delivery_info[:routing_key]
      # content_type = properties[:content_type]
      # body
      # TODO: handle exceptions
      res = instance.adapter.channel.ack(delivery_info.delivery_tag)
      puts res
    end
  end

  def self.publish(event)
    # TODO: add version to headers
    instance.adapter.publish(event.to_json, routing_key: event.class.event)
  end

  def initialize(config)
    @config = config
    @config[:subscribe] ||= {}
    @config[:subscribe].each_value { |config| config[:handler] = config[:handler].constantize }
  end

  def adapter
    @adapter ||= Adapters::Bunny.new(@config)
  end
end
