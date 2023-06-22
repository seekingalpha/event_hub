# EventHub

This library structurizes the application code for inter microservice communication.
Each micro-service has their own queue. All those queues are bind to the single exchange. So all the
micro-services can publish events to that exchange and only the events that are needed will get into
the corresponding micro-service's queue.

## Installation

You don't need to specify this gem directly in your Gemfile. Instead you need to add one of (or many) 
"adapter" gems like `event_hub_aws` for AWS or `event_hub_bunny` for RabbitMQ. This library will be added
as a dependency.

## Configuration

Create a config file where you should specify events you need in this specific app. In the subscribe
section specify events you wanna receive and the handlers.

```yaml
# config/event_hub.yml

development:
  queue: my-micro-service-events
  exchange: event-hub
  adapter: Bunny
  subscribe:
    user_registered:
      handler: Handlers::UserRegistered
```

Then apply this config:

```ruby
# config/initializers/event_hub.rb

config = Rails.application.config_for(:event_hub)

# This block will be called in case of problems during the event handling
config[:on_failure] = lambda do |e, _message|
  raise(e) if Rails.env.test?
  # notify developers about the problem
end

EventHub.configure(config)
```

You need to implement the `event` and `event handler`:

```ruby
# app/event_hub/events/user_registered.rb
class Events::TickerUpserted < EventHub::Event
  event :user_registered
  version '1.1'

  attribute :id
  attribute :email
  attribute :name
end

# app/event_hub/handlers/user_registered.rb
class Handlers::UserRegistered < EventHub::Handler
  version '1.1'
  
  def call
    User.create(event.as_json)
  end

  # this method will be called in case if the received event version isn't eql to the handler version
  def on_incorrect_version
    event_major, event_minor = message.version.split('.')
    handler_major, handler_minor = self.class.version.split('.')

    if event_major != handler_major || event_minor < handler_minor
      # TODO: notify rollbar
      raise IgnoreMessage
    end
  end

  private

  def event
    @event ||= Events::UserRegistered.new(JSON.parse(message.body))
  end
end
```

To bind the exchange to the queue run:

```ruby
EventHub.adapter.setup_bindings
```
You need to run this command each time you change the `subscription` part of the config file.
You can create a migration with `EventHub.adapter.setup_bindings` in your app each time you 
need to update bindings. 

### Listen to events

To receive events from other system you need to run a daemon process that will call blocking method:
```ruby
EventHub.subscribe
```
This method listens for events and call corresponding handlers.

### Event publishing

To publish an event you need to create its instance and call its `publish` method.

```ruby
Events::UserRegistered.new(id: user.id, email: user.email).publish
```

## Event versions

The event routing is done based on the event name. So if you want let's say to add an attribute to the event
you must upgrade its version. We recommend two-level version structure. 

If the event change breaks the contract the published should publish both versions of the event for some time.
For the new event the major part of the version must be changed.
The subscriber should reject the unsuported version and notify the responsible developers. It can be done in
`on_incorrect_version` handler method. So the micro-service's development team will have time to react onto the
problem and update the handler.

If the event change just extends the contract then the minor version should be changed. The subscriber should
notify the development team but still handle the event. 

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/event_hub. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/event_hub/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the EventHub project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/event_hub/blob/master/CODE_OF_CONDUCT.md).
