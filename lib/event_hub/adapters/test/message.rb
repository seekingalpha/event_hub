class EventHub::Adapters::Test::Message < EventHub::Message
  def initialize(event, queue)
    @event = event
    @queue = queue
  end

  def attributes
    {}
  end

  def body
    @event.body
  end

  def event
    @event.class.event
  end

  def version
    @event.class.version
  end

  def ack
    @ack = true
    @queue.delete(self)
  end

  def ack?
    !!@ack
  end
end
