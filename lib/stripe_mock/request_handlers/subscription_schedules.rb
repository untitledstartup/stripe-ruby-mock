module StripeMock
  module RequestHandlers
    module SubscriptionSchedules
      def SubscriptionSchedules.included(klass)
        klass.add_handler 'get /v1/subscription_schedules/(.*)', :retrieve_subscription_schedule
        klass.add_handler 'post /v1/subscription_schedules', :new_subscription_schedule
      end

      def new_subscription_schedule(route, method_url, params, headers)
        params[:id] ||= new_id('sub_sched')

        if params[:from_subscription]
          subscription = assert_existence :subscription, params[:from_subscription], subscriptions[params[:from_subscription]]
        else
          subscription = Data.mock_subscription({ id: (params[:id] || new_id('su')) })
        end

        customer = params[:customer]
        customer_id = customer.is_a?(Stripe::Customer) ? customer[:id] : customer.to_s
        customer = assert_existence :customer, customer_id, customers[stripe_account][customer_id]

        subscription_schedules[params[:id]] = Data.mock_subscription_schedule(params)
        # Set schedule id on subscription
        subscription[:schedule] = params[:id]

        # Deleting to avoid duplicate subscription in customer
        delete_subscription_from_customer customer, subscription

        # Adding updated subscription back to the customer and to regular subscriptions
        subscriptions[subscription[:id]] = subscription
        add_subscription_to_customer(customer, subscription)

        subscription_schedules[params[:id]]
      end

      def retrieve_subscription_schedule(route, method_url, params, headers)
        route =~ method_url

        assert_existence :subscription_schedule, $1, subscription_schedules[$1]
      end
    end
  end
end