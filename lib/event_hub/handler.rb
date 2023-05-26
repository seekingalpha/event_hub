class EventHub::Handler
  attr_reader :message

  def self.version(version = nil)
    @version = version if version
    @version
  end

  def initialize(message)
    @message = message
  end

  def on_incorrect_version
    raise IncorrectVersion
  end

  def validate!
    on_incorrect_version if @message.version != self.class.version
  end
end
