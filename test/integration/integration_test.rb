require File.expand_path('../../test_helper', __FILE__)

module Propono
  class IntegrationTest < Minitest::Test

    def setup
      super
      config_file = YAML.load_file( File.expand_path('../../config.yml', __FILE__))
      Propono.config do |config|
        config.access_key = config_file['access_key']
        config.secret_key = config_file['secret_key']
        config.queue_region = config_file['queue_region']
        config.application_name = config_file['application_name']
        config.udp_host = "localhost"
      end
      class << Propono::SQS
        alias_method :new_get_queue, :get_queue
        alias_method :get_queue, :original_get_queue
      end
      class << Propono::SNS
        alias_method :new_get_topic, :get_topic
        alias_method :get_topic, :original_get_topic
      end
    end

    def teardown
      super
      Propono.config do |config|
        config.access_key = "test-access-key"
        config.secret_key = "test-secret-key"
        config.queue_region = "us-east-1"
        config.application_name = "MyApp"
      end
      class << Propono::SQS
        alias_method :original_get_queue, :get_queue
        alias_method :get_queue, :new_get_queue
      end
      class << Propono::SNS
        alias_method :original_get_topic, :get_topic
        alias_method :get_topic, :new_get_topic
      end
    end

    # Wait a max of 20secs before failing the test
    def wait_for_thread(thread)
      200.times do |x|
        return true unless thread.alive?
        sleep(0.1)
      end
      false
    end
  end
end


