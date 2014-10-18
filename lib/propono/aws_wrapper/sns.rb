module Propono
  class SNS
    def self.get_topic(name)
      arn = client.create_topic(name: name)[0]
      aws_resource = Aws::SNS::Topic.new(arn, client: client)
      Propono::SNS::Topic.new(aws_resource)
    rescue => e
      Propono.config.logger.error "Propono: Failed to create topic #{name}: #{e}"
      raise
    end

    private
    def self.client
      Aws::SNS::Client.new(Propono.aws_options)
    end
  end
end
