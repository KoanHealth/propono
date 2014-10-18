module Propono
  class QueueDrainer

    def self.drain(topic_name)
      new(topic_name).drain
    end

    attr_reader :topic
    def initialize(topic_name)
      @topic = Propono::SNS.get_topic(topic_name)
    end

    def drain
      drain_queue(topic.main_queue)
      drain_queue(topic.slow_queue)
    end

    def drain_queue(queue)
      loop do
        messages = queue.receive_messages
        break if messages.empty?
        messages.each(&:delete!)
      end
    end
  end
end
