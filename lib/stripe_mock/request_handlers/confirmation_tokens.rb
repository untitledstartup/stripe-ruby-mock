module StripeMock
  module RequestHandlers
    module ConfirmationTokens
      def ConfirmationTokens.included(klass)
        klass.add_handler 'get /v1/confirmation_tokens/(.*)', :retrieve_confirmation_token
        klass.add_handler 'post /v1/test_helpers/confirmation_tokens', :new_confirmation_token
      end

      def create_default_confirmation_token(route, method_url, params, headers)
        card_token_id = StripeMock.generate_card_token(last4: "9191", exp_year: Time.now.year.next, exp_month: 4, brand: 'Visa')
        params[:payment_method_data] = {
          type: 'card',
          card: {
            token: card_token_id
          },
          setup_future_usage: 'off_session'
        }

        new_confirmation_token(route, method_url, params, headers)
      end

      def retrieve_confirmation_token(route, method_url, params, headers)
        route =~ method_url

        # If confirmation is not found, create a new one. This may happen if the tests are running real stripe on the UI but Stripe-ruby-mock on the backend.
        if confirmation_tokens[$1].nil?
          params[:id] = $1
          confirmation_tokens[$1] = create_default_confirmation_token(params)
        end

        assert_existence :confirmation_token, $1, confirmation_tokens[$1]
      end

      def new_confirmation_token(route, method_url, params, headers)
        params[:id] ||= new_id('ctoken')
        id = new_id('pi')
        secret = new_id('secret')

        if params[:payment_method_data]
          payment_method = new_payment_method(nil, nil, params[:payment_method_data], headers)
          params[:payment_method] = payment_method[:id]
        end

        payment_intents[id] = Data.mock_payment_intent(
          params.merge(
            id: id,
            client_secret: "#{id}_#{secret}",
            status: status(params),
          )
        )

        confirmation_tokens[params[:id]] = Data.mock_confirmation_token(params)
        confirmation_tokens[params[:id]]
      end
    end
  end
end