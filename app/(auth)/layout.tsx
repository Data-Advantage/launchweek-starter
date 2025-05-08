import { redirect } from "next/navigation"
import { createClient } from "@/lib/supabase/server"

export default async function AuthLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const supabase = createClient()
  const { data } = await supabase.auth.getSession()

  // If the user is logged in, redirect to the dashboard
  if (data?.session) {
    redirect("/dashboard")
  }

  return <>{children}</>
} 