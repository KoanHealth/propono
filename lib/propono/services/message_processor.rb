module Propono
  class MessageProcessor

    def self.process(topic, message, &block)
      new(topic, message, &block).process
    end

    attr_reader :topic, :message, :block
    def initialize(topic, message, &block)
      @topic = topic
      @message = message
      @block = block
    end

    def process
      block.call(message.message, message.context)
      message.delete!
    rescue CorruptSNSMessageError => e
      handle_corrupt_message(e)
    rescue => e
      handle_failed_message(e)
    end

    private

    def handle_corrupt_message(e)
      Propono.config.logger.error("Message is corrupt. Moving to Corrupt queue.")
      Propono.config.logger.error("#{e.message} #{e.backtrace}")
      topic.corrupt_queue.publish(message.body)
      message.delete!
    end

    def handle_failed_message(e)
      should_retry = message.num_failures < Propono.config.max_retries
      next_queue = should_retry ? topic.main_queue : topic.failed_queue
      Propono.config.logger.error("Failed to handle message. Moving to #{next_queue}.")
      Propono.config.logger.error("#{e.message} #{e.backtrace}")
      next_queue.publish(message.to_json_with_exception(e))
      message.delete!
    end
  end
end

