# frozen_string_literal: true

module Hws
  module PaymentOperationsDemo
    class Users # :nodoc:
      def create(name, description, tags)
        Hws::Stores.create_owner(name: name, description: description, tags: tags)
      end

      def fetch(owner_id)
        Hws::Stores.get_owner(owner_id)
      end

      def update(owner_id, name: nil, description: nil, tags: {})
        Hws::Stores.update_owner(owner_id, name, description, tags)
      end

      def delete(owner_id)
        Hws::Stores.delete(owner_id)
      end
    end
  end
end
