require 'aws-sdk-sns'
require 'aws-sdk-sqs'

class EventHub::Adapters::Aws
  def initialize(config)
    @config = config
  end

  def subscribe(&block)
    loop do
      receive_message_result = sqs.receive_message({
        queue_url: @config[:queue_url],
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
    policy = { event: @config[:subscribe].keys }.to_json
    subscription = topic.subscriptions.find { |s| s.attributes['Endpoint'] == @config[:queue_arn] }
    if subscription
      subscription.set_attributes({
        attribute_name: "FilterPolicy",
        attribute_value: policy
      })
    else
      topic.subscribe({
        protocol: 'sqs',
        attributes: {'FilterPolicy' => policy },
        endpoint: @config[:queue_arn]
      })
    end
  end

  def delete_message(receipt_handle)
    sqs.delete_message(
      queue_url: @config[:queue_url],
      receipt_handle: receipt_handle
    )
  end

  def topic
    @topic ||= sns.topic(@config[:exchange_arn])
  end

  def sns
    @sns ||= Aws::SNS::Resource.new(region: 'us-west-2')
  end

  def sqs
    @sns ||= Aws::SQS::Client.new(region: 'us-west-2')
  end
end
