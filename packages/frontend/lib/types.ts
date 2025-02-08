export type TenantData = {
  name: string;
  rentAmount: number;
  dueDate: string;
  balance: number;
  lastPayment: { amount: number; date: string };
  paymentHistory: {
    id: number;
    date: string;
    amount: number;
    status: string;
  }[];
};
