/**
 * Use `pnpm theme:generate-icons` to generate icons components
 * from the svg files `svg-sources` folder
 * to the `icons-generated` folder
 */
const comment =
  '// Autogenerated file, DO NOT MODIFY or it will be overwritten';

const template = (variables, { tpl }) => {
  const componentName = variables.componentName.replace('Svg', '');
  return tpl`
${comment}
${variables.imports};

import { forwardRef } from '@chakra-ui/react';

import { Icon, IconProps } from '..';

${variables.interfaces};

const Svg = (${variables.props}) => (
  ${variables.jsx}
);

const ${componentName} = forwardRef((props: Omit<IconProps, 'icon'>, ref) => {
  return <Icon ref={ref} icon={Svg} {...props} />;
});

export default ${componentName};
`;
};

module.exports = template;
