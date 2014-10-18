# Propono
#
# Propono is a pub/sub gem built on top of Amazon Web Services (AWS). It uses Simple Notification Service (SNS) and Simple Queue Service (SQS) to seamlessly pass messages throughout your infrastructure.
require 'aws-sdk-core'
require 'aws-sdk-resources'

require "propono/version"
require 'propono/propono_error'
require 'propono/logger'
require 'propono/configuration'

require "propono/helpers/hash"

require 'propono/aws_wrapper/aws_config'
require 'propono/aws_wrapper/sns'
require 'propono/aws_wrapper/sns_topic'
require 'propono/aws_wrapper/sqs'
require 'propono/aws_wrapper/sqs_queue'
require "propono/aws_wrapper/sqs_message"
require "propono/aws_wrapper/queue_set"

require "propono/services/message_processor"

require "propono/services/queue_drainer"
require "propono/services/queue_listener"
require "propono/services/publisher"
require "propono/services/udp_listener"
require "propono/services/tcp_listener"

# Propono is a pub/sub gem built on top of Amazon Web Services (AWS).
# It uses Simple Notification Service (SNS) and Simple Queue Service (SQS)
# to seamlessly pass messages throughout your infrastructure.
module Propono

  # Propono configuration settings.
  #
  # Settings should be set in an initializer or using some
  # other method that insures they are set before any
  # Propono code is used. They can be set as followed:
  #
  #   Propono.config.access_key = "my-access-key"
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
  def self.config
    @config ||= Configuration.new
    if block_given?
      yield @config
    else
      @config
    end
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
  def self.publish(topic, message, options = {})
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
  def self.subscribe(topic_name, &message_processor)
    QueueListener.listen(topic_name, &message_processor)
  end

  def self.listen_to_queue(topic, &block)
    Propono.config.logger.info("Propono.listen_to_queue is deprecated and will be removed in 2.1. Please use Propono.subscribe")
    Propono.subscribe(topic, &block)
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
  def self.drain_queue(topic, &message_processor)
    QueueListener.drain(topic, &message_processor)
  end

  # Listens for UDP messages and yields for each.
  #
  # Calling this will enter a queue-listening loop that
  # yields the message_processor for each UDP message received.
  #
  # @param &message_processor The block to yield for each message.
  #   Is called with <tt>|topic, message|</tt>.
  def self.listen_to_udp(&message_processor)
    UdpListener.listen(&message_processor)
  end

  # Listens for TCP messages and yields for each.
  #
  # Calling this will enter a queue-listening loop that
  # yields the message_processor for each UDP message received.
  #
  # @param &message_processor The block to yield for each message.
  #   Is called with <tt>|topic, message|</tt>.
  def self.listen_to_tcp(&message_processor)
    TcpListener.listen(&message_processor)
  end

  # Listens for UDP messages and passes them onto the queue.
  #
  # This method uses #listen_to_udp and #publish to proxy
  # messages from UDP onto the queue.
  def self.proxy_udp
    Propono.listen_to_udp do |topic, message, options = {}|
      Propono.publish(topic, message, options)
    end
  end

  # Listens for TCP messages and passes them onto the queue.
  #
  # This method uses #listen_to_tcp and #publish to proxy
  # messages from TCP onto the queue.
  def self.proxy_tcp
    Propono.listen_to_tcp do |topic, message, options = {}|
      Propono.publish(topic, message, options)
    end
  end
end
