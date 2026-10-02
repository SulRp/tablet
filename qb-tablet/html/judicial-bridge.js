window.addEventListener('message', async (event) => {
  const message = event.data;
  const frame = document.getElementById('app-frame');
  if (event.source !== frame.contentWindow || activeApp !== 'judicial') return;

  if (message?.type === 'qbTablet:requestJudicialCases' && message.id === 'judicial') {
    const result = await nui('judicialCases');
    event.source.postMessage({ type: 'qbTablet:judicialCases', id: 'judicial', result }, '*');
  }

  if (message?.type === 'qbTablet:createJudicialCase' && message.id === 'judicial') {
    const result = await nui('createJudicialCase', message.data || {});
    event.source.postMessage({ type: 'qbTablet:judicialCreated', id: 'judicial', result }, '*');
  }
});
