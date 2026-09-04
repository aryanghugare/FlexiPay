export type ProductSummary = {
  id: number; slug: string; name: string; short_description: string;
  mrpPaise: number; pricePaise: number; imageUrl: string; imageScale: number; defaultStorage: string;
};
export type Category = { id: number; slug: string; name: string; description: string; imageUrl: string; imageScale: number };

export type Variant = { id: number; label: string; ram: string; storage: string; configurationLabel: string; mrpPaise: number; pricePaise: number; colorHex: string; imageUrl: string };
export type EmiPlan = { id: number; variantId: number | null; monthlyPaymentPaise: number; tenureMonths: number; interestRateBps: number; cashbackPaise: number };
export type ProductSpecification = { id: number; label: string; value: string };
export type Product = Omit<ProductSummary, 'short_description' | 'defaultStorage'> & { shortDescription: string; variants: Variant[]; plans: EmiPlan[]; specifications: ProductSpecification[] };
