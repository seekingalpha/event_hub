# frozen_string_literal: true

class EventHub::Adapters::Test::Message < EventHub::Message
  def initialize(body, queue, attributes = {})
    @body = body
    @attributes = attributes
    @queue = queue
  end

  attr_reader :attributes, :body

  def event
    @attributes[:event]
  end

  def version
    @attributes[:version]
  end

  def ack
    @ack = true
    @queue.delete(self)
  end

  def ack?
    !!@ack
  end
end
