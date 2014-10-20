require File.expand_path('../test_helper', __FILE__)

module Propono
  class ConfigurationTest < Minitest::Test

    def test_use_iam_profile_defaults_false
      refute Configuration.new.use_iam_profile
    end

    def test_default_max_retries
      assert_equal 0, Configuration.new.max_retries
    end

    def test_use_iam_profile
      assert_config(:use_iam_profile, true)
    end

    %w{
      access_key 
      secret_key 
      queue_region 
      application_name
      queue_suffix
      udp_host
      udp_port
      tcp_host
      tcp_port
      max_retries
    }.each do |key|
      define_method "test_#{key}" do
        value = "foobar #{rand}"
        config = Configuration.new(key => value)
        assert_equal value, config.send(key)
      end
    end
  end
end
