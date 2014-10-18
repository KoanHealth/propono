module Propono
  class QueueSet

    attr_reader :topic
    def initialize(topic)
      @topic = topic
    end

    def main_queue
      @main_queue ||= begin
        Propono::SQS.get_queue(main_queue_name).tap do |queue|
          topic.subscribe(queue)
          queue.set_policy(topic)
        end
      end
    end

    def slow_queue
      @slow_queue ||= begin
        Propono::SQS.get_queue(slow_queue_name).tap do |queue|
          topic = Propono::SNS.get_topic(slow_topic_name)
          topic.subscribe(queue)
          queue.set_policy(topic)
        end
      end
    end

    def failed_queue
      @failed_queue ||= Propono::SQS.get_queue(failed_queue_name)
    end

    def corrupt_queue
      @corrupt_queue ||= Propono::SQS.get_queue(corrupt_queue_name)
    end

    def main_queue_name
      "#{Propono.config.application_name.gsub(" ", "_")}-#{main_topic_name}"
    end

    def slow_queue_name
      "#{main_queue_name}-slow"
    end

    def failed_queue_name
      "#{main_queue_name}-failed"
    end

    def corrupt_queue_name
      "#{main_queue_name}-corrupt"
    end

    def main_topic_name
      "#{topic.name}#{Propono.config.queue_suffix}"
    end

    def slow_topic_name
      "#{topic.name}#{Propono.config.queue_suffix}-slow"
    end
  end
end
