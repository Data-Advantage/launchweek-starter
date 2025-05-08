-- Create profiles table in the api schema
CREATE TABLE api.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  website TEXT,
  company TEXT,
  job_title TEXT,
  is_admin BOOLEAN DEFAULT FALSE,
  has_verified_email BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE api.profiles ENABLE ROW LEVEL SECURITY;

-- Create policies (only the owner can update their profile)
CREATE POLICY "Allow individuals to read all profiles"
  ON api.profiles
  FOR SELECT
  USING (true);

CREATE POLICY "Allow individuals to update their own profile"
  ON api.profiles
  FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Allow individuals to insert their own profile"
  ON api.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Create function to handle user creation
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user creation
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user(); 