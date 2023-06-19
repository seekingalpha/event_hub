# frozen_string_literal: true

class EventHub::Adapters::Bunny::Message < EventHub::Message
  def initialize(delivery_info, properties, body, channel)
    @delivery_info = delivery_info
    @properties = properties
    @body = body
    @channel = channel
  end

  def attributes
    @properties
  end

  attr_reader :body

  def event
    @properties[:event]
  end

  def version
    @properties[:version]
  end

  def ack
    @channel.ack(@delivery_info.delivery_tag)
  end

  def reject
    @channel.reject(@delivery_info.delivery_tag)
  end
end
