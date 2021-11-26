# frozen_string_literal: true

module Hws
  module PaymentOperationsDemo
    class TransactionalValueStore # :nodoc:
      attr_accessor :store_id, :transaction_group_id

      def store
        @store ||= Hws::Stores.get_store(@store_id)
        @store
      end

      def initialize(store_id:, transaction_group_id:)
        @store_id = store_id
        @transaction_group_id = transaction_group_id
      end

      def deposit(amount:, tags:, txn_time: Time.now)
        entry = ActiveRecord::Base.transaction do
          Hws::Stores.increment(@store_id, amount)
          tags.key?(:immutable_tags) ? tags[:immutable_tags][:store_id] = store_id : tags[:immutable_tags] = { store_id: store_id }
          Hws::Transactions.add_entry(@transaction_group_id, amount, txn_time, tags)
        end

        entry.id
      end

      def withdraw(amount:, tags:, txn_time: Time.now)
        self.deposit(amount: amount * -1, tags: tags, txn_time: txn_time)
      end

      def balance
        store = Hws::Stores.get_store(@store_id)
        store[:data]
      end

      def update_txn_status(entry_id, status, tags = {})
        entry = Hws::Transactions.get_entry(entry_id)

        return if status == entry['status']

        entry = ActiveRecord::Base.transaction do
          Hws::Transactions.update_entry(@transaction_group_id, entry_id, { status: status }.merge(tags))
          Hws::Stores.increment(@store_id, (entry[:value] * -1)) if entry['status'] != 'FAILED' && status == 'FAILED'

          Hws::Transactions.get_entry(entry_id)
        end
      end

      class << self
        def load(store_id)
          store = Hws::Stores.get_store(store_id)
          tg_id = store[:tags]['ledger_id']
          TransactionalValueStore.new(store_id: store_id, transaction_group_id: tg_id)
        end

        def create(name:, description: nil, store_tags: {}, txn_tags: [])
          ActiveRecord::Base.transaction do
            store_id = Hws::Stores.create_store(
              {
                name: name, description: description, data: 0,
                schema: { type: :number, multipleOf: 0.01 }.with_indifferent_access, tags: store_tags
              }
            )

            transaction_group = Hws::Transactions.create_group(
              "store_ledger_#{store_id}", "value_store_#{description}", %I[status bank_ref_id].concat(txn_tags),
              %I[store_id instrument_id beneficiary remitter txn_time note pymt_type]
            )

            Hws::Stores.update_store(store_id: store_id, tags: { ledger_id: transaction_group.id })

            TransactionalValueStore.new(store_id: store_id, transaction_group_id: transaction_group.id)
          end
        end

        def update_txn_status(entry_id, status, tags = {})
          entry = Hws::Transactions.get_entry(entry_id)

          return if status == entry['status']

          entry = ActiveRecord::Base.transaction do
            Hws::Transactions.update_entry(entry[:transaction_group_id], entry_id, { status: status }.merge(tags))
            if status == 'FAILED'
              store_id = get_immutable_tags_from_entry(entry).try(:[], 'store_id')
              raise 'couldnot find store corresponding to txn entry' if store_id.nil?

              Hws::Stores.increment(store_id, (entry[:value] * -1))
            end

            Hws::Transactions.get_entry(entry_id)
          end
        end

        def get_instrument_for_entry(entry_id)
          entry = Hws::Transactions.get_entry(entry_id)
          instrument_id = get_immutable_tags_from_entry(entry).try(:[], 'instrument_id')
          return if instrument_id.nil?

          Hws::Instruments::Models::Instrument.find_by(id: instrument_id)
        end

        private

        def get_immutable_tags_from_entry(entry)
          entry.try(:[], :tags).try(:[], :immutable_tags)
        end
      end
    end
  end
end
