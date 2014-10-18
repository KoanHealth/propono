module Propono
  class CorruptSNSMessageError < ProponoError
    attr_reader :message
    def initialize(message)
      @message = message
    end
  end

  class SQSMessage
    attr_reader :aws_resource
    def initialize(aws_resource)
      @aws_resource = aws_resource
    end

    def delete!
      aws_resource.delete
    end

    def receipt_handle
      aws_resource.receipt_handle
    end

    def message
      context[:message]
    end

    def num_failures
      context[:num_failures] || 0
    end

    def context
      @context ||= JSON.parse(parsed["Message"]).symbolize_keys
    rescue
      Propono.config.logger.error "Error parsing message, moving to corrupt queue", $!, $!.backtrace
      raise Propono::CorruptSNSMessageError.new(self)
    end

    def to_json_with_exception(exception)
      message = parsed.dup
      message['Message'] = {
        id: context[:id],
        message: message,
        last_context: context,
        num_failures: num_failures + 1,
        last_exception_message: exception.message,
        last_exception_stack_trace: exception.backtrace,
        last_exception_time: Time.now
      }.to_json
      JSON.pretty_generate(message)
    end

    def ==(other)
      return false unless other.is_a?(SQSMessage)
      receipt_handle == other.receipt_handle
    end

    private
    def parsed
      @parsed ||= JSON.parse(aws_resource.body)
    end
  end
end
