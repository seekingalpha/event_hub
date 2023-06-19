# frozen_string_literal: true

require 'bunny'

class EventHub::Adapters::Bunny
  def initialize(config)
    @config = config
  end

  def subscribe(&block)
    channel.prefetch(1)
    queue.subscribe(block: true, manual_ack: true) do |delivery_info, properties, body|
      message = Message.new(delivery_info, properties, body, channel)
      block.call(message)
    end
  end

  def publish(event)
    exchange.publish(
      event.body,
      routing_key: event.class.event,
      persistent: true,
      event: event.class.event,
      version: event.class.version
    )
  end

  def setup_bindings
    @config.subscribe.each_key do |routing_key|
      queue.bind(exchange, routing_key: routing_key)
    end
  end

  def channel
    @channel ||= connection.create_channel
  end

  private

  def exchange
    @exchange ||= channel.direct(@config[:exchange])
  end

  def queue
    @queue ||= channel.queue(@config[:queue], durable: true)
  end

  def connection
    return @connection if defined?(@connection)

    @connection = ::Bunny.new # TODO: config
    @connection.start
    @connection
  end
end
