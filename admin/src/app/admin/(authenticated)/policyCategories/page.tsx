"use client";

import { Suspense } from "react";

import PageAdminPolicyCategories from "@/features/policyCategories/PageAdminPolicyCategories";

export default function Page() {
  return (
    <Suspense>
      <PageAdminPolicyCategories />
    </Suspense>
  );
}
