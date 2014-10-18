require_relative '../test_helper'

module Propono
  class SQSTest < Minitest::Test

    def setup
      super
      class << Propono::SQS
        alias_method :new_get_queue, :get_queue
        alias_method :get_queue, :original_get_queue
      end
    end

    def teardown
      super
      class << Propono::SQS
        alias_method :original_get_queue, :get_queue
        alias_method :get_queue, :new_get_queue
      end
    end

    def test_get_queue_creates_a_queue
      name = "my_queue"
      queue_url = "my_url"

      client = mock
      client.expects(:create_queue).with(queue_name: name).returns([queue_url])
      Propono::SQS.stubs(:client).returns(client)

      queue = Propono::SQS.get_queue(name)
      assert_equal queue_url, queue.url
    end

    def test_should_raise_exception_if_no_queue_returned
      Aws::SQS::Client.any_instance.stubs(:create_queue).raises(RuntimeError)

      assert_raises RuntimeError do
        Propono::SQS.get_queue("Foobar")
      end
    end
  end
end
