const form = document.getElementById('case-form');
const casesElement = document.getElementById('cases');
const notice = document.getElementById('notice');
const summary = document.getElementById('summary');
const submit = document.getElementById('submit');

function showNotice(message, type = 'error') {
  notice.textContent = message;
  notice.className = `notice ${type}`;
}

function hideNotice() {
  notice.textContent = '';
  notice.className = 'notice hidden';
}

function requestCases() {
  window.parent.postMessage({ type: 'qbTablet:requestJudicialCases', id: 'judicial' }, '*');
}

function renderCases(items) {
  casesElement.replaceChildren();
  if (!items || items.length === 0) {
    const empty = document.createElement('div');
    empty.className = 'empty';
    empty.textContent = 'Nenhum processo registrado ainda.';
    casesElement.append(empty);
    return;
  }

  for (const item of items) {
    const card = document.createElement('article');
    card.className = 'case-card';
    const top = document.createElement('div');
    top.className = 'case-top';
    const number = document.createElement('span');
    number.className = 'case-number';
    number.textContent = `Processo #${String(item.id).padStart(6, '0')} · ${item.caseType}`;
    const badge = document.createElement('span');
    badge.className = 'badge';
    badge.textContent = item.status || 'Aberto';
    top.append(number, badge);

    const meta = document.createElement('div');
    meta.className = 'case-meta';
    const party = document.createElement('span');
    party.textContent = `Parte: ${item.party}`;
    const lawyer = document.createElement('span');
    lawyer.textContent = `Advogado: ${item.lawyerName}`;
    const date = document.createElement('span');
    const parsedDate = new Date(item.createdAt);
    date.textContent = Number.isNaN(parsedDate.getTime()) ? '' : parsedDate.toLocaleString('pt-BR');
    meta.append(party, lawyer, date);

    const description = document.createElement('p');
    description.className = 'case-summary';
    description.textContent = item.summary;
    card.append(top, meta, description);
    casesElement.append(card);
  }
}

document.getElementById('refresh').addEventListener('click', requestCases);
summary.addEventListener('input', () => {
  document.getElementById('counter').textContent = `${summary.value.length}/700`;
});

form.addEventListener('submit', (event) => {
  event.preventDefault();
  hideNotice();
  submit.disabled = true;
  window.parent.postMessage({
    type: 'qbTablet:createJudicialCase',
    id: 'judicial',
    data: {
      party: document.getElementById('party').value.trim(),
      caseType: document.getElementById('case-type').value,
      summary: summary.value.trim()
    }
  }, '*');
});

window.addEventListener('message', (event) => {
  const message = event.data;
  if (message?.type === 'qbTablet:judicialCases' && message.id === 'judicial') {
    if (message.result?.ok) renderCases(message.result.items);
    else showNotice(message.result?.error === 'no_permission'
      ? 'Apenas advogados autorizados podem consultar o sistema judicial.'
      : 'Não foi possível carregar os processos. Verifique se o recurso judicial está iniciado.');
  }

  if (message?.type === 'qbTablet:judicialCreated' && message.id === 'judicial') {
    submit.disabled = false;
    if (!message.result?.ok) {
      showNotice(message.result?.error === 'no_permission'
        ? 'Apenas advogados autorizados podem abrir processos.'
        : message.result?.error === 'save_failed'
          ? 'O processo não pôde ser salvo. Avise a administração.'
          : 'Preencha todos os campos para registrar o processo.');
      return;
    }
    form.reset();
    document.getElementById('counter').textContent = '0/700';
    showNotice(`Processo #${String(message.result.case.id).padStart(6, '0')} registrado com sucesso.`, 'success');
    requestCases();
  }
});

requestCases();
