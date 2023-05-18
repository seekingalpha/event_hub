class EventHub::Event
  def publish
    EventHub.publish(self)
  end

  def self.event(event = nil)
    @event = event if event
    @event
  end

  def self.version(version = nil)
    @version = version if version
  end

  # def self.field(field)
  #   self.fields ||= Set.new
  #   self.fields << field
  #   attr_accessor(field)
  # end
end
