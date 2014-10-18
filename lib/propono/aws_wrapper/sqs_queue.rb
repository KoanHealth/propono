require 'aws-sdk-core'

module Propono
  class SQS
    class Queue
      attr_reader :aws_resource
      def initialize(aws_resource)
        @aws_resource = aws_resource
      end

      def arn
        aws_resource.attributes["QueueArn"]
      end

      def url
        aws_resource.url
      end

      def publish(message)
        aws_resource.send_message(message_body: message)
      end

      def receive_messages(options = {})
        opts = {
          max_number_of_messages: options.fetch(:max_number_of_messages, 10),
          wait_time_seconds: options.fetch(:wait_time_seconds, 10)
        }
        messages = aws_resource.receive_messages(opts).map do |msg|
          SQSMessage.new(msg)
        end
      rescue Aws::SNS::Errors::InvalidClientTokenId => e
        Propono.config.logger.error "Forbidden error caught and re-raised. #{queue}"
        Propono.config.logger.error e
        raise e
      rescue => e
        Propono.config.logger.error "Unexpected error reading from queue #{url}"
        Propono.config.logger.error e
        Propono.config.logger.error e.backtrace
        raise e
      end

      def set_policy(topic)
        aws_resource.set_attributes(attributes: {
          "Policy" => generate_policy(topic)
        })
      end

      private
      def generate_policy(topic)
        <<-EOS
{
  "Version": "2008-10-17",
  "Id": "#{arn}/SQSDefaultPolicy",
  "Statement": [
    {
      "Sid": "#{arn}-Sid",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "SQS:*",
      "Resource": "#{arn}",
      "Condition": {
        "StringEquals": {
          "aws:SourceArn": "#{topic.arn}"
        }
      }
    }
  ]
}
        EOS
      end
    end
  end
end

