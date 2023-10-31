# frozen_string_literal: true

class MyHandler < EventHub::Handler
  version '1.1'
  set_callback :handle, :before, :handle_callback

  def call
    self.class.handled_messages << message
  end

  def handle_callback; end

  def on_incorrect_version; end

  class << self
    attr_accessor :handled_messages
  end
  self.handled_messages = []
end

class MyEvent < EventHub::Event
  event :my_event
  version '1.1'

  set_callback :publish, :after, :publish_callback

  attribute :id

  def publish_callback; end
end

class MyEvent2 < EventHub::Event
  event :my_event
  version '1.2'

  attribute :id
end

RSpec.describe EventHub do
  before do
    EventHub.configure(
      adapter: 'Test',
      on_failure: ->(e, _message) { raise(e) },
      subscribe: {
        my_event: { handler: 'MyHandler' }
      }
    )
  end

  it 'has a version number' do
    expect(EventHub::VERSION).not_to be_nil
  end

  it 'publishes and subscribes' do
    event = MyEvent.new(id: 1)
    expect(event).to receive(:publish_callback).once
    expect { event.publish }.to change(EventHub.adapter.queue, :size).by(1)
    message = EventHub.adapter.queue.first
    expect(message.event).to eq(event.class.event)
    expect(message.version).to eq(event.class.version)
    expect(message.body).to eq(event.body)

    expect_any_instance_of(MyHandler).to receive(:handle_callback).once
    expect { EventHub.subscribe }.to change(MyHandler.handled_messages, :size).by(1)
  end

  it 'handles versions' do
    expect_any_instance_of(MyHandler).to receive(:on_incorrect_version)
    MyEvent2.new(id: 1).publish
    EventHub.subscribe
  end

  it 'cannot be initialized without on_failure callback' do
    expect { EventHub.configure({}) }.to raise_exception(ArgumentError)
    expect { EventHub.configure(on_failure: :bla) }.to raise_exception(ArgumentError)
    expect { EventHub.configure(on_failure: -> { :bla }) }.to raise_exception(ArgumentError)
    expect { EventHub.configure(on_failure: ->(_e, _message) { :bla }) }.not_to raise_exception(ArgumentError)
  end
end
