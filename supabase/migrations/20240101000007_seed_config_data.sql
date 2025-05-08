-- Seed subscription benefits
INSERT INTO config.subscription_benefits (product_id, feature_limits, has_premium_features) VALUES
('prod_starter', '{"api_calls_per_day": 100, "storage_gb": 5, "projects": 3}', false),
('prod_professional', '{"api_calls_per_day": 1000, "storage_gb": 20, "projects": 10}', true),
('prod_enterprise', '{"api_calls_per_day": 10000, "storage_gb": 100, "projects": -1}', true); -- -1 means unlimited

-- Seed credit packs
INSERT INTO config.credit_packs (product_id, credits_amount, bonus_credits) VALUES
('prod_starter', 100, 0),
('prod_professional', 1000, 100),
('prod_enterprise', 10000, 2000);

-- Create storage buckets (only runs when executed via Supabase interface or CLI, not in direct SQL)
-- COMMENT OUT THESE LINES IF RUNNING DIRECTLY VIA SQL EDITOR
-- CREATE STORAGE BUCKET public (public);
-- CREATE STORAGE BUCKET protected (private);
-- CREATE STORAGE BUCKET private (private);

-- Storage RLS policies (uncomment and run separately if needed)
/*
-- Public bucket policies (anyone can view, only authenticated users can upload)
CREATE POLICY "Public Access"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'public');

CREATE POLICY "Authenticated users can upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'public' 
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "Users can update their own objects"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'public'
    AND auth.uid() = owner
  );

CREATE POLICY "Users can delete their own objects"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'public'
    AND auth.uid() = owner
  );

-- Protected bucket policies (only authenticated users can view/upload)
CREATE POLICY "Only authenticated users can view"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'protected'
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "Only authenticated users can upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'protected'
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "Users can update their own objects in protected bucket"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'protected'
    AND auth.uid() = owner
  );

CREATE POLICY "Users can delete their own objects in protected bucket"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'protected'
    AND auth.uid() = owner
  );

-- Private bucket policies (users can only access their own files)
CREATE POLICY "Users can access only their own folder"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'private'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can upload only to their own folder"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'private'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can update only their own files"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'private'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete only their own files"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'private'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
*/ 