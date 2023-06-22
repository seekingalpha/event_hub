# frozen_string_literal: true

require 'json'

class EventHub::Event
  def initialize(hash = {})
    hash.transform_keys(&:to_s).slice(*self.class.attributes.keys).each do |attr, val|
      public_send("#{attr}=", val)
    end
  end

  def publish
    EventHub.publish(self)
  end

  def body
    self.class.attributes.keys.to_h do |attr|
      [attr, public_send(attr)]
    end.to_json
  end

  def self.event(event = nil)
    @event = event.to_s if event
    @event
  end

  def self.version(version = nil)
    @version = version if version
    @version
  end

  class << self
    attr_reader :attributes

    def attribute(attribute, options = {})
      @attributes ||= {}
      @attributes[attribute.to_s] = options

      attr_accessor(attribute)
    end
  end
end
