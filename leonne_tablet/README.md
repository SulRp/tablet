# leonne_tablet

Tablet NUI para QBCore, `ox_inventory` e integrações selecionadas da base Reborn/Creative. Apps instalados e seus dados ficam nos metadados de cada unidade física do tablet.

## Instalação

1. Copie `leonne_tablet` para `resources/[ Reborn ]/`.
2. Inicie `qb-core`, `ox_lib`, `ox_inventory` e `vrp` antes do tablet. Os recursos `will_homes` e `will_garages_v2` precisam estar iniciados para as integrações de Casas e Garagem. Para o app Judicial, inicie também `leonne_judicial` antes do tablet.
3. Adicione `ensure leonne_judicial` e depois `ensure leonne_tablet` ao `server.cfg`.
4. Registre o item em `ox_inventory/data/items.lua`:

```lua
['tablet'] = {
    label = 'Tablet',
    weight = 1000,
    stack = false,
    close = true,
    consume = 0,
    client = { export = 'leonne_tablet.useTablet' }
},
```

5. Reinicie `ox_inventory` e `leonne_tablet`, depois use o item.

## Apps

Notas, Calculadora, Contatos, Clima e GOV vêm instalados. O GOV consulta os dados de identidade do personagem e os veículos registrados. Os outros sete apps ficam disponíveis para baixar na Loja e começam desinstalados:

- **Casas** (`will_homes`): lista imóveis do jogador e marca no mapa.
- **Garagem** (`will_garages_v2`): lista veículos, placa e estado. O spawn continua pelo fluxo original da garagem, pois o cliente enviado está ofuscado e não expõe API pública de spawn.
- **Organizações** (`ld_orgs_v2`): atalho informativo para o painel existente. Esse recurso não expõe um ponto de abertura pública para o NUI do tablet.
- **Spotify** (`ld_spotify`): botão que fecha o tablet e executa o comando configurado em `Config.LaunchCommands.spotify` (`som` por padrão).
- **Bate-ponto** (`will_bateponto`): app informativo; o recurso valida o grupo no ponto físico configurado e não oferece API remota pública.
- **Empregos** (`will_jobs`): botão que fecha o tablet e executa `Config.LaunchCommands.jobs` (`jobs` por padrão). O recurso só registra esse comando quando `Config.debug` está ativo.
- **Judicial** (`leonne_judicial`): advogados autorizados podem abrir e consultar processos pelo tablet. O recurso judicial continua responsável por validar a permissão, salvar os registros e enviar os avisos ao Discord.

O tablet mantém QBCore e ox_inventory para abrir e salvar o aparelho. Para as integrações dos recursos Reborn, o vRP deve estar iniciado para resolver o `user_id` do personagem.

## Adicionar um app

1. Crie `apps/<nome>/index.html`; inclua `style.css` e `app.js` se precisar.
2. Registre o app em `Config.Apps` em `config.lua`:

```lua
{ id='example', label='Exemplo', description='Meu aplicativo.', icon='📱', folder='example', defaultInstalled=false }
```

Para usar uma imagem no lugar do emoji, adicione `iconImage`, por exemplo `iconImage='apps/example/icon.png'`, e coloque `icon.png` na pasta do app. PNG, WebP e SVG são aceitos; o campo `icon` continua como fallback se a imagem não carregar.

3. Reinicie `leonne_tablet`. O `fxmanifest.lua` inclui as pastas `apps/**` e o app aparece na Loja.

Para salvar dados no próprio tablet, o app escuta a mensagem `qbTablet:init` e envia alterações ao NUI pai:

```js
window.addEventListener('message', (event) => {
  if (event.data.type === 'qbTablet:init') {
    // event.data.data contém os dados salvos neste aparelho.
  }
});
window.parent.postMessage({
  type: 'qbTablet:save', id: 'example', data: { value: 'texto' }
}, '*');
```

Os IDs devem ser únicos. Cada app pode salvar até 12 KB no metadado do tablet. Não coloque segredos do servidor nesses dados. Se um tablet for duplicado copiando seus metadados, a cópia também terá o mesmo conteúdo.
