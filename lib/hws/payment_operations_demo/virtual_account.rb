# frozen_string_literal: true

module Hws::PaymentOperationsDemo # :nodoc:
  class VirtualAccount # :nodoc:
    attr_accessor :store, :instrument

    HYPTO_VA_CONNECTOR_ID = 'Hws::Connectors::Hypto::VirtualAccount'
    HYPTO_PAYOUT_CONNECTOR_ID = 'Hws::Connectors::Hypto::Payout'

    def as_json
      {
        name: @store.store[:name],
        description: @store.store[:description],
        va_info: {
          id: self.instrument.value['id'],
          account_number: self.instrument.value['va_num'],
          account_ifsc: self.instrument.value['account_ifsc']
        }
      }
    end

    # Hws::PaymentOperationsDemo::VirtualAccount.create(name: 'name')
    def self.create(name:, description: nil)
      va_instr_config = Hws::Instruments::Models::InstrumentConfig.find_by(connector_id: HYPTO_VA_CONNECTOR_ID)
      if va_instr_config.nil?
        Rails.logger.error "cannot find instrument_config for connector_id #{HYPTO_VA_CONNECTOR_ID}"
        raise Hws::PaymentOperationsDemo::Exceptions::EntityNotFoundError, "InstrumentConfig [#{HYPTO_VA_CONNECTOR_ID}] not found"
      end
      instrument, store = ActiveRecord::Base.transaction do
        instrument = va_instr_config.create_instrument
        Rails.logger.info "Instrument [#{instrument.id}] created"

        store = TransactionalValueStore.create(name: name, description: description)
        Rails.logger.info "Store [#{store.store_id}] created"

        Hws::PaymentOperationsDemo::Models::InstrumentResourceStore.create(
          store_id: store.store_id, instrument_id: instrument.id
        )
        Rails.logger.info 'InstrumentResourceStore entry created'

        [instrument, store]
      end

      VirtualAccount.new(instrument, store)
    end

    # Hws::PaymentOperationsDemo::VirtualAccount.of('HYPTOUAT70809083139849')
    def self.of(va_num)
      instrument = Hws::Instruments::Models::Instrument.find_by(external_identifier: va_num)
      raise Hws::PaymentOperationsDemo::Exceptions::EntityNotFoundError, 'Instrument not found' if instrument.nil?

      store = TransactionalValueStore.load(
        Hws::PaymentOperationsDemo::Models::InstrumentResourceStore
          .find_by(instrument_id: instrument.id).store_id
      )

      VirtualAccount.new(instrument, store)
    end

    def initialize(instrument, store)
      @instrument = instrument
      @store = store
    end

    def payout_instrument
      return @payout_instrument if @payout_instrument.present?

      Rails.logger.warn 'Payout instrument not configured. Trying to auto configure...'
      # @payout_instrument ||= instrument
      payout_i_c = Hws::Instruments::Models::InstrumentConfig.where(connector_id: HYPTO_PAYOUT_CONNECTOR_ID, connector_credentials: @instrument.instrument_config.connector_credentials).first
      if payout_i_c.nil?
        Rails.logger.error 'Cannot find a matching instrument config. Unable to auto configure'
        raise 'Cannot find a matching instrument config. Unable to auto configure'
      end
      payout_instruments = payout_i_c.instruments
      @payout_instrument = if payout_instruments.empty?
                             Rails.logger.warn 'No payout instrument found. Creating one'
                             payout_i_c.create_instrument
                           else
                             payout_instruments.first
                           end

      @payout_instrument
    end

    def activate
      @instrument.execute(action: __method__, options: { va_num: @instrument.external_identifier })
    end

    def deactivate
      @instrument.execute(action: __method__, options: { va_num: @instrument.external_identifier })
    end

    # fetch_balance
    def balance
      @store.balance
    end

    # send_funds
    def transfer_funds(amount:, payment_type:, beneficiary:)
      instrument = self.payout_instrument

      entry_id = self.store.withdraw(
        amount: amount,
        tags: {
          mutable_tags: { status: 'PENDING' },
          immutable_tags: { pymt_type: payment_type, beneficiary: beneficiary, instrument_id: instrument.id }
        }
      )
      begin
        payload = { amount: amount, reference_number: entry_id, payment_type: payment_type, beneficiary: beneficiary }.with_indifferent_access
        if payment_type == 'UPI' && beneficiary.key?('upi_id')
          payout_instrument.execute(action: :send_to_upi_id, options: payload)
        else # NEFT, IMPS, RTGS or UPI to bank account number
          payout_instrument.execute(action: :send_to_bank_account, options: payload)
        end
      rescue StandardError => e
        Rails.logger.error e
        self.store.update_txn_status(entry_id, 'FAILED') if entry_id.present?
        raise e
      end
    end

    def self.funds_received_webhook(va_num:, amount:, payment_type:, txn_time: Time.now, status:, bank_ref_id:, beneficiary:, remitter:)
      virtual_account = self.of(va_num)
      virtual_account.store.deposit(
        amount: amount,
        tags: {
          mutable_tags: { status: status, bank_ref_id: bank_ref_id },
          immutable_tags: { pymt_type: payment_type, txn_time: txn_time, beneficiary: beneficiary, remitter: remitter }
        }
      )
    end

    def self.record_txn_status_change(reference_number, status, bank_ref_num)
      TransactionalValueStore.update_txn_status(reference_number, status, { bank_ref_id: bank_ref_num })
    end

    def self.fetch_transaction_status(reference_number)
      instrument = TransactionalValueStore.get_instrument_for_entry(reference_number)
      return if instrument.nil?

      resp = instrument.execute(action: :status, options: { reference_number: reference_number })
      Rails.logger.info "Fetch_transaction_status: response - #{resp}"
      TransactionalValueStore.update_txn_status(reference_number, resp.status, { bank_ref_id: resp.bank_ref_num })
    end
  end
end
