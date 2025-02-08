import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { TenantData } from "@/lib/types";

export function PaymentHistory({ tenantData }: { tenantData: TenantData }) {
  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Date</TableHead>
          <TableHead>Amount</TableHead>
          <TableHead>Status</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {tenantData.paymentHistory.map((payment) => (
          <TableRow key={payment.id}>
            <TableCell>{payment.date}</TableCell>
            <TableCell>${payment.amount}</TableCell>
            <TableCell>{payment.status}</TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
