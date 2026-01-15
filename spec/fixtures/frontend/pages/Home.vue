<template>
  <div>
    <h1>{{ t('common.hello') }}</h1>
    <p>{{ t('common.goodbye') }}</p>
    <span>{{ t(`status.${currentStatus}`) }}</span>
  </div>
</template>

<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
const welcomeMessage = t('common.hello');
const currentStatus = 'done';
</script>
