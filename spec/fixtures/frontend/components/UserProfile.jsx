import React from 'react';
import { useTranslation } from 'react-i18next';

function UserProfile({ userId }) {
  const { t } = useTranslation();

  return (
    <div>
      <h1>{t('react.profile_title')}</h1>
      <p>{t("react.greeting", { name: "Alex" })}</p>
      <p>{t(`react.dynamic.${userId}`)}</p>
    </div>
  );
}

export default UserProfile;
