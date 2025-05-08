# Supabase Configuration for LaunchWeek Starter

This directory contains the database migration scripts that set up the necessary schemas and tables for the LaunchWeek Starter application.

## Migration Files

The migrations are designed to run in sequence, with each one building on the previous:

1. `20240101000000_create_schemas.sql` - Creates the `stripe`, `api`, and `blog` schemas
2. `20240101000001_create_profiles_table.sql` - Sets up the profiles table and related triggers
3. `20240101000002_create_stripe_tables.sql` - Creates tables for Stripe integration
4. `20240101000003_create_blog_tables.sql` - Sets up the blog system
5. `20240101000004_create_api_functions.sql` - Adds utility functions for the API
6. `20240101000005_seed_data.sql` - Populates the database with initial data
7. `20240101000006_security_enhancements.sql` - Enhances security and adds additional schemas
8. `20240101000007_seed_config_data.sql` - Populates configuration tables

## Setting Up Your Supabase Project

1. Create a new Supabase project through the [Supabase Dashboard](https://app.supabase.io/)
2. Go to the SQL Editor in your project
3. Run each migration script in sequence, starting with `20240101000000_create_schemas.sql`
4. Verify the migrations ran successfully by checking the tables in the Table Editor

Alternatively, you can use the Supabase CLI:

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Push the migrations
supabase db push
```

## Database Structure

### Schema Organization

Following best practices for Supabase projects, we use a custom schema structure:

- `public` - Limited use for functions and enums that need broader access
- `api` - User-generated content and application data
- `stripe` - Payment processing and subscription management
- `blog` - Content management system for blog posts
- `internal` - Sensitive operations not directly accessible to users
- `config` - Application configuration and settings

### Tables by Schema

#### `api` Schema
- `profiles`: Stores user profile information, linked to auth.users

#### `stripe` Schema
- `products`: Stripe products and their details
- `prices`: Pricing information for products
- `customers`: Customer information from Stripe
- `subscriptions`: User subscription details
- `webhook_events`: History of received Stripe webhook events

#### `blog` Schema
- `categories`: Blog post categories
- `posts`: Blog articles
- `tags`: Tags for categorizing posts
- `post_tags`: Join table linking posts to tags
- `comments`: User comments on blog posts

#### `internal` Schema
- `user_credits`: Tracks user credit balances for consumption-based pricing
- `credit_transactions`: Detailed history of credit purchases and usage

#### `config` Schema
- `subscription_benefits`: Maps subscription tiers to application features
- `credit_packs`: Defines what each credit pack contains

## Security Model

### Row Level Security (RLS)

All tables are protected with Row Level Security policies that control access:

- Users can only view and modify their own profile information
- Only admins can create and edit blog categories and tags
- Published blog posts are viewable by everyone
- Draft posts are only viewable by their authors or admins
- Blog comments need approval before being publicly visible
- Credit information is only accessible to the user it belongs to or service role

### Function Security

Database functions use the following security patterns:

- `SECURITY DEFINER` for functions that need elevated permissions
- Explicit search paths (`SET search_path = schema, pg_temp`) to prevent injection
- Schema placement based on sensitivity level

### Storage Bucket Policies

Storage is organized into three buckets with different access patterns:

- `public`: Anyone can view, authenticated users can upload
- `protected`: Only authenticated users can view/upload
- `private`: Users can only access their own files

## Automatic Triggers

When a new user signs up, a trigger function automatically creates:

1. A profile record in the `api.profiles` table using the user's information from `auth.users`

## Access Patterns

### Subscription Model

The system supports both subscription-based and credit-based pricing:

#### Subscription-Based Features
- User purchases a subscription plan (Starter, Professional, Enterprise)
- Each plan provides different feature limits defined in `config.subscription_benefits`
- Active subscription status checked via `public.user_has_active_subscription()` function

#### Credits-Based Features
- User purchases credit packs with different amounts
- Credits are stored in `internal.user_credits` with history in `internal.credit_transactions`
- API functions to check and update credit balances with proper security controls 