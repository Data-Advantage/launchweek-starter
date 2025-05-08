import { createClient } from "@/lib/supabase/server"
import { Metadata } from "next"

export const metadata: Metadata = {
  title: "Dashboard | LaunchWeek Starter",
  description: "Manage your LaunchWeek Starter projects",
}

export default async function DashboardPage() {
  const supabase = createClient()
  const { data: { user } } = await supabase.auth.getUser()

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold">Dashboard</h1>
        <p className="text-gray-500 dark:text-gray-400">
          Welcome back, {user?.email}
        </p>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {/* Stats cards */}
        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-800 dark:bg-gray-900">
          <h3 className="text-lg font-medium">Projects</h3>
          <p className="mt-2 text-3xl font-bold">0</p>
        </div>
        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-800 dark:bg-gray-900">
          <h3 className="text-lg font-medium">Active Users</h3>
          <p className="mt-2 text-3xl font-bold">0</p>
        </div>
        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-800 dark:bg-gray-900">
          <h3 className="text-lg font-medium">Revenue</h3>
          <p className="mt-2 text-3xl font-bold">$0</p>
        </div>
      </div>

      <div className="mt-12">
        <h2 className="mb-4 text-2xl font-bold">Recent Activity</h2>
        <div className="rounded-lg border border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900">
          <div className="p-6 text-center text-gray-500 dark:text-gray-400">
            No recent activity
          </div>
        </div>
      </div>
    </div>
  )
} 