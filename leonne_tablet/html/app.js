const resource = 'leonne_tablet';
let catalog = [], state = {}, activeApp = null;
const $ = (id) => document.getElementById(id);
const nui = (name, data = {}) => fetch(`https://${resource}/${name}`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json; charset=UTF-8' },
  body: JSON.stringify(data)
}).then((response) => response.json());

function show(id) {
  document.querySelectorAll('.screen').forEach((screen) => screen.classList.add('hidden'));
  $(id).classList.remove('hidden');
}

function installedApps() {
  return catalog.filter((app) => !app.core && state.installed?.[app.id]);
}

function populateIcon(container, app) {
  if (app.iconImage) {
    const image = document.createElement('img');
    image.className = 'app-icon-image';
    image.src = `https://cfx-nui-${resource}/${app.iconImage}`;
    image.alt = app.label;
    image.onerror = () => {
      image.remove();
      container.textContent = app.icon || '▣';
    };
    container.append(image);
  } else {
    container.textContent = app.icon || '▣';
  }
}

function render() {
  const grid = $('home-grid'), dock = $('dock');
  grid.innerHTML = '';
  dock.innerHTML = '';
  installedApps().forEach((app) => {
    const button = document.createElement('button');
    button.className = 'app-tile';
    const icon = document.createElement('span');
    icon.className = 'app-icon';
    populateIcon(icon, app);
    const label = document.createElement('span');
    label.textContent = app.label;
    button.append(icon, label);
    button.onclick = () => launch(app);
    grid.append(button);

    const dockButton = document.createElement('button');
    dockButton.title = app.label;
    populateIcon(dockButton, app);
    dockButton.onclick = () => launch(app);
    dock.append(dockButton);
  });
  $('app-count').textContent = installedApps().length;

  const list = $('store-list');
  list.innerHTML = '';
  catalog.filter((app) => !app.core).forEach((app) => {
    const row = document.createElement('div');
    row.className = 'store-item';
    const icon = document.createElement('div');
    icon.className = 'app-icon';
    populateIcon(icon, app);
    const info = document.createElement('div');
    info.className = 'store-info';
    const title = document.createElement('b'), description = document.createElement('small');
    title.textContent = app.label;
    description.textContent = app.description || '';
    info.append(title, description);
    const button = document.createElement('button');
    const active = !!state.installed?.[app.id];
    button.textContent = active ? 'Remover' : 'Instalar';
    button.classList.toggle('remove', active);
    button.onclick = () => toggle(app, active);
    row.append(icon, info, button);
    list.append(row);
  });
}

function launch(app) {
  if (app.id === 'store') { show('store'); return; }
  if (app.id === 'settings') { show('settings'); return; }
  activeApp = app.id;
  $('app-title').textContent = app.label;
  const frame = $('app-frame');
  frame.src = `https://cfx-nui-${resource}/${app.url}`;
  frame.onload = () => frame.contentWindow.postMessage({ type: 'qbTablet:init', data: state.data?.[activeApp] || {} }, '*');
  show('app-view');
}

async function toggle(app, active) {
  const result = await nui('save', { action: active ? 'remove' : 'install', id: app.id });
  if (result.ok) { state = result.state; render(); }
}

$('home-store').onclick = () => show('store');
$('close').onclick = () => nui('close');
$('app-back').onclick = () => { $('app-frame').src = 'about:blank'; activeApp = null; show('home'); };
document.querySelectorAll('[data-home]').forEach((button) => button.onclick = () => show('home'));

window.addEventListener('message', async (event) => {
  const message = event.data;
  if (message.action === 'open') {
    catalog = message.apps;
    state = message.state;
    render();
    $('tablet').classList.remove('hidden');
  }
  if (message.action === 'close') {
    $('tablet').classList.add('hidden');
    $('app-frame').src = 'about:blank';
    activeApp = null;
  }
  if (event.source !== $('app-frame').contentWindow) return;
  if (message.type === 'qbTablet:save' && message.id === activeApp) {
    const result = await nui('save', { action: 'data', id: message.id, value: message.data });
    if (result.ok) state = result.state;
  }
  if (message.type === 'qbTablet:requestIntegration' && message.id === activeApp) {
    const result = await nui('integrationData', { id: message.id });
    $('app-frame').contentWindow.postMessage({ type: 'qbTablet:integration', id: message.id, result }, '*');
  }
  if (message.type === 'qbTablet:markLocation' && message.id === activeApp) {
    await nui('markLocation', { x: message.x, y: message.y });
  }
  if (message.type === 'qbTablet:launchResource' && message.id === activeApp) {
    await nui('launchResource', { id: message.id });
  }
});

window.addEventListener('keydown', (event) => { if (event.key === 'Escape') nui('close'); });
setInterval(() => $('clock').textContent = new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }), 10000);
