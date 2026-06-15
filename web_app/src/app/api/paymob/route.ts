import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const { parentEnrollmentId, amount, customerInfo, paymentMethod } = await request.json();

    const apiKey = process.env.PAYMOB_API_KEY;
    const integrationId =
      paymentMethod === 'wallet'
        ? Number(process.env.PAYMOB_WALLET_INTEGRATION_ID)
        : Number(process.env.PAYMOB_INTEGRATION_ID);

    const iframeId = Number(process.env.PAYMOB_IFRAME_ID);

    if (!apiKey || !integrationId) {
      return NextResponse.json(
        { error: 'Paymob configuration is missing on server.' },
        { status: 500 }
      );
    }

    // Step 1: Authentication Token
    const authResponse = await fetch('https://accept.paymob.com/api/auth/tokens', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ api_key: apiKey }),
    });
    const authData = await authResponse.json();
    const token = authData.token;

    if (!token) {
      return NextResponse.json({ error: 'Authentication failed with Paymob' }, { status: 400 });
    }

    // Step 2: Order Registration
    // Amount must be in cents (EGP * 100)
    const amountInCents = Math.round(Number(amount) * 100);

    const orderResponse = await fetch('https://accept.paymob.com/api/ecommerce/orders', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        auth_token: token,
        delivery_needed: 'false',
        amount_cents: amountInCents,
        currency: 'EGP',
        merchant_order_id: parentEnrollmentId, // Link to Supabase parent enrollment id
        items: [],
      }),
    });
    const orderData = await orderResponse.json();
    const orderId = orderData.id;

    if (!orderId) {
      return NextResponse.json({ error: 'Order registration failed with Paymob' }, { status: 400 });
    }

    // Step 3: Payment Key Request
    const paymentKeyResponse = await fetch(
      'https://accept.paymob.com/api/acceptance/payment_keys',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          auth_token: token,
          amount_cents: amountInCents,
          expiration: 3600,
          order_id: orderId,
          billing_data: {
            apartment: 'NA',
            email: customerInfo.email || 'guest@example.com',
            floor: 'NA',
            first_name: customerInfo.name?.split(' ')[0] || 'Student',
            street: 'NA',
            building: 'NA',
            phone_number: customerInfo.phone || '+201000000000',
            shipping_method: 'PKG',
            postal_code: 'NA',
            city: 'Cairo',
            country: 'EG',
            last_name: customerInfo.name?.split(' ').slice(1).join(' ') || 'User',
            state: 'Cairo',
          },
          currency: 'EGP',
          integration_id: integrationId,
        }),
      }
    );
    const paymentKeyData = await paymentKeyResponse.json();
    const paymentToken = paymentKeyData.token;

    if (!paymentToken) {
      return NextResponse.json({ error: 'Payment key retrieval failed' }, { status: 400 });
    }

    // Step 4: Handle Mobile Wallet or Card
    if (paymentMethod === 'wallet') {
      // For mobile wallets, we need to request the redirection URL directly from Paymob
      const walletResponse = await fetch(
        'https://accept.paymob.com/api/acceptance/void_payments/pay',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            source: {
              identifier: customerInfo.walletNumber || customerInfo.phone || '01000000000',
              subtype: 'WALLET',
            },
            payment_token: paymentToken,
          }),
        }
      );
      const walletData = await walletResponse.json();
      
      return NextResponse.json({
        type: 'wallet',
        redirectUrl: walletData.iframe_redirection_url || walletData.redirection_url,
      });
    }

    // For cards, we build the iframe URL
    const cardRedirectUrl = `https://accept.paymob.com/api/acceptance/iframes/${iframeId}?payment_token=${paymentToken}`;
    
    return NextResponse.json({
      type: 'card',
      redirectUrl: cardRedirectUrl,
    });
  } catch (err: unknown) {
    console.error('Paymob Server Integration Error:', err);
    const message = err instanceof Error ? err.message : 'Internal Server Error';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
