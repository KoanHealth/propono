require File.expand_path('../../test_helper', __FILE__)

module Propono
  class QueueSetTest < Minitest::Test
    def setup
      super
      @suffix = "-suf"
      Propono.config.queue_suffix = @suffix
    end

    def teardown
      super
      Propono.config.queue_suffix = ""
    end

    def test_main_queue_sets_everything_up_correctly
      topic = mock().tap{|x|x.stubs(name: 'foobar')}
      subscriber = QueueSet.new(topic)
      main_topic_name = subscriber.send(:main_topic_name)
      queue_name = subscriber.send(:main_queue_name)
      queue = mock

      Propono::SQS.expects(:get_queue).with(queue_name).returns(queue)
      topic.expects(:subscribe).with(queue)
      queue.expects(:set_policy).with(topic)

      assert_equal queue, subscriber.send(:main_queue)
    end

    def test_slow_queue_sets_everything_up_correctly
      topic = mock().tap{|x|x.stubs(name: 'foobar')}
      subscriber = QueueSet.new(topic)
      slow_topic_name = subscriber.send(:slow_topic_name)
      slow_queue_name = subscriber.send(:slow_queue_name)
      slow_topic = mock
      slow_queue = mock

      Propono::SNS.expects(:get_topic).with(slow_topic_name).returns(slow_topic)
      Propono::SQS.expects(:get_queue).with(slow_queue_name).returns(slow_queue)
      slow_topic.expects(:subscribe).with(slow_queue)
      slow_queue.expects(:set_policy).with(slow_topic)
      assert_equal slow_queue, subscriber.send(:slow_queue)
    end

    def test_failed_queue_sets_everything_up_correctly
      topic = mock().tap{|x|x.stubs(name: 'foobar')}
      subscriber = QueueSet.new(topic)
      queue_name = subscriber.send(:failed_queue_name)
      queue = mock
      Propono::SQS.expects(:get_queue).with(queue_name).returns(queue)
      assert_equal queue, subscriber.send(:failed_queue)
    end

    def test_corrupt_queue_sets_everything_up_correctly
      topic = mock().tap{|x|x.stubs(name: 'foobar')}
      subscriber = QueueSet.new(topic)
      queue_name = subscriber.send(:corrupt_queue_name)
      queue = mock
      Propono::SQS.expects(:get_queue).with(queue_name).returns(queue)
      assert_equal queue, subscriber.send(:corrupt_queue)
    end

    def test_queue_name
      application_name = "The Best Thing"
      suffix = "Badass"
      topic_name = "foobar"
      topic = mock().tap{|x|x.stubs(name: topic_name)}

      Propono.config.application_name = application_name
      Propono.config.queue_suffix = suffix
      subscriber = QueueSet.new(topic)
      expected = "#{application_name.tr(" ", "_")}-#{topic_name}#{suffix}"
      actual = subscriber.send(:main_queue_name)
      assert_equal expected, actual
    end

    def test_slow_queue_name
      application_name = "The Best Thing"
      suffix = "Badass"
      topic_name = "foobar"
      topic = mock().tap{|x|x.stubs(name: topic_name)}

      Propono.config.application_name = application_name
      Propono.config.queue_suffix = suffix
      subscriber = QueueSet.new(topic)
      expected = "#{application_name.tr(" ", "_")}-#{topic_name}#{suffix}-slow"
      actual = subscriber.send(:slow_queue_name)
      assert_equal expected, actual
    end

    def test_main_topic_name
      suffix = "Badass"
      topic_name = "foobar"
      topic = mock().tap{|x|x.stubs(name: topic_name)}

      Propono.config.queue_suffix = suffix
      subscriber = QueueSet.new(topic)
      expected = "#{topic_name}#{suffix}"
      actual = subscriber.send(:main_topic_name)
      assert_equal expected, actual
    end

    def test_slow_topic_name
      suffix = "Badass"
      topic_name = "foobar"
      topic = mock().tap{|x|x.stubs(name: topic_name)}

      Propono.config.queue_suffix = suffix
      subscriber = QueueSet.new(topic)
      expected = "#{topic_name}#{suffix}-slow"
      actual = subscriber.send(:slow_topic_name)
      assert_equal expected, actual
    end
  end
end
