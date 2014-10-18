module Propono
  class SNS
    class Topic
      attr_reader :aws_resource
      def initialize(aws_resource)
        @aws_resource = aws_resource
      end

      def arn
        aws_resource.arn
      end

      def name
        arn.split(":").last
      end

      def main_queue
        @main_queue_url ||= queue_set.main_queue
      end

      def slow_queue
        @slow_queue_url ||= queue_set.slow_queue
      end

      def failed_queue
        @failed_queue_url ||= queue_set.failed_queue
      end

      def corrupt_queue
        @corrupt_queue_url ||= queue_set.corrupt_queue
      end

      def publish(message)
        aws_resource.publish(message: message)
      end

      def subscribe(queue)
        aws_resource.subscribe(
          protocol: 'sqs',
          endpoint: queue.arn
        )
      end

      def subscribe_via_http(endpoint)
        aws_resource.subscribe(
          protocol: 'http',
          endpoint: endpoint
        )
      end

      private
      def queue_set
        @queue_set ||= QueueSet.new(self)
      end
    end
  end
end
