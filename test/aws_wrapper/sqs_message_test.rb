require_relative '../test_helper'

module Propono
  class SQSMessageTest < Minitest::Test
    def test_message_content
      msg = SQSMessage.new(aws_message)
      assert_equal message_content, msg.message
    end

    def test_failure_count
      msg = SQSMessage.new(aws_message)
      assert_equal num_failures, msg.num_failures
    end

    def test_delete_proxies
      aws_resource = mock
      msg = SQSMessage.new(aws_resource)

      aws_resource.expects(:delete)
      msg.delete!
    end

    def test_receipt_handle
      receipt_handle = "asdasds"
      aws_message = mock
      aws_message.expects(:receipt_handle).returns(receipt_handle)
      msg = SQSMessage.new(aws_message)
      assert_equal receipt_handle, msg.receipt_handle
    end

    def test_equality
      receipt_handle = "asdasds"
      aws_message_1 = mock.tap{|x|x.stubs(receipt_handle: receipt_handle)}
      aws_message_2 = mock.tap{|x|x.stubs(receipt_handle: receipt_handle)}
      aws_message_3 = mock.tap{|x|x.stubs(receipt_handle: "qwe23424")}

      msg1 = SQSMessage.new(aws_message_1)
      msg2 = SQSMessage.new(aws_message_2)
      msg3 = SQSMessage.new(aws_message_3)
      assert_equal msg1, msg2
      assert_equal msg2, msg1
      refute_equal msg1, msg3
    end

    def aws_message
      id = "asdasdsa"
      body = {
        "Message" => {
          "id" => id,
          "message" => message_content,
          "num_failures" => num_failures
        }.to_json
      }.to_json
      mock().tap{|x|x.stubs(body: body)}
    end

    def message_content
      {foo: 'bar'}
    end

    def num_failures
      8
    end
  end
end
