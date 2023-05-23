class EventHub::Adapters::Test::Message < EventHub::Message
  def initialize(body, routing_key:)
    @body = body
    @routing_key = routing_key
  end

  def attributes
    {}
  end

  def body
    @body
  end

  def event
    @routing_key
  end

  def ack
    @ack = true
  end

  def ack?
    !!@ack
  end
end
