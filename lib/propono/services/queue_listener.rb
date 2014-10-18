module Propono

  class QueueListener

    def self.listen(topic_name, &block)
      new(topic_name, &block).listen
    end

    attr_reader :topic, :block
    def initialize(topic_name, &block)
      @topic = Propono::SNS.get_topic(topic_name)
      @block = block
    end

    def listen
      loop { receive_messages }
    end

    private

    def receive_messages
      receive_main_queue_messages or receive_slow_queue_messages
    end

    def receive_main_queue_messages
      receive_messages_from_queue(topic.main_queue,
                                  max_number_of_messages: 10,
                                  wait_time_seconds: 10)

    end

    def receive_slow_queue_messages
      receive_messages_from_queue(topic.slow_queue,
                                 max_number_of_messages: 1,
                                 wait_time_seconds: nil)

    end

    def receive_messages_from_queue(queue, options)
      messages = queue.receive_messages(options)
      return false if messages.empty?

      messages.each do |message|
        MessageProcessor.process(topic, message, &block)
      end
      true
    end
  end
end
