import { NextResponse } from "next/server";

export const runtime = "edge";

export async function POST(req: Request) {
  // CORS headers
  const headers = new Headers({
    "Access-Control-Allow-Origin": "http://localhost:3000",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  });

  // Handle preflight requests
  if (req.method === "OPTIONS") {
    return new NextResponse(null, { headers });
  }

  try {
    const rpcUrl = process.env.NEXT_PUBLIC_RPC_URL;
    if (!rpcUrl) {
      throw new Error("RPC URL not configured");
    }

    // Forward the request body to the RPC endpoint
    const response = await fetch(rpcUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(await req.json()),
    });

    const data = await response.json();

    // Return the RPC response with CORS headers
    return NextResponse.json(data, { headers });
  } catch (error) {
    console.error("RPC proxy error:", error);
    return NextResponse.json(
      { error: "Internal Server Error" },
      { status: 500, headers }
    );
  }
}
