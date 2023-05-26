class EventHub::Adapters::Test::Message < EventHub::Message
  def initialize(body, attributes = {}, queue)
    @body = body
    @attributes = attributes
    @queue = queue
  end

  def attributes
    @attributes
  end

  def body
    @body
  end

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
