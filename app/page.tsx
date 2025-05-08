import Link from 'next/link'

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-gradient-to-r from-cyan-500 to-blue-500 p-8 text-white">
      <div className="container flex flex-col items-center justify-center gap-12 px-4 py-16 md:px-8 lg:max-w-5xl">
        <h1 className="text-4xl font-extrabold tracking-tight sm:text-6xl">
          LaunchWeek <span className="text-yellow-400">Starter</span>
        </h1>
        
        <p className="text-center text-lg md:text-xl lg:text-2xl">
          Build your SaaS business in just one week - no coding required.
        </p>
        
        <div className="flex gap-4">
          <Link 
            href="/signup" 
            className="rounded-full bg-white px-6 py-3 text-lg font-semibold text-blue-600 shadow-lg hover:bg-blue-50 transition-colors"
          >
            Get Started
          </Link>
          <Link 
            href="/login" 
            className="rounded-full border-2 border-white px-6 py-3 text-lg font-semibold hover:bg-white/10 transition-colors"
          >
            Login
          </Link>
        </div>
        
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {[
            {
              title: "Create",
              description: "Turn your idea into a working prototype",
            },
            {
              title: "Refine", 
              description: "Gather feedback and enhance your design",
            },
            {
              title: "Build",
              description: "Develop the complete application with all features",
            },
            {
              title: "Position",
              description: "Craft your marketing message and materials",
            },
            {
              title: "Launch",
              description: "Deploy and start your promotional campaign",
            },
          ].map((feature, index) => (
            <div 
              key={index}
              className="rounded-xl bg-white/20 p-6 backdrop-blur-sm hover:bg-white/30 transition-colors"
            >
              <h3 className="text-xl font-bold">{feature.title}</h3>
              <p className="mt-2 text-white/80">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </main>
  )
} 