-- Seed blog categories
INSERT INTO blog.categories (name, slug, description) VALUES
('Getting Started', 'getting-started', 'Tutorials and guides for beginners'),
('Features', 'features', 'Detailed information about product features'),
('Case Studies', 'case-studies', 'Success stories and implementation examples'),
('Product Updates', 'product-updates', 'New features and improvements'),
('Tutorials', 'tutorials', 'Step-by-step guides');

-- Seed blog tags
INSERT INTO blog.tags (name, slug, description) VALUES
('Next.js', 'nextjs', 'Content related to Next.js framework'),
('React', 'react', 'Content about React components and patterns'),
('Supabase', 'supabase', 'Tutorials and tips for working with Supabase'),
('Stripe', 'stripe', 'Integration guides and payment processing'),
('Tailwind CSS', 'tailwind-css', 'Styling and UI design with Tailwind'),
('Authentication', 'authentication', 'User management and auth flows'),
('Database', 'database', 'Working with Postgres and Supabase'),
('Deployment', 'deployment', 'Guides for deploying your application'),
('Performance', 'performance', 'Tips for optimizing your application');

-- Seed example Stripe products
INSERT INTO stripe.products (id, active, name, description, metadata) VALUES
('prod_starter', true, 'Starter Plan', 'Perfect for individuals and small projects', '{"features": ["Up to 100 API calls/day", "Standard support", "3 projects", "Basic analytics"]}'),
('prod_professional', true, 'Professional Plan', 'For growing businesses with more needs', '{"features": ["Unlimited API calls", "Priority support", "10 projects", "Advanced analytics", "Team collaboration"]}'),
('prod_enterprise', true, 'Enterprise Plan', 'For large organizations with custom requirements', '{"features": ["Custom API limits", "Dedicated support", "Unlimited projects", "Custom analytics", "Advanced security", "SLA guarantees"]}');

-- Seed example Stripe prices
INSERT INTO stripe.prices (id, product_id, active, currency, description, type, unit_amount, interval, interval_count) VALUES
('price_starter_monthly', 'prod_starter', true, 'usd', 'Starter Plan - Monthly', 'recurring', 999, 'month', 1),
('price_starter_yearly', 'prod_starter', true, 'usd', 'Starter Plan - Yearly', 'recurring', 9990, 'year', 1),
('price_professional_monthly', 'prod_professional', true, 'usd', 'Professional Plan - Monthly', 'recurring', 2999, 'month', 1),
('price_professional_yearly', 'prod_professional', true, 'usd', 'Professional Plan - Yearly', 'recurring', 29990, 'year', 1),
('price_enterprise_monthly', 'prod_enterprise', true, 'usd', 'Enterprise Plan - Monthly', 'recurring', 9999, 'month', 1),
('price_enterprise_yearly', 'prod_enterprise', true, 'usd', 'Enterprise Plan - Yearly', 'recurring', 99990, 'year', 1); 