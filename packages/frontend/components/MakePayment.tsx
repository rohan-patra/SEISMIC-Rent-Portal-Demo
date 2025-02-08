"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { TenantData } from "@/lib/types";

export function MakePayment({ tenantData }: { tenantData: TenantData }) {
  const [amount, setAmount] = useState(tenantData.rentAmount.toString());

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Here you would typically handle the payment submission
    alert(`Payment of $${amount} submitted`);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <Label htmlFor="amount">Payment Amount</Label>
        <Input
          id="amount"
          type="number"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          min="0"
          step="0.01"
          required
        />
      </div>
      <Button type="submit">Make Payment</Button>
    </form>
  );
}
