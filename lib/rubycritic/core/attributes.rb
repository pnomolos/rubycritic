# frozen_string_literal: true

module RubyCritic
  # Lightweight replacement for the subset of Virtus used by RubyCritic.
  # Provides an `attribute` class macro that registers attributes (with
  # optional type coercion and default value), generates reader/writer
  # methods, and an initializer accepting a hash of attribute values.
  module Attributes
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Class-level macros and attribute registry.
    module ClassMethods
      def attributes
        @attributes ||=
          if superclass.respond_to?(:attributes)
            superclass.attributes.dup
          else
            {}
          end
      end

      def attribute(name, type = nil, default: nil)
        attributes[name] = { type: type, default: default }

        define_method(name) { instance_variable_get("@#{name}") }
        define_method("#{name}=") do |value|
          instance_variable_set("@#{name}", self.class.coerce(type, value))
        end
      end

      def coerce(type, value)
        return value if value.nil? || type.nil?

        case type.name
        when 'Float'   then Float(value)
        when 'Integer' then Integer(value)
        when 'Symbol'  then value.to_sym
        when 'Array'   then Array(value)
        else value
        end
      end
    end

    def initialize(attributes = {})
      self.class.attributes.each do |name, definition|
        if attributes.key?(name)
          public_send("#{name}=", attributes[name])
        else
          instance_variable_set("@#{name}", default_for(definition))
        end
      end
    end

    private

    def default_for(definition)
      default = definition[:default]
      case default
      when Array, Hash then default.dup
      else default
      end
    end
  end
end
