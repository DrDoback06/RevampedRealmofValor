String handleScan(String data) {
  if (data.startsWith('card:')) return 'card';
  if (data.startsWith('quest:')) return 'quest';
  if (data.startsWith('curse:')) return 'curse';
  return 'unknown';
}
