require File.expand_path('../integration_test', __FILE__)

module Propono
  class SnsToSqsTest < IntegrationTest
    def test_the_message_gets_there
      topic_name = "propono-tests-sns-to-sqs-topic-20"
      text = "This is my message #{DateTime.now} #{rand()}"

      errors = []
      message_received = false

      Thread.abort_on_exception = true

      subscribe_thread = Thread.new do
        #p "Subscribing..."
        begin
          Propono.subscribe(topic_name) do |message, context|
            next unless message == text
            message_received = true
            subscribe_thread.terminate
          end
        ensure
          subscribe_thread.terminate
        end
      end

      sleep(5)
      #p "Publishing..."
      Propono.publish(topic_name, text, async: false)

      timer_thread = Thread.new do
        #p "Timing..."
        sleep(20)
        subscribe_thread.terminate
        flunk("No Message found within 20secs")
      end

      #p "Waiting..."
      subscribe_thread.join
    ensure
      Thread.abort_on_exception = false
    end
  end
end

=begin
      flunks = []
      message_received = false

      thread = Thread.new do
        begin
          Propono.subscribe(topic) do |message, context|
            flunks << "Wrong message" unless message == text
            flunks << "Wrong id" unless context[:id] =~ Regexp.new("[a-z0-9]{6}")
            message_received = true
          end
        rescue => e
          flunks << e.message
        ensure
          thread.terminate
        end
      end

      Thread.new do
        sleep(1) while !message_received
        sleep(5) # Make sure all the message deletion clear up in the thread has happened
        thread.terminate
      end

      sleep(1) # Make sure the listener has started

      Propono.publish(topic, text)
      flunks << "Test Timeout" unless wait_for_thread(thread)
      flunk(flunks.join("\n")) unless flunks.empty?
    #ensure
    #  thread.terminate
    end

=end
=begin


    def test_failed_messge_is_transferred_to_failed_channel
      topic = "test-topic"
      text = "This is my message #{DateTime.now} #{rand()}"
      flunks = []
      message_received = false

      Propono.subscribe_by_queue(topic)

      thread = Thread.new do
        begin
          Propono.subscribe(topic) do |message, context|
            raise StandardError.new 'BOOM'
          end
        rescue => e
          flunks << e.message
        ensure
          thread.terminate
        end
      end

      failure_listener = Thread.new do
        begin
          Propono.subscribe(topic, channel: :failed) do |message, context|
            flunks << "Wrong message" unless message == text
            flunks << "Wrong id" unless context[:id] =~ Regexp.new("[a-z0-9]{6}")
            message_received = true
          end
        rescue => e
          flunks << e.message
        ensure
          thread.terminate
        end
      end

      Thread.new do
        sleep(1) while !message_received
        sleep(5) # Make sure all the message deletion clear up in the thread has happened
        thread.terminate
        failure_listener.terminate
      end

      sleep(1) # Make sure the listener has started

      Propono.publish(topic, text)
      flunks << "Test Timeout" unless wait_for_thread(thread)
      flunk(flunks.join("\n")) unless flunks.empty?
    ensure
      thread.terminate
    end


  end
end
=end
