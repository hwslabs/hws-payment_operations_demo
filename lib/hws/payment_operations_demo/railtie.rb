# frozen_string_literal: true

class PaymentOperationsDemoRailtie < Rails::Railtie # :nodoc:
  initializer 'PaymentOperationsDemo.connector_initialization' do # rubocop:disable Metrics/BlockLength
    Hws::Connectors.configure do |config| # rubocop:disable Metrics/BlockLength
      config.webhooks = {
        'payouts' => {
          'callback' => lambda do |_entity, response|
                          Rails.logger.debug response.inspect

                          begin
                            Hws::PaymentOperationsDemo::VirtualAccount.record_txn_status_change(
                              response.reference_number, response.status, response.bank_ref_num
                            )
                          rescue StandardError => e
                            Rails.logger.info e.backtrace
                            raise e
                          end
                        end
        },
        'virtual_accounts' => {
          'notify' => lambda do |_entity, response|
                        Rails.logger.debug response.inspect
                        begin
                          Hws::PaymentOperationsDemo::VirtualAccount.funds_received_webhook(
                            va_num: response.beneficiary.account_number,
                            amount: response.amount,
                            payment_type: response.payment_type,
                            txn_time: response.credit_time,
                            status: 'COMPLETED',
                            bank_ref_id: response.bank_ref_num,
                            beneficiary: response.beneficiary,
                            remitter: response.remitter
                          )
                        rescue StandardError => e
                          Rails.logger.info e.backtrace
                          raise e
                        end
                      end
        }
      }
    end
  end
end
