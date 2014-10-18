require_relative '../test_helper'

module Propono
  class MessageProcessorTest < Minitest::Test

    def test_block_is_called
      count = 0
      block = Proc.new { |msg, context|
        count += 1
        assert_equal message_message, msg
        assert_equal message_context, context
      }
      processor = MessageProcessor.new(nil, sns_message, &block)
      processor.process
      assert_equal 1, count
    end

    def test_message_is_deleted
      processor = MessageProcessor.new(nil, sns_message) {}
      processor.process
    end

    def test_message_is_moved_to_corrupt_queue_if_corrupt
      corrupt_queue = mock
      corrupt_queue.expects(:publish).with(sns_message_body)

      topic = mock
      topic.expects(:corrupt_queue).returns(corrupt_queue)
      processor = MessageProcessor.new(topic, sns_message) { |msg|
        raise CorruptSNSMessageError.new(msg)
      }
      processor.process
    end

    def test_message_is_requeued
      Propono.config.max_retries = 2
      sns_message.stubs(num_failures: 0)
      main_queue = mock
      main_queue.expects(:publish).with(json_with_exception)

      topic = mock
      topic.expects(:main_queue).returns(main_queue)
      processor = MessageProcessor.new(topic, sns_message) { |msg|
        raise RuntimeError
      }
      processor.process
    end

    def test_message_is_moved_to_failed_queue_if_over_threshold
      Propono.config.max_retries = 2
      sns_message.stubs(num_failures: 2)

      failed_queue = mock
      failed_queue.expects(:publish).with(json_with_exception)

      topic = mock
      topic.expects(:failed_queue).returns(failed_queue)
      processor = MessageProcessor.new(topic, sns_message) { |msg|
        raise RuntimeError
      }
      processor.process
    end

    def sns_message
      @sns_message ||= mock(
        message: message_message,
        context: message_context,
        delete!: nil
      ).tap {|msg| msg.stubs(
        body: sns_message_body,
        to_json_with_exception: json_with_exception
      )}
    end

    def sns_message_body
      @sns_message_body ||= mock
    end

    def message_message
      @message_message ||= mock
    end

    def message_context
      @message_context ||= mock
    end

    def json_with_exception
      @json_with_exception ||= mock
    end
  end
end
