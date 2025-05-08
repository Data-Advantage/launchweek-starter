import { Metadata } from "next"
import { LoginForm } from "@/components/auth/login-form"
import Link from "next/link"

export const metadata: Metadata = {
  title: "Login | LaunchWeek Starter",
  description: "Login to your LaunchWeek Starter account",
}

export default function LoginPage() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center px-4 py-12 sm:px-6 lg:px-8">
      <div className="w-full max-w-md">
        <div className="mb-8 flex justify-center">
          <Link href="/" className="text-2xl font-bold">
            LaunchWeek
          </Link>
        </div>
        <LoginForm />
      </div>
    </div>
  )
} 