<script lang='ts'>
  import { t } from '@/lib/i18n.svelte';

  const welcomeMessage = t('common.hello');
  const currentStatus = 'done';
</script>

<h1>{t('common.hello')}</h1>
<p>{t('common.goodbye')}</p>
<span>{t(`status.${currentStatus}`)}</span>
