require File.expand_path('../../test_helper', __FILE__)

module Propono
  class SQSQueueTest < Minitest::Test

    def test_returns_arn
      arn = "my_arn"
      aws_resource = mock(attributes: {"QueueArn" => arn})
      queue = SQS::Queue.new(aws_resource)
      assert_equal arn, queue.arn
    end

    def test_publishes_message
      message = "The cat sat on the mat"
      aws_resource = mock()
      aws_resource.expects(:send_message).with({
        message_body: message
      })
      queue = SQS::Queue.new(aws_resource)
      queue.publish(message)
    end

    def test_receive_messages
      max = 5
      wait = 12
      aws_resource = mock()
      aws_resource.expects(:receive_messages).with({
        max_number_of_messages: max,
        wait_time_seconds: wait
      }).returns([])
      queue = SQS::Queue.new(aws_resource)
      queue.receive_messages({
        max_number_of_messages: max,
        wait_time_seconds: wait
      })
    end

    def test_receive_messages_uses_default_max
      aws_resource = mock()
      aws_resource.expects(:receive_messages).with({
        max_number_of_messages: 10,
        wait_time_seconds: 10
      }).returns([])
      queue = SQS::Queue.new(aws_resource)
      queue.receive_messages
    end

    def test_receive_messages_returns_sns_messages
      aws_resource = mock()
      aws_resource.expects(:receive_messages).returns([mock])
      queue = SQS::Queue.new(aws_resource)
      assert_instance_of SQSMessage, queue.receive_messages.first
    end

    def test_set_policy
      policy = mock
      topic = mock
      aws_resource = mock
      aws_resource.expects(:set_attributes).with(
        attributes: { "Policy" => policy }
      )
      queue = Propono::SQS::Queue.new(aws_resource)
      queue.expects(:generate_policy).with(topic).returns(policy)
      queue.set_policy(topic)
    end

    def test_generate_policy
      queue_arn = "queue-arn"
      topic_arn = "topic-arn"

      aws_resource = mock()
      queue = Propono::SQS::Queue.new(aws_resource)
      queue.stubs(arn: queue_arn)

      policy = <<-EOS
{
  "Version": "2008-10-17",
  "Id": "#{queue_arn}/SQSDefaultPolicy",
  "Statement": [
    {
      "Sid": "#{queue_arn}-Sid",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "SQS:*",
      "Resource": "#{queue_arn}",
      "Condition": {
        "StringEquals": {
          "aws:SourceArn": "#{topic_arn}"
        }
      }
    }
  ]
}
EOS

      topic = mock().tap {|m|m.stubs(arn: topic_arn)}
      assert_equal policy, queue.send(:generate_policy, topic)
    end
  end
end
