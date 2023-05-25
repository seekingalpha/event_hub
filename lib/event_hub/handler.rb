class EventHub::Handler
  attr_reader :message

  def initialize(message)
    @message = message
  end
end
