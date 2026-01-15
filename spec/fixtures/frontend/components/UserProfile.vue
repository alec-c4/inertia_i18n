<template>
  <div>
    <h1>{{ t('vue.profile_title') }}</h1>
    <p v-t="'vue.greeting'"></p>
    <p>{{ t(`vue.dynamic.${userId}`) }}</p>
  </div>
</template>

<script>
import { useI18n } from 'vue-i18n';

export default {
  props: {
    userId: String,
  },
  setup() {
    const { t } = useI18n();
    // Key inside script
    console.log(t('vue.script_key'));
    return { t };
  },
};
</script>
