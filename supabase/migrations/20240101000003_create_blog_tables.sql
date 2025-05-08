-- Create blog categories table
CREATE TABLE blog.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  parent_id UUID REFERENCES blog.categories(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create blog posts table
CREATE TABLE blog.posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  excerpt TEXT,
  content TEXT NOT NULL,
  featured_image TEXT,
  author_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  category_id UUID REFERENCES blog.categories(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  meta_title TEXT,
  meta_description TEXT,
  published_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create blog tags table
CREATE TABLE blog.tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create post_tags junction table
CREATE TABLE blog.post_tags (
  post_id UUID REFERENCES blog.posts(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES blog.tags(id) ON DELETE CASCADE,
  PRIMARY KEY (post_id, tag_id)
);

-- Create comments table
CREATE TABLE blog.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES blog.posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES blog.comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_approved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE blog.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog.tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog.post_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog.comments ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for blog tables

-- Categories: Everyone can read, only admins can write
CREATE POLICY "Allow public read access to categories"
  ON blog.categories
  FOR SELECT
  USING (true);

CREATE POLICY "Allow admin write access to categories"
  ON blog.categories
  FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM api.profiles WHERE id = auth.uid() AND is_admin = true));

CREATE POLICY "Allow admin update access to categories"
  ON blog.categories
  FOR UPDATE
  USING (EXISTS (SELECT 1 FROM api.profiles WHERE id = auth.uid() AND is_admin = true));

CREATE POLICY "Allow admin delete access to categories"
  ON blog.categories
  FOR DELETE
  USING (EXISTS (SELECT 1 FROM api.profiles WHERE id = auth.uid() AND is_admin = true));

-- Posts: Published posts are public, drafts visible to authors and admins
CREATE POLICY "Allow public read access to published posts"
  ON blog.posts
  FOR SELECT
  USING (status = 'published' OR author_id = auth.uid() OR 
         EXISTS (SELECT 1 FROM api.profiles WHERE id = auth.uid() AND is_admin = true));

CREATE POLICY "Allow authors to write their own posts"
  ON blog.posts
  FOR INSERT
  WITH CHECK (author_id = auth.uid() OR 
             EXISTS (SELECT 1 FROM api.profiles WHERE id = auth.uid() AND is_admin = true));

CREATE POLICY "Allow authors to update their own posts"
  ON blog.posts
  FOR UPDATE
  USING (author_id = auth.uid() OR 
         EXISTS (SELECT 1 FROM api.profiles WHERE id = auth.uid() AND is_admin = true));

CREATE POLICY "Allow authors to delete their own posts"
  ON blog.posts
  FOR DELETE
  USING (author_id = auth.uid() OR 
         EXISTS (SELECT 1 FROM api.profiles WHERE id = auth.uid() AND is_admin = true));

-- Tags: Everyone can read, only admins can write
CREATE POLICY "Allow public read access to tags"
  ON blog.tags
  FOR SELECT
  USING (true);

CREATE POLICY "Allow admin write access to tags"
  ON blog.tags
  FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM api.profiles WHERE id = auth.uid() AND is_admin = true));

CREATE POLICY "Allow admin update access to tags"
  ON blog.tags
  FOR UPDATE
  USING (EXISTS (SELECT 1 FROM api.profiles WHERE id = auth.uid() AND is_admin = true));

CREATE POLICY "Allow admin delete access to tags"
  ON blog.tags
  FOR DELETE
  USING (EXISTS (SELECT 1 FROM api.profiles WHERE id = auth.uid() AND is_admin = true));

-- Post Tags: Same permissions as posts
CREATE POLICY "Allow public read access to post_tags"
  ON blog.post_tags
  FOR SELECT
  USING (EXISTS (SELECT 1 FROM blog.posts WHERE blog.posts.id = post_id AND 
                (blog.posts.status = 'published' OR blog.posts.author_id = auth.uid() OR
                 EXISTS (SELECT 1 FROM api.profiles WHERE id = auth.uid() AND is_admin = true))));

CREATE POLICY "Allow authors to manage their post tags"
  ON blog.post_tags
  FOR ALL
  USING (EXISTS (SELECT 1 FROM blog.posts WHERE blog.posts.id = post_id AND 
                (blog.posts.author_id = auth.uid() OR
                 EXISTS (SELECT 1 FROM api.profiles WHERE id = auth.uid() AND is_admin = true))));

-- Comments: Published comments are public, pending are visible to comment author and admins
CREATE POLICY "Allow public read access to approved comments"
  ON blog.comments
  FOR SELECT
  USING (is_approved = true OR user_id = auth.uid() OR 
         EXISTS (SELECT 1 FROM api.profiles WHERE id = auth.uid() AND is_admin = true));

CREATE POLICY "Allow authenticated users to create comments"
  ON blog.comments
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow users to update their own comments"
  ON blog.comments
  FOR UPDATE
  USING (user_id = auth.uid() OR 
         EXISTS (SELECT 1 FROM api.profiles WHERE id = auth.uid() AND is_admin = true));

CREATE POLICY "Allow users to delete their own comments"
  ON blog.comments
  FOR DELETE
  USING (user_id = auth.uid() OR 
         EXISTS (SELECT 1 FROM api.profiles WHERE id = auth.uid() AND is_admin = true));

-- Create function to generate slug from title
CREATE OR REPLACE FUNCTION blog.generate_slug(title TEXT)
RETURNS TEXT AS $$
DECLARE
  slug TEXT;
BEGIN
  -- Convert to lowercase, replace spaces with hyphens, remove special characters
  slug := lower(title);
  slug := regexp_replace(slug, '[^a-z0-9\s]', '', 'g');
  slug := regexp_replace(slug, '\s+', '-', 'g');
  
  RETURN slug;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = blog, public, pg_temp; 