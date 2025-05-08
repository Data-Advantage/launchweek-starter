import Link from "next/link"
import { redirect } from "next/navigation"
import { createClient } from "@/lib/supabase/server"

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const supabase = createClient()
  const { data } = await supabase.auth.getSession()

  // If the user is not logged in, redirect to the login page
  if (!data?.session) {
    redirect("/login")
  }

  return (
    <div className="flex min-h-screen flex-col">
      <header className="border-b border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900">
        <div className="container mx-auto flex h-16 items-center justify-between px-4">
          <Link href="/dashboard" className="text-xl font-bold">
            LaunchWeek
          </Link>
          <nav className="flex items-center space-x-8">
            <Link href="/dashboard" className="hover:text-blue-600 dark:hover:text-blue-400">
              Dashboard
            </Link>
            <Link href="/settings" className="hover:text-blue-600 dark:hover:text-blue-400">
              Settings
            </Link>
            <form action="/api/auth/signout" method="post">
              <button type="submit" className="hover:text-blue-600 dark:hover:text-blue-400">
                Logout
              </button>
            </form>
          </nav>
        </div>
      </header>
      <div className="flex flex-1">
        <aside className="hidden w-64 border-r border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900 lg:block">
          <div className="p-4">
            <nav className="space-y-1">
              <Link
                href="/dashboard"
                className="flex items-center rounded-md px-3 py-2 text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
              >
                Dashboard
              </Link>
              <Link
                href="/settings"
                className="flex items-center rounded-md px-3 py-2 text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
              >
                Settings
              </Link>
              <Link
                href="/billing"
                className="flex items-center rounded-md px-3 py-2 text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
              >
                Billing
              </Link>
            </nav>
          </div>
        </aside>
        <main className="flex-1 bg-gray-50 dark:bg-gray-950">{children}</main>
      </div>
    </div>
  )
} 