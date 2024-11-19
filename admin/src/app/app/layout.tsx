import { ReactNode } from 'react';

import { NextLoader } from '@/app/NextLoader';

export default function AppLayout({ children }: { children: ReactNode }) {
  return (
    <>
      <NextLoader showSpinner />
      {children}
    </>
  );
}
