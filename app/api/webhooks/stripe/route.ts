import { headers } from 'next/headers'
import Stripe from 'stripe'
import { NextResponse } from 'next/server'
import { stripe } from '@/lib/stripe/utils'
import { createClient } from '@/lib/supabase/server'

export async function POST(req: Request) {
  const body = await req.text()
  const signature = headers().get('Stripe-Signature') as string

  let event: Stripe.Event

  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    )
  } catch (error: any) {
    return new NextResponse(`Webhook Error: ${error.message}`, { status: 400 })
  }

  const supabase = createClient()

  // Handle the event
  switch (event.type) {
    case 'checkout.session.completed':
      const session = event.data.object as Stripe.Checkout.Session
      
      // Update user subscription status in Supabase
      if (session?.metadata?.userId) {
        const { error } = await supabase
          .from('subscriptions')
          .upsert({
            user_id: session.metadata.userId,
            stripe_customer_id: session.customer as string,
            stripe_subscription_id: session.subscription as string,
            status: 'active',
            price_id: session.metadata.priceId,
            plan: session.metadata.plan,
          })

        if (error) {
          console.error('Error updating subscription:', error)
          return new NextResponse('Error updating subscription', { status: 500 })
        }
      }
      break

    case 'customer.subscription.updated':
    case 'customer.subscription.deleted':
      const subscription = event.data.object as Stripe.Subscription
      
      // Find the customer in your database
      const { data: subscriptionData } = await supabase
        .from('subscriptions')
        .select('*')
        .eq('stripe_subscription_id', subscription.id)
        .single()

      if (subscriptionData) {
        const { error } = await supabase
          .from('subscriptions')
          .update({
            status: subscription.status,
            // Add more fields you might want to update
          })
          .eq('stripe_subscription_id', subscription.id)

        if (error) {
          console.error('Error updating subscription status:', error)
          return new NextResponse('Error updating subscription status', { status: 500 })
        }
      }
      break

    default:
      console.log(`Unhandled event type: ${event.type}`)
  }

  return new NextResponse(JSON.stringify({ received: true }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  })
} 