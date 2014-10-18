require_relative '../test_helper'

module Propono
  class QueueListenerTest < Minitest::Test

    def test_initializer_gets_topic
      topic_name = "foobar"
      topic = mock
      Propono::SNS.expects(:get_topic).with(topic_name).returns(topic)
      listener = QueueListener.new(topic_name)
      assert_equal topic, listener.topic
    end

    def test_messages_are_read_and_proxied_to_message_processor

      message = mock
      main_queue = mock
      main_queue.expects(:receive_messages).with({
        max_number_of_messages: 10,
        wait_time_seconds: 10
      }).returns([message])

      topic = mock(main_queue: main_queue)
      Propono::SNS.expects(:get_topic).returns(topic)

      MessageProcessor.expects(:process).with(topic, message)
      listener = QueueListener.new("foobar")
      listener.stubs(:loop).yields()
      listener.listen
    end

    def test_slow_queue_is_checked_if_main_is_empty
      message = mock
      main_queue = mock
      main_queue.expects(:receive_messages).returns([])

      slow_queue = mock
      slow_queue.expects(:receive_messages).with({
        max_number_of_messages: 1,
        wait_time_seconds: nil
      }).returns([message])

      topic = mock(main_queue: main_queue,
                   slow_queue: slow_queue)
      Propono::SNS.expects(:get_topic).returns(topic)

      MessageProcessor.expects(:process).with(topic, message)
      listener = QueueListener.new("foobar")
      listener.stubs(:loop).yields()
      listener.listen
    end
  end
end
