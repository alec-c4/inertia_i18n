import React from 'react';
import { useTranslation } from 'react-i18next';

function Home() {
  const { t } = useTranslation();
  const welcomeMessage = t('common.hello');
  const currentStatus = 'done';

  return (
    <div>
      <h1>{welcomeMessage}</h1>
      <p>{t('common.goodbye')}</p>
      <span>{t(`status.${currentStatus}`)}</span>
    </div>
  );
}

export default Home;
