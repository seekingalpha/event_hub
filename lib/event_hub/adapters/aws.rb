require 'aws-sdk-sns'
require 'aws-sdk-sqs'

class EventHub::Adapters::Aws
  def initialize(config)
    @config = config
  end

  def subscribe(&block)
    loop do
      receive_message_result = sqs.receive_message({
        queue_url: @config[:queue],
        message_attribute_names: ["All"], # Receive all custom attributes.
        max_number_of_messages: 10, # Receive at most one message.
        wait_time_seconds: 15 # Do not wait to check for the message.
      })

      # Display information about the message.
      # Display the message's body and each custom attribute value.
      receive_message_result.messages.each do |aws_msg|
        message = Message.new(self, aws_msg)
        block.call(message)
      end
    end
  end

  def publish(message, routing_key:)
    topic.publish({
      message: message,
      message_attributes: {event: {data_type: 'String', string_value: routing_key.to_s}},
      message_group_id: 'message_group_id', # TODO: read why it's needed
      message_deduplication_id: SecureRandom.uuid # TODO: read why it's needed
    })
  end

  def setup_bindings
    # @config.subscribe.each_key do |routing_key|
    #   queue.bind(exchange, routing_key: routing_key)
    # end
  end

  def delete_message(receipt_handle)
    sqs.delete_message(
      queue_url: @config[:queue],
      receipt_handle: receipt_handle
    )
  end

  private

  def topic
    @topic ||= sns.topic(@config[:exchange])
  end

  def sns
    @sns ||= Aws::SNS::Resource.new(region: 'us-west-2')
  end

  def sqs
    @sns ||= Aws::SQS::Client.new(region: 'us-west-2')
  end

  # def exchange
  #   # @exchange ||= channel.direct(@config[:exchange])
  # end
  #
  # def queue
  #   @queue ||= channel.queue(@config[:queue], durable: true)
  # end
  #
  # def connection
  #   return @connection if defined?(@connection)
  #
  #   @connection = ::Bunny.new # TODO: config
  #   @connection.start
  #   @connection
  # end
end
