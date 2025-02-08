import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { FaucetForm } from "./faucet-form";

export default function FaucetPage() {
  return (
    <div className="container mx-auto p-4 max-w-lg">
      <Card>
        <CardHeader>
          <CardTitle>USDY Faucet</CardTitle>
          <CardDescription>
            Get test USDY tokens for the demo. You can request between 0.01 and
            5000 USDY.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <FaucetForm />
        </CardContent>
      </Card>
    </div>
  );
}
