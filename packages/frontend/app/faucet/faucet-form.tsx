"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { toast } from "sonner";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { z } from "zod";
import {
  useAccount,
  useWaitForTransactionReceipt,
  type BaseError,
} from "wagmi";
import { useShieldedWriteContract } from "seismic-react";
import { USDYContract } from "@/lib/contracts";
import { parseEther } from "viem";
import { drip } from "./dripAction";

const formSchema = z.object({
  address: z.string().regex(/^0x[a-fA-F0-9]{40}$/, "Invalid Ethereum address"),
  amount: z.number().min(0.01).max(5000).step(0.01),
});

export type FormSchema = z.infer<typeof formSchema>;

export function FaucetForm() {
  const form = useForm<FormSchema>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      address: "",
      amount: 100,
    },
  });

  const {
    hash,
    error,
    isLoading,
    writeContract: mintUSDY,
  } = useShieldedWriteContract({
    address: USDYContract.address,
    abi: USDYContract.abi,
    functionName: "mint",
    args: [
      form.getValues("address"),
      parseEther(form.getValues("amount").toString()),
    ],
  });

  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({
      hash: hash || undefined,
    });

  const { isConnected } = useAccount();

  // function onSubmit(values: FormSchema) {
  function onSubmit() {
    try {
      // use wagmi to call the mint function on the USDY contract
      // mintUSDY();
      drip(
        form.getValues("address") as `0x${string}`,
        form.getValues("amount"),
      );

      if (isConfirmed) {
        toast.success("USDY tokens sent successfully!");
        form.reset();
      } else {
        toast.error(`An unexpected error occurred: ${error?.message}`);
      }
    } catch (error) {
      toast.error(`An unexpected error occurred: ${error}`);
    }
  }

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="address"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Ethereum Address</FormLabel>
              <FormControl>
                <Input placeholder="0x..." {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <FormField
          control={form.control}
          name="amount"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Amount of USDY</FormLabel>
              <FormControl>
                <Input
                  type="number"
                  placeholder="100"
                  min={0.01}
                  max={5000}
                  step={0.01}
                  {...field}
                  onChange={(e) => field.onChange(Number(e.target.value))}
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <Button
          type="submit"
          className="w-full"
          disabled={
            form.formState.isSubmitting ||
            isLoading ||
            !isConnected ||
            !form.formState.isValid
          }
        >
          {form.formState.isSubmitting || isLoading
            ? "Sending..."
            : "Request USDY"}
        </Button>
        {hash && (
          <div className="text-sm text-muted-foreground">
            Transaction Hash: {hash}
          </div>
        )}
        {isConfirming && (
          <div className="text-sm text-muted-foreground">
            Waiting for confirmation...
          </div>
        )}
        {isConfirmed && (
          <div className="text-sm text-muted-foreground">
            Transaction confirmed!
          </div>
        )}
        {error && (
          <div className="text-sm text-muted-foreground">
            Error: {(error as BaseError).shortMessage || error.message}
          </div>
        )}
      </form>
    </Form>
  );
}
