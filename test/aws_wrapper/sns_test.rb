require File.expand_path('../../test_helper', __FILE__)

module Propono
  class SNSTest < Minitest::Test

    def setup
      super
      class << Propono::SNS
        alias_method :new_get_topic, :get_topic
        alias_method :get_topic, :original_get_topic
      end
    end

    def teardown
      super
      class << Propono::SNS
        alias_method :original_get_queue, :get_topic
        alias_method :get_topic, :new_get_topic
      end
    end

    def test_get_topic_creates_a_topic
      arn = "my_arn"
      name = "my_topic"

      client = mock
      client.expects(:create_topic).with(name: name).returns([arn])
      Propono::SNS.expects(:client).at_least_once.returns(client)

      topic = Propono::SNS.get_topic(name)
      assert_equal arn, topic.arn
    end

    def test_create_topic_should_propogate_exception_on_topic_creation_error
      client = mock
      client.stubs(:create_topic).raises(RuntimeError)
      Propono::SNS.stubs(client: client)

      assert_raises(RuntimeError) do
        Propono::SNS.get_topic("foobar")
      end
    end
  end
end
