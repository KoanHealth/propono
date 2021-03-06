module Propono

  def self.aws_options
    AwsConfig.new(Propono.config).aws_options
  end
  
  class AwsConfig
    
    def initialize(config)
      @config = config
    end

    def aws_options
      if @config.use_iam_profile
        {
          :use_iam_profile => true,
          :region => @config.queue_region
        }
      else
        {
          :aws_access_key_id => @config.access_key,
          :aws_secret_access_key => @config.secret_key,
          :region => @config.queue_region
        }
      end
    end
  end
end