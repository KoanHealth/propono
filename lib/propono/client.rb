# Propono is a pub/sub gem built on top of Amazon Web Services (AWS).
# It uses Simple Notification Service (SNS) and Simple Queue Service (SQS)
# to seamlessly pass messages throughout your infrastructure.
module Propono
  class Client

    # Propono configuration settings.
    #
    # Settings should be passed in as a hash as follows:
    #
    #   Propono::Client.new(access_key: "my-access-key",...)
    #
    # The following settings are allowed:
    #
    # * <tt>:access_key</tt> - The AWS access key
    # * <tt>:secret_key</tt> - The AWS secret key
    # * <tt>:queue_region</tt> - The AWS region
    # * <tt>:application_name</tt> - The name of the application Propono
    #   is included in.
    # * <tt>:udp_host</tt> - If using UDP, the host to send to.
    # * <tt>:udp_port</tt> - If using UDP, the port to send to.
    # * <tt>:logger</tt> - A logger object that responds to puts.
    def initialize(settings)
      @config = Configuration.new(settings)
    end

    # Publishes a new message into the Propono pub/sub network.
    #
    # This requires a topic and a message. By default this pushes
    # out AWS SNS. The method optionally takes a :protocol key in
    # options, which can be set to :udp for non-guaranteed but very
    # fast delivery.
    #
    # @param [String] topic The name of the topic to publish to.
    # @param [String] message The message to post.
    # @param [Hash] options
    #   * protocol: :udp
    def publish(topic, message, options = {})
      suffixed_topic = "#{topic}#{Propono.config.queue_suffix}"
      Publisher.publish(suffixed_topic, message, options)
    end

    # Listens on a queue and yields for each message
    #
    # Calling this will enter a queue-listening loop that
    # yields the message_processor for each messages.
    #
    # This method will automatically create a subscription if
    # one does not exist.
    #
    # @param [String] topic The topic to subscribe to.
    # @param &message_processor The block to yield for each message.
    def subscribe(topic_name, &message_processor)
      QueueListener.listen(topic_name, &message_processor)
    end

    # Listens on a queue and yields for each message
    #
    # Calling this will enter a queue-listening loop that
    # yields the message_processor for each messages.  The
    # loop will end when all messages have been processed.
    #
    # This method will automatically create a subscription if
    # one does not exist.
    #
    # @param [String] topic The topic to subscribe to.
    # @param &message_processor The block to yield for each message.
    def drain_queue(topic, &message_processor)
      QueueListener.drain(topic, &message_processor)
    end

    # Listens for UDP messages and yields for each.
    #
    # Calling this will enter a queue-listening loop that
    # yields the message_processor for each UDP message received.
    #
    # @param &message_processor The block to yield for each message.
    #   Is called with <tt>|topic, message|</tt>.
    def lf.listen_to_udp(&message_processor)
      UdpListener.listen(&message_processor)
    end

    # Listens for TCP messages and yields for each.
    #
    # Calling this will enter a queue-listening loop that
    # yields the message_processor for each UDP message received.
    #
    # @param &message_processor The block to yield for each message.
    #   Is called with <tt>|topic, message|</tt>.
    def listen_to_tcp(&message_processor)
      TcpListener.listen(&message_processor)
    end

    # Listens for UDP messages and passes them onto the queue.
    #
    # This method uses #listen_to_udp and #publish to proxy
    # messages from UDP onto the queue.
    def proxy_udp
      Propono.listen_to_udp do |topic, message, options = {}|
        Propono.publish(topic, message, options)
      end
    end

    # Listens for TCP messages and passes them onto the queue.
    #
    # This method uses #listen_to_tcp and #publish to proxy
    # messages from TCP onto the queue.
    def proxy_tcp
      Propono.listen_to_tcp do |topic, message, options = {}|
        Propono.publish(topic, message, options)
      end
    end
  end
end
