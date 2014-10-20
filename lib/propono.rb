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
end
