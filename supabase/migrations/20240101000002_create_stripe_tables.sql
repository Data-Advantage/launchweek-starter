-- Create products table
CREATE TABLE stripe.products (
  id TEXT PRIMARY KEY, -- Stripe product ID
  active BOOLEAN,
  name TEXT,
  description TEXT,
  image TEXT,
  metadata JSONB,
  created TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create prices table
CREATE TABLE stripe.prices (
  id TEXT PRIMARY KEY, -- Stripe price ID
  product_id TEXT REFERENCES stripe.products(id),
  active BOOLEAN,
  currency TEXT,
  description TEXT,
  type TEXT, -- 'one_time' or 'recurring'
  unit_amount BIGINT, -- Amount in cents
  interval TEXT, -- For recurring prices: 'day', 'week', 'month', or 'year'
  interval_count INTEGER, -- For recurring prices
  trial_period_days INTEGER,
  metadata JSONB,
  created TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create customers table
CREATE TABLE stripe.customers (
  id TEXT PRIMARY KEY, -- Stripe customer ID
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  name TEXT,
  phone TEXT,
  address JSONB,
  metadata JSONB,
  created TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (user_id)
);

-- Create subscriptions table
CREATE TABLE stripe.subscriptions (
  id TEXT PRIMARY KEY, -- Stripe subscription ID
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  customer_id TEXT REFERENCES stripe.customers(id),
  status reference.subscription_status,
  price_id TEXT REFERENCES stripe.prices(id),
  quantity INTEGER,
  cancel_at_period_end BOOLEAN,
  cancel_at TIMESTAMP WITH TIME ZONE,
  canceled_at TIMESTAMP WITH TIME ZONE,
  current_period_start TIMESTAMP WITH TIME ZONE,
  current_period_end TIMESTAMP WITH TIME ZONE,
  ended_at TIMESTAMP WITH TIME ZONE,
  trial_start TIMESTAMP WITH TIME ZONE,
  trial_end TIMESTAMP WITH TIME ZONE,
  metadata JSONB,
  created TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create an index for faster queries
CREATE INDEX stripe_subscriptions_user_id_idx ON stripe.subscriptions (user_id);
CREATE INDEX stripe_customers_user_id_idx ON stripe.customers (user_id);

-- Enable RLS on all tables
ALTER TABLE stripe.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe.prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe.subscriptions ENABLE ROW LEVEL SECURITY;

-- Create policies for products and prices (viewable by all authenticated users)
CREATE POLICY "Allow authenticated users to view products"
  ON stripe.products
  FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to view prices"
  ON stripe.prices
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- Create policies for customers (only viewable by the customer or admin)
CREATE POLICY "Allow users to view their own customer data"
  ON stripe.customers
  FOR SELECT
  USING (auth.uid() = user_id OR auth.role() = 'service_role');

-- Create policies for subscriptions (only viewable by the subscriber or admin)
CREATE POLICY "Allow users to view their own subscriptions"
  ON stripe.subscriptions
  FOR SELECT
  USING (auth.uid() = user_id OR auth.role() = 'service_role');

-- Create a function to check if a user has an active subscription
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a view for easier access to subscription status
CREATE OR REPLACE VIEW public.subscription_status AS
SELECT
  auth.users.id AS user_id,
  auth.users.email,
  stripe.subscriptions.id AS subscription_id,
  stripe.subscriptions.status,
  stripe.prices.id AS price_id,
  stripe.prices.product_id,
  stripe.prices.unit_amount,
  stripe.prices.interval,
  stripe.prices.currency,
  stripe.products.name AS product_name,
  stripe.subscriptions.current_period_end,
  stripe.subscriptions.cancel_at_period_end
FROM auth.users
LEFT JOIN stripe.subscriptions ON auth.users.id = stripe.subscriptions.user_id
LEFT JOIN stripe.prices ON stripe.subscriptions.price_id = stripe.prices.id
LEFT JOIN stripe.products ON stripe.prices.product_id = stripe.products.id
WHERE stripe.subscriptions.status IN ('trialing', 'active') OR stripe.subscriptions.status IS NULL; 