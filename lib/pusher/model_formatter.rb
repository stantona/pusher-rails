module Pusher
  module Rails
    class ModelFormatter
      attr_reader :model, :serializer_class, :serializer_options

      def initialize(data={})
        @model, @serializer_class = data[:model], data.fetch(:serializer, DefaultSerializer)
        extract_other_options(data)
      end

      def format
        serializer.as_json
      end

      def serializer
        @serializer ||= serializer_class.new(model, serializer_options)
      end

      private
        def extract_other_options(data={})
          @serializer_options ||= data.select { |k, v| [:model, :serializer].exclude?(k) }
        end
    end
  end
end
