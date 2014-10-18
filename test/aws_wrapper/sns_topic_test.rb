require File.expand_path('../../test_helper', __FILE__)

module Propono
  class SNSTopicTest < Minitest::Test

    def test_returns_arn
      arn = "my_arn"
      aws_object = mock(arn: arn)
      topic = SNS::Topic.new(aws_object)
      assert_equal arn, topic.arn
    end

    def test_returns_name
      name = "my_name"
      aws_object = mock(arn: "Foobar:#{name}")
      topic = SNS::Topic.new(aws_object)
      assert_equal name, topic.name
    end

    def test_publish_proxies_correctly
      message = "The brown fox or something"
      aws_object = mock
      aws_object.expects(:publish).with(message: message)
      topic = SNS::Topic.new(aws_object)
      topic.publish(message)
    end

    def test_subscribe_proxies_correctly
      queue_arn = "my_arn"
      queue = mock(arn: queue_arn)
      aws_object = mock
      aws_object.expects(:subscribe).with(
        protocol: 'sqs',
        endpoint: queue_arn
      )
      topic = SNS::Topic.new(aws_object)
      topic.subscribe(queue)
    end

    def test_subscribe_via_http_proxies_correctly
      endpoint = "http://some.endpoint.com"
      aws_object = mock
      aws_object.expects(:subscribe).with(
        protocol: 'http',
        endpoint: endpoint
      )
      topic = SNS::Topic.new(aws_object)
      topic.subscribe_via_http(endpoint)
    end
  end
end
