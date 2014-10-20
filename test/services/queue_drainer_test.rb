require_relative '../test_helper'

module Propono
  class QueueDrainerTest < Minitest::Test

    def test_initializer_gets_topic
      topic_name = "foobar"
      topic = mock
      Propono::SNS.expects(:get_topic).with(topic_name).returns(topic)
      drainer = QueueDrainer.new(topic_name)
      assert_equal topic, drainer.topic
    end

    def test_messages_are_read_and_deleted_from_queue
      message = mock
      message.expects(:delete!)

      main_queue = mock
      main_queue.expects(:receive_messages).twice.returns([message], [])

      slow_queue = mock
      slow_queue.expects(:receive_messages).returns([])

      topic = mock(main_queue: main_queue,
                   slow_queue: slow_queue)
      Propono::SNS.expects(:get_topic).returns(topic)

      drainer = QueueDrainer.new("foobar")
      drainer.drain
    end

    # TODO - We need to add this back in but it's now in the initializer
    def test_drain_raises_with_nil_topic
      skip
      drainer = QueueDrainer.new(nil)
      assert_raises ProponoError do
        drainer.drain
      end
    end
  end
end
