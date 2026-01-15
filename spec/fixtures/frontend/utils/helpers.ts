import { t } from 'i18next';

export function getTsMessage(): string {
  return t('typescript.message');
}

export const dynamicTsMessage = (type: string): string => {
  return t(`typescript.dynamic.${type}`);
};
