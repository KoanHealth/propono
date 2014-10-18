module Propono
  class SQS
    def self.get_queue(name)
      queue_url = client.create_queue(queue_name: name)[0]
      aws_resource = Aws::SQS::Queue.new(queue_url, client: client)
      Propono::SQS::Queue.new(aws_resource)
    end

    private
    def self.client
      Aws::SQS::Client.new(Propono.aws_options)
    end
  end
end
