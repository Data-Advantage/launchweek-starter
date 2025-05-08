export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      // Public schema tables (if any)
    }
    Views: {
      subscription_status: {
        Row: {
          user_id: string
          email: string | null
          subscription_id: string | null
          status: Database["reference"]["Enums"]["subscription_status"] | null
          price_id: string | null
          product_id: string | null
          unit_amount: number | null
          interval: string | null
          currency: string | null
          product_name: string | null
          current_period_end: string | null
          cancel_at_period_end: boolean | null
        }
      }
    }
    Functions: {
      user_has_active_subscription: {
        Args: {
          user_uuid: string
        }
        Returns: boolean
      }
      handle_timestamps: {
        Args: Record<string, never>
        Returns: unknown 
      }
    }
    Enums: {
      // subscription_status moved to reference
    }
  }
  reference: {
    Tables: {}
    Views: {}
    Functions: {}
    Enums: {
      subscription_status: 
        | "trialing"
        | "active"
        | "canceled"
        | "incomplete"
        | "incomplete_expired"
        | "past_due"
        | "unpaid"
        | "paused"
    }
  }
  api: {
    Tables: {
      profiles: {
        Row: {
          id: string
          email: string
          full_name: string | null
          avatar_url: string | null
          website: string | null
          company: string | null
          job_title: string | null
          is_admin: boolean
          has_verified_email: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          email: string
          full_name?: string | null
          avatar_url?: string | null
          website?: string | null
          company?: string | null
          job_title?: string | null
          is_admin?: boolean
          has_verified_email?: boolean
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          email?: string
          full_name?: string | null
          avatar_url?: string | null
          website?: string | null
          company?: string | null
          job_title?: string | null
          is_admin?: boolean
          has_verified_email?: boolean
          created_at?: string
          updated_at?: string
        }
      }
    }
    Views: {
      // Views in api schema
    }
    Functions: {
      get_current_user_profile: {
        Args: Record<string, never>
        Returns: Database["api"]["Tables"]["profiles"]["Row"][]
      }
      is_admin: {
        Args: Record<string, never>
        Returns: boolean
      }
      get_user_subscription: { 
        Args: { user_uuid?: string | null }
        Returns: {
          subscription_id: string | null
          status: string | null
          product_id: string | null
          product_name: string | null
          price_id: string | null
          interval: string | null
          amount: number | null
          currency: string | null
          is_active: boolean | null
          current_period_end: string | null
          cancel_at_period_end: boolean | null
        }[]
      }
      get_user_credits: { 
        Args: { user_uuid?: string | null }
        Returns: {
          total_credits: number | null
          remaining_credits: number | null
          updated_at: string | null
        }[]
      }
    }
    Enums: {
      // Enums in api schema
    }
  }
  stripe: {
    Tables: {
      products: {
        Row: {
          id: string
          active: boolean | null
          name: string | null
          description: string | null
          image: string | null
          metadata: Json | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          active?: boolean | null
          name?: string | null
          description?: string | null
          image?: string | null
          metadata?: Json | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          active?: boolean | null
          name?: string | null
          description?: string | null
          image?: string | null
          metadata?: Json | null
          created_at?: string
          updated_at?: string
        }
      }
      prices: {
        Row: {
          id: string
          product_id: string | null
          active: boolean | null
          currency: string | null
          description: string | null
          type: string | null
          unit_amount: number | null
          interval: string | null
          interval_count: number | null
          trial_period_days: number | null
          metadata: Json | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          product_id?: string | null
          active?: boolean | null
          currency?: string | null
          description?: string | null
          type?: string | null
          unit_amount?: number | null
          interval?: string | null
          interval_count?: number | null
          trial_period_days?: number | null
          metadata?: Json | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          product_id?: string | null
          active?: boolean | null
          currency?: string | null
          description?: string | null
          type?: string | null
          unit_amount?: number | null
          interval?: string | null
          interval_count?: number | null
          trial_period_days?: number | null
          metadata?: Json | null
          created_at?: string
          updated_at?: string
        }
      }
      customers: {
        Row: {
          id: string
          user_id: string
          email: string | null
          name: string | null
          phone: string | null
          address: Json | null
          metadata: Json | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          user_id: string
          email?: string | null
          name?: string | null
          phone?: string | null
          address?: Json | null
          metadata?: Json | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          email?: string | null
          name?: string | null
          phone?: string | null
          address?: Json | null
          metadata?: Json | null
          created_at?: string
          updated_at?: string
        }
      }
      subscriptions: {
        Row: {
          id: string
          user_id: string
          customer_id: string | null
          status: Database["reference"]["Enums"]["subscription_status"] | null
          price_id: string | null
          quantity: number | null
          cancel_at_period_end: boolean | null
          cancel_at: string | null
          canceled_at: string | null
          current_period_start: string | null
          current_period_end: string | null
          ended_at: string | null
          trial_start: string | null
          trial_end: string | null
          metadata: Json | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          user_id: string
          customer_id?: string | null
          status?: Database["reference"]["Enums"]["subscription_status"] | null
          price_id?: string | null
          quantity?: number | null
          cancel_at_period_end?: boolean | null
          cancel_at?: string | null
          canceled_at?: string | null
          current_period_start?: string | null
          current_period_end?: string | null
          ended_at?: string | null
          trial_start?: string | null
          trial_end?: string | null
          metadata?: Json | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          customer_id?: string | null
          status?: Database["reference"]["Enums"]["subscription_status"] | null
          price_id?: string | null
          quantity?: number | null
          cancel_at_period_end?: boolean | null
          cancel_at?: string | null
          canceled_at?: string | null
          current_period_start?: string | null
          current_period_end?: string | null
          ended_at?: string | null
          trial_start?: string | null
          trial_end?: string | null
          metadata?: Json | null
          created_at?: string
          updated_at?: string
        }
      }
      webhook_events: { 
        Row: {
          id: string
          type: string
          api_version: string | null
          created: string | null
          data: Json | null
          processing_status: string | null
          processing_error: string | null
          processing_attempts: number | null
          processed_at: string | null
          received_at: string | null
        }
        Insert: {
          id: string
          type: string
          api_version?: string | null
          created?: string | null
          data?: Json | null
          processing_status?: string | null
          processing_error?: string | null
          processing_attempts?: number | null
          processed_at?: string | null
          received_at?: string | null
        }
        Update: {
          id?: string
          type?: string
          api_version?: string | null
          created?: string | null
          data?: Json | null
          processing_status?: string | null
          processing_error?: string | null
          processing_attempts?: number | null
          processed_at?: string | null
          received_at?: string | null
        }
      }
    }
    Views: {
      // Views in stripe schema
    }
    Functions: {
      create_or_update_customer: {
        Args: {
          user_id: string
          customer_data: Json
        }
        Returns: string
      }
      process_webhook_event: { 
        Args: { event_id: string }
        Returns: boolean
      }
    }
    Enums: {
      // Enums in stripe schema
    }
  }
  blog: {
    Tables: {
      categories: {
        Row: {
          id: string
          name: string
          slug: string
          description: string | null
          parent_id: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          slug: string
          description?: string | null
          parent_id?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          slug?: string
          description?: string | null
          parent_id?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      posts: {
        Row: {
          id: string
          title: string
          slug: string
          excerpt: string | null
          content: string
          featured_image: string | null
          author_id: string | null
          category_id: string | null
          status: string
          meta_title: string | null
          meta_description: string | null
          published_at: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          title: string
          slug: string
          excerpt?: string | null
          content: string
          featured_image?: string | null
          author_id?: string | null
          category_id?: string | null
          status?: string
          meta_title?: string | null
          meta_description?: string | null
          published_at?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          title?: string
          slug?: string
          excerpt?: string | null
          content?: string
          featured_image?: string | null
          author_id?: string | null
          category_id?: string | null
          status?: string
          meta_title?: string | null
          meta_description?: string | null
          published_at?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      tags: {
        Row: {
          id: string
          name: string
          slug: string
          description: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          slug: string
          description?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          slug?: string
          description?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      post_tags: {
        Row: {
          post_id: string
          tag_id: string
        }
        Insert: {
          post_id: string
          tag_id: string
        }
        Update: {
          post_id?: string
          tag_id?: string
        }
      }
      comments: {
        Row: {
          id: string
          post_id: string
          user_id: string
          parent_id: string | null
          content: string
          is_approved: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          post_id: string
          user_id: string
          parent_id?: string | null
          content: string
          is_approved?: boolean
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          post_id?: string
          user_id?: string
          parent_id?: string | null
          content?: string
          is_approved?: boolean
          created_at?: string
          updated_at?: string
        }
      }
    }
    Views: {
      // Views in blog schema
    }
    Functions: {
      generate_slug: {
        Args: {
          title: string
        }
        Returns: string
      }
      get_posts: {
        Args: {
          _limit?: number
          _offset?: number
          _status?: string
          _category_slug?: string
          _tag_slug?: string
          _search?: string
        }
        Returns: {
          id: string
          title: string
          slug: string
          excerpt: string | null
          content: string
          featured_image: string | null
          author_id: string | null
          author_name: string | null
          author_avatar: string | null
          category_id: string | null
          category_name: string | null
          category_slug: string | null
          status: string
          tags: Json
          published_at: string | null
          created_at: string
          updated_at: string
          total_count: number
        }[]
      }
    }
    Enums: {
      // Enums in blog schema
    }
  }
  internal: {
    Tables: {
      user_credits: {
        Row: {
          id: string
          user_id: string
          total_credits: number
          remaining_credits: number
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          total_credits: number
          remaining_credits: number
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          total_credits?: number
          remaining_credits?: number
          updated_at?: string
        }
      }
      credit_transactions: {
        Row: {
          id: string
          user_id: string
          amount: number
          transaction_type: string
          description: string | null
          payment_id: string | null
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          amount: number
          transaction_type: string
          description?: string | null
          payment_id?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          amount?: number
          transaction_type?: string
          description?: string | null
          payment_id?: string | null
          created_at?: string
        }
      }
    }
    Views: {}
    Functions: {}
    Enums: {}
  }
  config: {
    Tables: {
      subscription_benefits: {
        Row: {
          id: string
          product_id: string | null
          feature_limits: Json
          has_premium_features: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          product_id?: string | null
          feature_limits: Json
          has_premium_features: boolean
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          product_id?: string | null
          feature_limits?: Json
          has_premium_features?: boolean
          created_at?: string
          updated_at?: string
        }
      }
      credit_packs: {
        Row: {
          id: string
          product_id: string | null
          credits_amount: number
          bonus_credits: number
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          product_id?: string | null
          credits_amount: number
          bonus_credits?: number
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          product_id?: string | null
          credits_amount?: number
          bonus_credits?: number
          created_at?: string
          updated_at?: string
        }
      }
    }
    Views: {}
    Functions: {}
    Enums: {}
  }
} 