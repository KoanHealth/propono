require File.expand_path('../../test_helper', __FILE__)

module Propono
  class PublisherTest < Minitest::Test

    def test_initialization
      publisher = Publisher.new('topic', 'message')
      refute publisher.nil?
    end

    def test_self_publish_calls_new
      topic = "topic123"
      message = "message123"
      Publisher.expects(:new).with(topic, message, {}).returns(mock(publish: nil))
      Publisher.publish(topic, message)
    end

    def test_initializer_generates_an_id
      id = "21312421"
      SecureRandom.stubs(:hex).returns(id)
      publisher = Publisher.new(mock,mock)

      assert_equal id, publisher.instance_variable_get(:@id)
    end

    def test_initializer_concats_an_id
      id = "q1w2e3"
      publisher = Publisher.new('x','y', id: id)
      assert publisher.id =~ Regexp.new("^#{id}-[a-z0-9]{6}$")
    end

    def test_self_publish_calls_publish
      Publisher.any_instance.expects(:publish)
      Publisher.publish("topic", "message")
    end

    def test_protocol_should_be_sns_by_default
      publisher = Publisher.new('topic', 'message')
      assert_equal :sns, publisher.protocol
    end

    def test_publish_logs
      publisher = Publisher.new("foo", "bar")
      publisher.instance_variable_set(:@id, 'abc')
      Propono.config.logger.expects(:info).with {|x| x =~ /^Propono \[abc\]: Publishing bar to foo via sns.*/}
      publisher.publish
    end

    def test_publish_proxies_to_sns
      publisher = Publisher.new('topic', 'message')
      publisher.expects(:publish_via_sns)
      publisher.publish
    end

    def test_publish_proxies_to_udp
      publisher = Publisher.new('topic', 'message', protocol: :udp)
      publisher.expects(:publish_via_udp)
      publisher.publish
    end

    def test_publish_via_sns_should_call_sns_on_correct_topic_and_message
      topic_name = "topic123"
      id = "f123"
      message = "message123"

      aws_object = mock
      topic = mock
      Propono::SNS.stubs(get_topic: topic)

      publisher = Publisher.new(topic_name, message)
      publisher.stubs(id: id, async: false)

      topic.expects(:publish).with({id: id, message: message}.to_json)
      publisher.send(:publish_via_sns)
    end

    def test_publish_via_sns_should_accept_a_hash_for_message
      topic_name = "topic123"
      id = "foobar123"
      message = {something: ['some', 123, true]}
      body = {id: id, message: message}

      topic = mock
      Propono::SNS.stubs(get_topic: topic)

      publisher = Publisher.new(topic, message, async: false)
      publisher.stubs(id: id)

      topic.expects(:publish).with(body.to_json)
      publisher.send(:publish_via_sns)
    end

    def test_publish_via_sns_should_return_id_of_the_sns_message
      message_id = "foasdas"

      topic = mock
      topic.stubs(:publish).returns(message_id)
      Propono::SNS.stubs(get_topic: topic)

      publisher = Publisher.new(topic, message, async: false)
      assert_equal message_id, publisher.send(:publish_via_sns)
    end

    def test_publish_via_sns_creates_a_topic
      topic_name = "Malcs_topic_id"
      topic = mock(:publish)
      Propono::SNS.expects(:get_topic).with(topic_name).returns(topic)
      publisher = Publisher.new(topic_name, "Foobar", async: false)
      publisher.send(:publish_via_sns)
    end

    def test_udp_uses_correct_message_host_and_port
      host = "http://meducation.net"
      port = 1234
      Propono.config.udp_host = host
      Propono.config.udp_port = port
      topic_id = "my-fav-topic"

      id = "foobar123"
      message = "cat dog mouse"
      payload = {id: id, message: message, topic: topic_id}.to_json
      UDPSocket.any_instance.expects(:send).with(payload, 0, host, port)

      publisher = Publisher.new(topic_id, message)
      publisher.stubs(id: id)
      publisher.send(:publish_via_udp)
    end

    def test_exception_from_udpsocket_caught_and_logged
      host = "http://meducation.net"
      port = 1234
      Propono.config.udp_host = host
      Propono.config.udp_port = port

      publisher = Publisher.new("topic_id", "message")
      publisher.stubs(id: '123asd')
      Propono.config.logger.expects(:error).with() {|x| x =~ /^Propono \[123asd\]: Failed to send : getaddrinfo:.*/}
      publisher.send(:publish_via_udp)
    end

    def test_publish_should_raise_exception_if_topic_is_nil
      assert_raises(PublisherError, "Topic is nil") do
        Publisher.publish(nil, "foobar")
      end
    end

    def test_tcp_uses_correct_message
      Propono.config.tcp_host = "http://meducation.net"
      Propono.config.tcp_port = 1234
      topic_id = "my-fav-topic"
      id = "qweqw2312"
      message = "foobar"
      payload = {id: id, message: message, topic: topic_id}.to_json

      socket = mock()
      socket.expects(:write).with(payload)
      socket.expects(:close)
      TCPSocket.stubs(new: socket)

      publisher = Publisher.new(topic_id, message)
      publisher.stubs(id: id)
      publisher.send(:publish_via_tcp)
    end

    def test_tcp_uses_correct_message_host_and_port
      host = "http://meducation.net"
      port = 1234
      Propono.config.tcp_host = host
      Propono.config.tcp_port = port
      topic_id = "my-fav-topic"
      message = "foobar"
      TCPSocket.expects(:new).with(host, port)

      publisher = Publisher.new(topic_id, message)
      publisher.send(:publish_via_tcp)
    end

    def test_exception_from_tcpsocket_caught_and_logged
      host = "http://meducation.net"
      port = 1234
      Propono.config.tcp_host = host
      Propono.config.tcp_port = port

      publisher = Publisher.new("topic_id", "message")
      publisher.stubs(id: '123asd')
      Propono.config.logger.expects(:error).with() {|x| x =~ /^Propono \[123asd\]: Failed to send : getaddrinfo:.*/}
      publisher.send(:publish_via_tcp)
    end

    def test_publish_should_raise_exception_if_topic_is_nil
      assert_raises(PublisherError, "Topic is nil") do
        Publisher.publish(nil, "foobar")
      end
    end

    def test_publish_should_raise_exception_if_message_is_nil
      assert_raises(PublisherError, "Message is nil") do
        Publisher.publish("foobar", nil)
      end
    end

    def test_publish_can_be_called_syncronously
      publisher = Publisher.new("topic_id", "message", async: false)
      publisher.expects(:publish_via_sns_syncronously).once
      publisher.expects(:publish_via_sns_asyncronously).never
      publisher.send(:publish_via_sns)
    end

    def test_publish_is_normally_called_asyncronously
      publisher = Publisher.new("topic_id", "message")
      publisher.expects(:publish_via_sns_asyncronously)
      publisher.send(:publish_via_sns)
    end
  end
end
