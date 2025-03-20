module StripeMock
  module RequestHandlers
    module CustomerSessions
      def CustomerSessions.included(klass)
        klass.add_handler 'post /v1/customer_sessions', :new_customer_session
      end

      def new_customer_session(route, method_url, params, headers)
        params[:id] ||= new_id('cus_ses')
        customer_sessions[params[:id]] = Data.mock_customer_session(params)
        customer_sessions[params[:id]]
      end
    end
  end
end
