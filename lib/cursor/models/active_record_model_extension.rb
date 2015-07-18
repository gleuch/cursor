
module Cursor
  module ActiveRecordModelExtension
    extend ActiveSupport::Concern

    included do
      self.send(:include, Cursor::ConfigurationMethods)

      # Fetch the values at the specified page edge
      #   Model.page(after: 5)
      eval <<-RUBY
        def self.#{Cursor.config.page_method_name}(options={})
          (options || {}).to_hash.symbolize_keys!

          @_cursor_direction = options.keys.include?(:after) ? :after : :before
          @_current_cursor = options[ @_cursor_direction ]

          on_cursor.in_direction.limit(default_per_page).extending do
            include Cursor::PageScopeMethods
          end
        end
      RUBY

      def self.current_cursor
        @_current_cursor
      end

      def self.cursor_direction
        @_cursor_direction
      end

      def self.on_cursor
        if self.current_cursor.nil?
          where(nil)
        else
          where(["#{self.table_name}.id #{self.cursor_direction == Cursor.config.after_param_name ? '>' : '<'} ?", self.current_cursor])
        end
      end

      def self.in_direction
        reorder("#{self.table_name}.id #{self.cursor_direction == Cursor.config.after_param_name ? 'asc' : 'desc'}")
      end
    end
  end
end
