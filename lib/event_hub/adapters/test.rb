class EventHub::Adapters::Test
  attr_accessor :messages

  def initialize(config)
    @config = config
    @messages = []
  end

  def subscribe(&block)
    @messages.each do |message|
      block.call(message)
      @messages.delete(message)
    end
  end

  def publish(message_body, routing_key:)
    @messages << Message.new(message_body, routing_key: routing_key)
  end

  def setup_bindings
    true
  end
end
