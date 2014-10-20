require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

gem "minitest"
require "minitest/autorun"
require "minitest/pride"
require "minitest/mock"
require "mocha/setup"

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "propono"

class Minitest::Test
  def setup
    super
    #Propono.config do |config|
    #  config.access_key = "test-access-key"
    #  config.secret_key = "test-secret-key"
    #  config.queue_region = "us-east-1"
    #  config.application_name = "MyApp"

    #  config.logger.stubs(:debug)
    #  config.logger.stubs(:info)
    #  config.logger.stubs(:error)
    #end
  end
end

module Propono
  class SNS
    self.singleton_class.send :alias_method, :original_get_topic, :get_topic
    def self.get_topic(name)
      aws_topic = Object.new
      class << aws_topic
        def arn
          "Topic::ARN"
        end

        def attributes
          {
            "DisplayName" => "Foobar"
          }
        end

        def subscribe(params = {})
        end
      end
      Topic.new(aws_topic)
    end
  end

  class SQS
    self.singleton_class.send :alias_method, :original_get_queue, :get_queue
    def self.get_queue(name)
      aws_queue = Object.new
      class << aws_queue
        def arn
          "Queue:ARN"
        end
        def receive_messages(max = 5)
          []
        end
        def set_attributes(params = {})
        end
      end
      Queue.new(aws_queue)
    end
  end
end

=begin
require 'fog'
class Fog::AWS::SNS::Mock
  def create_topic(*args)
    foo = Object.new
    class << foo
      def body
        {"TopicArn" => "FoobarFromTheMock"}
      end
    end
    foo
  end

  def subscribe(topic_arn, arn_or_url, type)
  end
end

class Fog::AWS::SQS::Mock
  def create_queue(*args)
  end
  def set_queue_attributes(*args)
  end
end

Fog::AWS::SQS::Mock::QueueUrl = 'https://meducation.net/foobar'
Fog::AWS::SQS::Mock::QueueArn = 'FoobarArn'
data = {'Attributes' => {"QueueArn" => Fog::AWS::SQS::Mock::QueueArn}}
queues = Fog::AWS::SQS::Mock.data["us-east-1"]["test-access-key"][:queues]
queues[Fog::AWS::SQS::Mock::QueueUrl] = data
=end
