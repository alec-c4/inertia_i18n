<script>
  import { t } from '@/lib/i18n.svelte';

  export let userId;
</script>

<div>
  <h1>{t('svelte.profile_title')}</h1>
  <p>{t("svelte.greeting", { name: "Alex" })}</p>
  <p>{t(`svelte.dynamic.${userId}`)}</p>
</div>
