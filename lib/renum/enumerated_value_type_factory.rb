require 'renum/enumerated_value'

module Renum
  module EnumeratedValueTypeFactory
    class << self
      def create nest, type_name, values, &block
        klass = create_class nest, type_name
        create_values klass, values, &block
      end
    
      def create_class nest, type_name
        klass = Class.new EnumeratedValue
        nest.const_set(type_name, klass)
        klass
      end
    
      def create_values klass, values, &block
        setup_for_definition_in_block(klass) if values == :defined_in_block
        klass.class_eval &block if block_given?
        if values == :defined_in_block
          klass.block_defined_values.each do |value_name, init_args|
            value = klass.new(value_name)
            klass.const_set(value_name, value)
            value.init *init_args if init_args.any?
          end
          teardown_from_definition_in_block(klass)
        else
          values.each do |name|
            klass.const_set(name, klass.new(name))
          end
        end
      end
    
      def setup_for_definition_in_block klass
        klass.class_eval do
          def self.block_defined_values
            @block_defined_values ||= []
          end

          def self.method_missing value_name, *init_args
            block_defined_values << [value_name, init_args]
          end
        end
      end
    
      def teardown_from_definition_in_block klass
        class << klass
          remove_method :block_defined_values
          remove_method :method_missing
        end
      end
    end
  end
end