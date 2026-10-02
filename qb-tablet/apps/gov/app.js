const notice = document.getElementById('notice');
const vehiclesElement = document.getElementById('vehicles');

function requestData() {
  window.parent.postMessage({ type: 'qbTablet:requestIntegration', id: 'gov' }, '*');
}

function valueOrDash(value) {
  return value === undefined || value === null || String(value).trim() === '' ? '—' : String(value);
}

function renderVehicles(items, available) {
  vehiclesElement.replaceChildren();
  if (!available) {
    const empty = document.createElement('div');
    empty.className = 'empty';
    empty.textContent = 'Consulta de veículos indisponível no momento.';
    vehiclesElement.append(empty);
    document.getElementById('vehicle-count').textContent = 'Indisponível';
    return;
  }

  const vehicles = Array.isArray(items) ? items : [];
  document.getElementById('vehicle-count').textContent = `${vehicles.length} ${vehicles.length === 1 ? 'registro' : 'registros'}`;
  if (vehicles.length === 0) {
    const empty = document.createElement('div');
    empty.className = 'empty';
    empty.textContent = 'Nenhum veículo registrado em seu nome.';
    vehiclesElement.append(empty);
    return;
  }

  for (const item of vehicles) {
    const card = document.createElement('article');
    card.className = 'vehicle-card';
    const top = document.createElement('div');
    top.className = 'vehicle-top';
    const name = document.createElement('span');
    name.className = 'vehicle-name';
    name.textContent = item.label || item.model || 'Veículo';
    const plate = document.createElement('span');
    plate.className = 'plate';
    plate.textContent = item.plate || 'SEM PLACA';
    top.append(name, plate);

    const state = document.createElement('div');
    state.className = 'vehicle-state';
    const arrested = Number(item.arrest) > 0;
    const stored = ['1', 'true', 'stored', 'sim'].includes(String(item.stored).toLowerCase());
    state.textContent = arrested ? 'Situação: apreendido' : stored ? 'Situação: na garagem' : 'Situação: em circulação';
    card.append(top, state);
    vehiclesElement.append(card);
  }
}

function renderProfile(profile) {
  const data = profile || {};
  const name = valueOrDash(data.name);
  document.getElementById('welcome-name').textContent = name === '—' ? 'Olá, cidadão' : `Olá, ${name}`;
  document.getElementById('full-name').textContent = name;
  document.getElementById('passport').textContent = valueOrDash(data.passport);
  document.getElementById('age').textContent = data.age ? `${data.age} anos` : '—';
  document.getElementById('phone').textContent = valueOrDash(data.phone);
  document.getElementById('registration').textContent = valueOrDash(data.registration);
}

document.getElementById('refresh').addEventListener('click', requestData);
window.addEventListener('message', (event) => {
  const message = event.data;
  if (message?.type !== 'qbTablet:integration' || message.id !== 'gov') return;
  const result = message.result;
  if (!result?.ok) {
    notice.textContent = 'Não foi possível consultar seus dados. Tente novamente em instantes.';
    notice.classList.remove('hidden');
    return;
  }
  notice.classList.add('hidden');
  renderProfile(result.profile);
  renderVehicles(result.vehicles, result.vehiclesAvailable);
});

requestData();
