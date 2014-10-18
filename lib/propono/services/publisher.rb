require 'socket'

module Propono
  class PublisherError < ProponoError
  end

  class Publisher

    def self.publish(topic_name, message, options = {})
      new(topic_name, message, options).publish
    end

    attr_reader :id, :topic_name, :message, :protocol, :async

    def initialize(topic_name, message, options = {})
      raise PublisherError.new("Topic is nil") if topic_name.nil?
      raise PublisherError.new("Message is nil") if message.nil?

      options = options.symbolize_keys

      @id = SecureRandom.hex(3)
      @id = "#{options[:id]}-#{@id}" if options[:id]

      @topic_name = topic_name
      @message = message
      @protocol = options.fetch(:protocol, :sns).to_sym
      @async = options.fetch(:async, true)
    end

    def publish
      Propono.config.logger.info "Propono [#{id}]: Publishing #{message} to #{topic_name} via #{protocol}"
      send("publish_via_#{protocol}")
    end

    private

    def publish_via_sns
      async ? publish_via_sns_asyncronously : publish_via_sns_syncronously
    end

    def publish_via_sns_asyncronously
      Thread.new { publish_via_sns_syncronously }
    end

    def publish_via_sns_syncronously
      topic = Propono::SNS.get_topic(topic_name)
      topic.publish(body.to_json)
    rescue => e
      Propono.config.logger.error "Propono [#{id}]: Failed to send via sns: #{e}"
      raise
    end

    def publish_via_udp
      payload = body.merge(topic: topic_name).to_json
      UDPSocket.new.send(payload, 0, Propono.config.udp_host, Propono.config.udp_port)
    rescue => e
      Propono.config.logger.error "Propono [#{id}]: Failed to send : #{e}"
    end

    def publish_via_tcp
      payload = body.merge(topic: topic_name).to_json

      socket = TCPSocket.new(Propono.config.tcp_host, Propono.config.tcp_port)
      socket.write payload
      socket.close
    rescue => e
      Propono.config.logger.error "Propono [#{id}]: Failed to send : #{e}"
    end

    def body
      {
        id: id,
        message: message
      }
    end
  end
end
