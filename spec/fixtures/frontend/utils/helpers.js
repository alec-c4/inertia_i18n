import { t } from 'i18next';

export function getJsMessage() {
  return t('javascript.message');
}

export const dynamicMessage = (type) => {
  return t(`javascript.dynamic.${type}`);
};
