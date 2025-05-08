-- Create internal schema for sensitive operations
CREATE SCHEMA IF NOT EXISTS internal;

-- Set up necessary permissions for RLS on internal schema
ALTER DEFAULT PRIVILEGES IN SCHEMA internal GRANT ALL ON TABLES TO postgres, service_role;

-- Create internal.user_credits table for tracking user credit balances
CREATE TABLE internal.user_credits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  total_credits INTEGER NOT NULL DEFAULT 0,
  remaining_credits INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (user_id)
);

-- Create internal.credit_transactions table for tracking credit history
CREATE TABLE internal.credit_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('purchase', 'consumption', 'refund', 'bonus', 'expiration')),
  description TEXT,
  payment_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security on internal tables
ALTER TABLE internal.user_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE internal.credit_transactions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for internal tables
CREATE POLICY "Users can view their own credits"
  ON internal.user_credits
  FOR SELECT
  USING (auth.uid() = user_id OR auth.role() = 'service_role');

CREATE POLICY "Only service role can modify credits"
  ON internal.user_credits
  FOR ALL
  USING (auth.role() = 'service_role');

CREATE POLICY "Users can view their own credit transactions"
  ON internal.credit_transactions
  FOR SELECT
  USING (auth.uid() = user_id OR auth.role() = 'service_role');

CREATE POLICY "Only service role can create credit transactions"
  ON internal.credit_transactions
  FOR INSERT
  WITH CHECK (auth.role() = 'service_role');

-- Create webhook_events table in stripe schema
CREATE TABLE stripe.webhook_events (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  api_version TEXT,
  created TIMESTAMP WITH TIME ZONE,
  data JSONB,
  processing_status TEXT DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processed', 'failed')),
  processing_error TEXT,
  processing_attempts INTEGER DEFAULT 0,
  processed_at TIMESTAMP WITH TIME ZONE,
  received_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on webhook_events
ALTER TABLE stripe.webhook_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Only service role can access webhook events"
  ON stripe.webhook_events
  FOR ALL
  USING (auth.role() = 'service_role');

-- Secure existing functions with explicit search paths
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO api.profiles (id, email, full_name, avatar_url)
  VALUES (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

CREATE OR REPLACE FUNCTION public.user_has_active_subscription(user_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
  has_subscription BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM stripe.subscriptions
    WHERE user_id = user_uuid
    AND status IN ('trialing', 'active')
  ) INTO has_subscription;
  
  RETURN has_subscription;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, stripe, pg_temp;

CREATE OR REPLACE FUNCTION api.get_current_user_profile()
RETURNS SETOF api.profiles AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM api.profiles
  WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, pg_temp;

CREATE OR REPLACE FUNCTION api.is_admin()
RETURNS BOOLEAN AS $$
DECLARE
  is_admin BOOLEAN;
BEGIN
  SELECT p.is_admin INTO is_admin
  FROM api.profiles p
  WHERE p.id = auth.uid();
  
  RETURN COALESCE(is_admin, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, pg_temp;

CREATE OR REPLACE FUNCTION stripe.create_or_update_customer(
  user_id UUID,
  customer_data JSONB
)
RETURNS TEXT AS $$
DECLARE
  customer_id TEXT;
BEGIN
  -- Check if customer exists for this user
  SELECT id INTO customer_id
  FROM stripe.customers
  WHERE stripe.customers.user_id = create_or_update_customer.user_id;
  
  -- Insert or update customer data
  IF customer_id IS NULL THEN
    INSERT INTO stripe.customers (
      id,
      user_id,
      email,
      name,
      phone,
      address,
      metadata
    ) VALUES (
      customer_data->>'id',
      create_or_update_customer.user_id,
      customer_data->>'email',
      customer_data->>'name',
      customer_data->>'phone',
      customer_data->'address',
      customer_data->'metadata'
    )
    RETURNING id INTO customer_id;
  ELSE
    UPDATE stripe.customers SET
      email = customer_data->>'email',
      name = customer_data->>'name',
      phone = customer_data->>'phone',
      address = customer_data->'address',
      metadata = customer_data->'metadata',
      updated_at = NOW()
    WHERE id = customer_id;
  END IF;
  
  RETURN customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = stripe, pg_temp;

-- Create standard timestamp function
CREATE OR REPLACE FUNCTION public.handle_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  -- Set created_at for new records
  IF TG_OP = 'INSERT' THEN
    NEW.created_at = NOW();
  END IF;
  
  -- Always update the updated_at timestamp
  NEW.updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Apply timestamp triggers to existing tables
CREATE TRIGGER handle_timestamps_profiles
BEFORE INSERT OR UPDATE ON api.profiles
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

CREATE TRIGGER handle_timestamps_stripe_products
BEFORE INSERT OR UPDATE ON stripe.products
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

CREATE TRIGGER handle_timestamps_stripe_prices
BEFORE INSERT OR UPDATE ON stripe.prices
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

CREATE TRIGGER handle_timestamps_stripe_customers
BEFORE INSERT OR UPDATE ON stripe.customers
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

CREATE TRIGGER handle_timestamps_stripe_subscriptions
BEFORE INSERT OR UPDATE ON stripe.subscriptions
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

CREATE TRIGGER handle_timestamps_blog_categories
BEFORE INSERT OR UPDATE ON blog.categories
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

CREATE TRIGGER handle_timestamps_blog_posts
BEFORE INSERT OR UPDATE ON blog.posts
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

CREATE TRIGGER handle_timestamps_blog_tags
BEFORE INSERT OR UPDATE ON blog.tags
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

CREATE TRIGGER handle_timestamps_blog_comments
BEFORE INSERT OR UPDATE ON blog.comments
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

-- Create configuration schema for application settings
CREATE SCHEMA IF NOT EXISTS config;

-- Set up necessary permissions for RLS on config schema
ALTER DEFAULT PRIVILEGES IN SCHEMA config GRANT ALL ON TABLES TO postgres, service_role;

-- Create config.subscription_benefits table
CREATE TABLE config.subscription_benefits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id TEXT REFERENCES stripe.products(id) ON DELETE CASCADE,
  feature_limits JSONB NOT NULL DEFAULT '{}'::jsonb,
  has_premium_features BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create config.credit_packs table
CREATE TABLE config.credit_packs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id TEXT REFERENCES stripe.products(id) ON DELETE CASCADE,
  credits_amount INTEGER NOT NULL,
  bonus_credits INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on config tables
ALTER TABLE config.subscription_benefits ENABLE ROW LEVEL SECURITY;
ALTER TABLE config.credit_packs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for config tables
CREATE POLICY "Anyone can view subscription benefits"
  ON config.subscription_benefits
  FOR SELECT
  USING (true);

CREATE POLICY "Only service role can modify subscription benefits"
  ON config.subscription_benefits
  FOR ALL
  USING (auth.role() = 'service_role');

CREATE POLICY "Anyone can view credit packs"
  ON config.credit_packs
  FOR SELECT
  USING (true);

CREATE POLICY "Only service role can modify credit packs"
  ON config.credit_packs
  FOR ALL
  USING (auth.role() = 'service_role');

-- Apply handles_timestamps trigger to config tables
CREATE TRIGGER handle_timestamps_subscription_benefits
BEFORE INSERT OR UPDATE ON config.subscription_benefits
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

CREATE TRIGGER handle_timestamps_credit_packs
BEFORE INSERT OR UPDATE ON config.credit_packs
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

-- Create function to get user subscription status
CREATE OR REPLACE FUNCTION api.get_user_subscription(user_uuid UUID DEFAULT NULL)
RETURNS TABLE (
  subscription_id TEXT,
  status TEXT,
  product_id TEXT,
  product_name TEXT,
  price_id TEXT,
  interval TEXT,
  amount BIGINT,
  currency TEXT,
  is_active BOOLEAN,
  current_period_end TIMESTAMP WITH TIME ZONE,
  cancel_at_period_end BOOLEAN
) AS $$
DECLARE
  _user_id UUID;
BEGIN
  -- Use provided user_id or fall back to current user
  _user_id := COALESCE(user_uuid, auth.uid());
  
  -- Check permissions
  IF _user_id != auth.uid() AND NOT api.is_admin() THEN
    RAISE EXCEPTION 'Not authorized to view subscription data for other users';
  END IF;
  
  RETURN QUERY
  SELECT 
    s.id AS subscription_id,
    s.status::TEXT,
    p.product_id,
    prod.name AS product_name,
    s.price_id,
    p.interval,
    p.unit_amount AS amount,
    p.currency,
    s.status IN ('active', 'trialing') AS is_active,
    s.current_period_end,
    s.cancel_at_period_end
  FROM stripe.subscriptions s
  JOIN stripe.prices p ON s.price_id = p.id
  JOIN stripe.products prod ON p.product_id = prod.id
  WHERE s.user_id = _user_id
  AND s.status IN ('active', 'trialing', 'canceled', 'past_due')
  ORDER BY s.current_period_end DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, stripe, pg_temp;

-- Create function to get user credit balance
CREATE OR REPLACE FUNCTION api.get_user_credits(user_uuid UUID DEFAULT NULL)
RETURNS TABLE (
  total_credits INTEGER,
  remaining_credits INTEGER,
  updated_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
  _user_id UUID;
BEGIN
  -- Use provided user_id or fall back to current user
  _user_id := COALESCE(user_uuid, auth.uid());
  
  -- Check permissions
  IF _user_id != auth.uid() AND NOT api.is_admin() THEN
    RAISE EXCEPTION 'Not authorized to view credit data for other users';
  END IF;
  
  RETURN QUERY
  SELECT 
    uc.total_credits,
    uc.remaining_credits,
    uc.updated_at
  FROM internal.user_credits uc
  WHERE uc.user_id = _user_id;
  
  -- If no record exists, return zeros
  IF NOT FOUND THEN
    RETURN QUERY SELECT 0, 0, NOW();
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, internal, pg_temp;

-- Create function to process Stripe webhook events
CREATE OR REPLACE FUNCTION stripe.process_webhook_event(event_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  webhook_event RECORD;
  subscription_record RECORD;
  customer_id TEXT;
  user_id UUID;
  checkout_session JSONB;
  subscription_data JSONB;
  subscription_id TEXT;
  price_id TEXT;
  product_id TEXT;
  credit_amount INTEGER;
BEGIN
  -- Get webhook event
  SELECT * INTO webhook_event 
  FROM stripe.webhook_events 
  WHERE id = event_id AND processing_status = 'pending';
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Webhook event not found or already processed: %', event_id;
  END IF;
  
  -- Update attempts
  UPDATE stripe.webhook_events 
  SET processing_attempts = processing_attempts + 1 
  WHERE id = event_id;
  
  -- Process based on event type
  CASE webhook_event.type
    -- Handle subscription events
    WHEN 'customer.subscription.created', 'customer.subscription.updated' THEN
      subscription_data := webhook_event.data->'object';
      subscription_id := subscription_data->>'id';
      customer_id := subscription_data->>'customer';
      price_id := (subscription_data->'items'->'data'->0->>'price');
      
      -- Get user_id from customer
      SELECT user_id INTO user_id 
      FROM stripe.customers 
      WHERE id = customer_id;
      
      IF user_id IS NULL THEN
        RAISE EXCEPTION 'No user found for customer: %', customer_id;
      END IF;
      
      -- Upsert subscription
      INSERT INTO stripe.subscriptions (
        id, 
        user_id, 
        customer_id, 
        status,
        price_id,
        cancel_at_period_end,
        current_period_start,
        current_period_end,
        metadata
      ) VALUES (
        subscription_id,
        user_id,
        customer_id,
        (subscription_data->>'status')::reference.subscription_status,
        price_id,
        (subscription_data->>'cancel_at_period_end')::boolean,
        to_timestamp((subscription_data->>'current_period_start')::integer),
        to_timestamp((subscription_data->>'current_period_end')::integer),
        subscription_data->'metadata'
      )
      ON CONFLICT (id) DO UPDATE SET
        status = (subscription_data->>'status')::reference.subscription_status,
        price_id = price_id,
        cancel_at_period_end = (subscription_data->>'cancel_at_period_end')::boolean,
        current_period_start = to_timestamp((subscription_data->>'current_period_start')::integer),
        current_period_end = to_timestamp((subscription_data->>'current_period_end')::integer),
        metadata = subscription_data->'metadata',
        updated_at = NOW();
        
    -- Handle checkout session completion
    WHEN 'checkout.session.completed' THEN
      checkout_session := webhook_event.data->'object';
      customer_id := checkout_session->>'customer';
      
      -- Get user_id from customer
      SELECT user_id INTO user_id 
      FROM stripe.customers 
      WHERE id = customer_id;
      
      IF user_id IS NULL THEN
        RAISE EXCEPTION 'No user found for customer: %', customer_id;
      END IF;
      
      -- Handle one-time purchases (credit packs)
      IF checkout_session->>'mode' = 'payment' THEN
        price_id := checkout_session->'line_items'->'data'->0->'price'->>'id';
        
        -- Get product_id from price
        SELECT product_id INTO product_id 
        FROM stripe.prices 
        WHERE id = price_id;
        
        -- Get credit amount from config
        SELECT credits_amount + bonus_credits INTO credit_amount 
        FROM config.credit_packs 
        WHERE product_id = product_id;
        
        IF credit_amount IS NULL THEN
          RAISE EXCEPTION 'No credit pack found for product: %', product_id;
        END IF;
        
        -- Update user credits
        INSERT INTO internal.user_credits (
          user_id, 
          total_credits, 
          remaining_credits
        ) VALUES (
          user_id,
          credit_amount,
          credit_amount
        )
        ON CONFLICT (user_id) DO UPDATE SET
          total_credits = internal.user_credits.total_credits + credit_amount,
          remaining_credits = internal.user_credits.remaining_credits + credit_amount,
          updated_at = NOW();
          
        -- Record transaction
        INSERT INTO internal.credit_transactions (
          user_id,
          amount,
          transaction_type,
          description,
          payment_id
        ) VALUES (
          user_id,
          credit_amount,
          'purchase',
          'Credit pack purchase',
          checkout_session->>'payment_intent'
        );
      END IF;
  END CASE;
  
  -- Mark webhook as processed
  UPDATE stripe.webhook_events 
  SET 
    processing_status = 'processed',
    processed_at = NOW()
  WHERE id = event_id;
  
  RETURN TRUE;
  
EXCEPTION WHEN OTHERS THEN
  -- Record error
  UPDATE stripe.webhook_events 
  SET 
    processing_status = 'failed',
    processing_error = SQLERRM
  WHERE id = event_id;
  
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = stripe, internal, config, public, pg_temp; 