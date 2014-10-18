module Propono

  def self.aws_options
    AWSConfig.new(Propono.config).aws_options
  end

  class AWSConfig

    def initialize(config)
      @config = config
    end

    def aws_options
      config = {
        region: @config.queue_region
      }

      if @config.use_iam_profile
        config[:use_iam_profile] = true
      else
        config[:access_key_id] = @config.access_key
        config[:secret_access_key] = @config.secret_key
      end

      config
    end
  end
end
