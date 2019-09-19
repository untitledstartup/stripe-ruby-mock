module StripeMock
  module RequestHandlers
    module ParamValidators

      def validate_create_plan_params(params)
        params[:id] = params[:id].to_s

        # Retrofit for old version of the API.
        # The old versions only supported automatic
        # creation of products for subscriptions, so
        # we can hard-code the 'service' type.
        if !params.key?(:product)
          product = {
            id: 'stripe_mock_default_product_id',
            name: params[:name],
            type: 'service'
          }
          params[:product] = product
        end

        @base_strategy.create_plan_params.keys.each do |name|
          message =
            if name == :amount
              "Plans require an `#{name}` parameter to be set."
            else
              "Missing required param: #{name}."
            end
          raise Stripe::InvalidRequestError.new(message, name) if params[name].nil?
        end

        if plans[ params[:id] ]
          raise Stripe::InvalidRequestError.new("Plan already exists.", :id)
        end

        unless params[:amount].integer?
          raise Stripe::InvalidRequestError.new("Invalid integer: #{params[:amount]}", :amount)
        end
      end

      def require_param(param_name)
        raise Stripe::InvalidRequestError.new("Missing required param: #{param_name}.", param_name.to_s, http_status: 400)
      end

      def validate_create_sku_params(params)
        @base_strategy.create_sku_params.keys.each do |name|
          message = "Missing required param: #{name}."
          raise Stripe::InvalidRequestError.new(message, name) if params[name].nil?
        end

        if skus[ params[:id] ]
          raise Stripe::InvalidRequestError.new("SKU already exists.", :id)
        end

        unless %w(finite bucket infinite).include? params[:inventory][:type]
          raise Stripe::InvalidRequestError.new("Invalid inventory type: must be one of finite, infinite, or bucket", :type)
        end
      end
    end
  end
end
