export async function getRates(zip: string) {
  const res = await fetch(`https://api.shipfast.example/v2/rates?zip=${zip}`);
  const body = await res.json();
  return body.rates as Array<{ carrier: string; amountCents: number }>;
}

export async function trackPackage(id: string) {
  return fetch(`https://api.shipfast.example/v2/track/${id}`)
    .then((r) => r.json())
    .catch(() => null);
}
