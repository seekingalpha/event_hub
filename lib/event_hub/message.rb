class EventHub::Message
  def body
    raise NotImplementedError
  end

  def routing_key
    raise NotImplementedError
  end

  def headers
    raise NotImplementedError
  end

  # Message acknowledgment
  def ack
    raise NotImplementedError
  end
end
