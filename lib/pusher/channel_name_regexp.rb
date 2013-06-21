require 'forwardable'

module Pusher
  module Rails
    class ChannelNameRegexp
      extend Forwardable

      def_delegators :expression, :=~

      attr_reader :channel_name, :include_id_capture

      def initialize(options)
        @channel_name = ChannelName.new options
        @include_id_capture = options.fetch(:include_id_capture, false)
      end

      def capture_id(channel_name)
        return nil unless include_id_capture
        expression.match(channel_name) { |m| return m[1].to_i }
        nil
      end

      def expression
        unless @expression
          regex_str = channel_name.prefix
          if include_id_capture
            regex_str += "_(\\d+)"
          end
          @expression = Regexp.new regex_str
        end
        @expression
      end
    end
  end
end
