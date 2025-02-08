import { TenantData } from "@/lib/types";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export function RentSummary({ tenantData }: { tenantData: TenantData }) {
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Current Rent</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">${tenantData.rentAmount}</div>
          <p className="text-xs text-muted-foreground">
            Due on {tenantData.dueDate}
          </p>
        </CardContent>
      </Card>
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Balance</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">${tenantData.balance}</div>
          <p className="text-xs text-muted-foreground">
            Current outstanding balance
          </p>
        </CardContent>
      </Card>
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Last Payment</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">
            ${tenantData.lastPayment.amount}
          </div>
          <p className="text-xs text-muted-foreground">
            Paid on {tenantData.lastPayment.date}
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
