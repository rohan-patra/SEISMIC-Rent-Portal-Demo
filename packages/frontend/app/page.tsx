import { RentSummary } from "@/components/RentSummary";
import { PaymentHistory } from "@/components/PaymentHistory";
import { MakePayment } from "@/components/MakePayment";
import { TenantData } from "@/lib/types";

const tenantData: TenantData = {
  name: "Charles Richter",
  rentAmount: 1200,
  dueDate: "2024-05-01",
  balance: 0,
  lastPayment: {
    amount: 1200,
    date: "2024-04-01",
  },
  paymentHistory: [
    { id: 1, date: "2024-04-01", amount: 1200, status: "Paid" },
    { id: 2, date: "2024-03-01", amount: 1200, status: "Paid" },
    { id: 3, date: "2024-02-01", amount: 1200, status: "Paid" },
  ],
};

export default function Home() {
  return (
    <div className="container mx-auto p-4">
      <h1 className="text-3xl font-bold mb-6">Welcome, {tenantData.name}</h1>
      <div className="space-y-6">
        <section>
          <h2 className="text-2xl font-semibold mb-4">Rent Summary</h2>
          <RentSummary tenantData={tenantData} />
        </section>
        <section>
          <h2 className="text-2xl font-semibold mb-4">Payment History</h2>
          <PaymentHistory tenantData={tenantData} />
        </section>
        <section>
          <h2 className="text-2xl font-semibold mb-4">Make a Payment</h2>
          <MakePayment tenantData={tenantData} />
        </section>
      </div>
    </div>
  );
}
