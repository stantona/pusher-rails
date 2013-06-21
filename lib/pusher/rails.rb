require "pusher/extension/version"

module Pusher
  module Rails
    class UnrecognizedEventException < StandardError; end;

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      class << base
        attr_reader :_channel_name, :_message_formatter
        attr_reader :_channel_name_id, :_valid_events, :_private_channel
        attr_reader :_channel_type
      end
      base.set_defaults
    end

    module ClassMethods
      def channel_name_id id
        @_channel_name_id = id
        create_capture_channel_id_method
      end

      def channel_type type
        assert_valid_channel_type type
        @_channel_type = type
      end

      def set_defaults
        @_private_channel = false
        @_valid_events = []
      end

      def private_channel enable
        @_private_channel = enable
      end

      def channel_name name
        @_channel_name = name
      end

      def message_formatter type
        @_message_formatter = type
      end

      def recognize_events *args
        @_valid_events = [] unless @_valid_events
        @_valid_events.concat(args)
      end

      def has_channel_name_id?
        self._channel_name_id.present?
      end

      def can_handle?(channel_name)
        !!(expression =~ channel_name)
      end

      protected
        def assert_valid_channel_type type
          unless [:presence, :private].include?(type)
            rails "#{type} is not a valid channel type"
          end
        end
        def expression
          @expression ||= ChannelNameRegexp.new(
            name: self._channel_name,
            private: self._private_channel,
            include_id_capture: has_channel_name_id?
          )
        end

        def create_capture_channel_id_method
          define_singleton_method "capture_channel_id" do |channel_name|
            expression.capture_id(channel_name)
          end
        end
    end

    module InstanceMethods
      def publish(event, data)
        assert_recognized_event(event)
        Pusher.trigger(self.channel_name, event, format(data))
      end

      def channel_name
        @channel_name ||= generate_channel_name
      end

      def recognized_events
        @valid_events ||= self.class._valid_events
      end

      def channel_type
        self.class._channel_type
      end

      def requires_id?
        self.class.has_channel_name_id?
      end

      def channel_name_id
        self.send(self.class._channel_name_id)
      end

      protected
        def format(data)
          message_formatter.new(data).format
        end

        def generate_channel_name
          @channel_name ||= ChannelName.new(
            name: self.class._channel_name,
            channel_type: self.channel_type,
            id: self.channel_name_id).to_s
        end

        def generate_id
        end

        def message_formatter
          self.class._message_formatter || ModelFormatter
        end

        def assert_recognized_event(event)
          return if self.recognized_events.empty?
          unless self.recognized_event?(event)
            raise UnrecognizedEventException
          end
        end

        def recognized_event?(event)
          self.recognized_events.include?(event)
        end
    end

    class DefaultSerializer
      attr_reader :model, :options

      def initialize(model, options={})
        @model, @options = model, options
      end

      def as_json
        model.as_json
      end
    end
  end
end
