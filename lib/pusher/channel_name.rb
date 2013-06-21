module Pusher
  module Rails
    class ChannelName
      attr_reader :id, :channel_name, :channel_type

      def initialize(options)
        @channel_type = options[:channel_type]
        @channel_name = options[:name]
        @id = options[:id]
      end

      def to_s
        name = prefix
        name += "_#{id}" if has_id?
        name
      end

      def prefix
        unless @prefix
          @prefix = channel_name
          if channel_type
            @prefix = "#{channel_type}-#{@prefix}"
          end
        end
        @prefix
      end

      private
        def has_id?
          id != nil
        end
    end
  end
end
