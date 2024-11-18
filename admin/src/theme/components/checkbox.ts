import { checkboxAnatomy } from '@chakra-ui/anatomy';
import { createMultiStyleConfigHelpers } from '@chakra-ui/react';

const { defineMultiStyleConfig } = createMultiStyleConfigHelpers(
  checkboxAnatomy.keys
);

export const checkboxTheme = defineMultiStyleConfig({
  defaultProps: {
    colorScheme: 'brand',
  },
});
