/**
 * Formats time in seconds to a human-readable format with localized units.
 * Example: 172800 => "2 Day 0 Hr" (in English) or "2 Ngày 0 Giờ" (in Vietnamese)
 *
 * @param {number} timeInSeconds - The time in seconds to format.
 * @param {function} t - The translation function ($t).
 * @returns {string} The formatted duration string.
 */
export const formatTime = (timeInSeconds, t) => {
  if (timeInSeconds === undefined || timeInSeconds === null) return '';

  const days = Math.floor(timeInSeconds / 86400);
  const hours = Math.floor((timeInSeconds % 86400) / 3600);
  const minutes = Math.floor((timeInSeconds % 3600) / 60);
  const seconds = Math.floor(timeInSeconds % 60);

  if (days > 0) {
    return `${days} ${t('REPORT_TIME_UNITS.DAY')} ${hours} ${t('REPORT_TIME_UNITS.HOUR')}`;
  }
  if (hours > 0) {
    return `${hours} ${t('REPORT_TIME_UNITS.HOUR')} ${minutes} ${t('REPORT_TIME_UNITS.MINUTE')}`;
  }
  if (minutes > 0) {
    return `${minutes} ${t('REPORT_TIME_UNITS.MINUTE')} ${seconds} ${t('REPORT_TIME_UNITS.SECOND')}`;
  }
  return `${seconds} ${t('REPORT_TIME_UNITS.SECOND')}`;
};
