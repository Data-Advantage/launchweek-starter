-- Get the current user's profile
CREATE OR REPLACE FUNCTION api.get_current_user_profile()
RETURNS SETOF api.profiles AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM api.profiles
  WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if a user is an admin
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create or update Stripe customer
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get blog posts with pagination
CREATE OR REPLACE FUNCTION blog.get_posts(
  _limit INTEGER DEFAULT 10,
  _offset INTEGER DEFAULT 0,
  _status TEXT DEFAULT 'published',
  _category_slug TEXT DEFAULT NULL,
  _tag_slug TEXT DEFAULT NULL,
  _search TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  slug TEXT,
  excerpt TEXT,
  content TEXT,
  featured_image TEXT,
  author_id UUID,
  author_name TEXT,
  author_avatar TEXT,
  category_id UUID,
  category_name TEXT,
  category_slug TEXT,
  status TEXT,
  tags JSONB,
  published_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,
  total_count BIGINT
) AS $$
DECLARE
  _total_count BIGINT;
  _query TEXT;
  _where_conditions TEXT := ' WHERE 1=1 ';
  _is_admin BOOLEAN;
BEGIN
  -- Check if user is admin
  SELECT EXISTS (
    SELECT 1 FROM api.profiles
    WHERE id = auth.uid() AND is_admin = true
  ) INTO _is_admin;
  
  -- Build WHERE conditions
  IF _status IS NOT NULL THEN
    IF _status = 'all' AND _is_admin THEN
      -- Admin can see all posts
      _where_conditions := _where_conditions || '';
    ELSE
      -- Non-admin users can only see published posts or their own drafts
      _where_conditions := _where_conditions || 
        ' AND (p.status = ''' || _status || ''' OR p.author_id = ''' || COALESCE(auth.uid()::TEXT, 'null') || ''')';
    END IF;
  END IF;
  
  IF _category_slug IS NOT NULL THEN
    _where_conditions := _where_conditions || ' AND c.slug = ''' || _category_slug || '''';
  END IF;
  
  IF _tag_slug IS NOT NULL THEN
    _where_conditions := _where_conditions || ' AND EXISTS (
      SELECT 1 FROM blog.post_tags pt 
      JOIN blog.tags t ON pt.tag_id = t.id 
      WHERE pt.post_id = p.id AND t.slug = ''' || _tag_slug || '''
    )';
  END IF;
  
  IF _search IS NOT NULL THEN
    _where_conditions := _where_conditions || 
      ' AND (p.title ILIKE ''%' || _search || '%'' OR p.content ILIKE ''%' || _search || '%'')';
  END IF;
  
  -- Get total count for pagination
  EXECUTE 'SELECT COUNT(p.id) FROM blog.posts p
    LEFT JOIN blog.categories c ON p.category_id = c.id
    LEFT JOIN api.profiles pr ON p.author_id = pr.id' 
    || _where_conditions INTO _total_count;
  
  -- Build and execute the main query
  RETURN QUERY EXECUTE 
    'SELECT 
      p.id, p.title, p.slug, p.excerpt, p.content,
      p.featured_image, p.author_id, pr.full_name as author_name,
      pr.avatar_url as author_avatar, p.category_id,
      c.name as category_name, c.slug as category_slug,
      p.status,
      COALESCE(
        (SELECT jsonb_agg(jsonb_build_object(
          ''id'', t.id,
          ''name'', t.name,
          ''slug'', t.slug
        ))
        FROM blog.post_tags pt
        JOIN blog.tags t ON pt.tag_id = t.id
        WHERE pt.post_id = p.id),
        ''[]''::jsonb
      ) as tags,
      p.published_at, p.created_at, p.updated_at, 
      ' || _total_count || '::BIGINT as total_count
    FROM blog.posts p
    LEFT JOIN blog.categories c ON p.category_id = c.id
    LEFT JOIN api.profiles pr ON p.author_id = pr.id'
    || _where_conditions ||
    ' ORDER BY 
      CASE WHEN p.status = ''published'' THEN 0 ELSE 1 END,
      p.published_at DESC NULLS LAST,
      p.created_at DESC
    LIMIT ' || _limit || ' OFFSET ' || _offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = blog, api, public, pg_temp; 