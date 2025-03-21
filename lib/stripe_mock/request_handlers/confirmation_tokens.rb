module StripeMock
  module RequestHandlers
    module ConfirmationTokens
      def ConfirmationTokens.included(klass)
        klass.add_handler 'get /v1/confirmation_tokens/(.*)', :retrieve_confirmation_token
        klass.add_handler 'post /v1/confirmation_tokens', :new_confirmation_token
      end

      def new_confirmation_token(route, method_url, params, headers)
        params[:id] ||= new_id('ctoken')

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

      def retrieve_confirmation_token(route, method_url, params, headers)
        route =~ method_url

        assert_existence :confirmation_token, $1, confirmation_tokens[$1]
      end
    end
  end
end