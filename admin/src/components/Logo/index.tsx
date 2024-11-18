import { ComponentProps } from 'react';

import { Image } from '@chakra-ui/react';

export const Logo = ({}: ComponentProps<typeof Image>) => {
  return (
    <Image src="/ring0logo.png" alt="ring-0 logo" />

  );
};
