# Leonne Judicial

Sistema judicial integrado ao tablet: advogados registram e consultam processos no app Judicial. O canal judicial recebe um aviso pelo Discord quando um processo é aberto. Os comandos de chat também continuam disponíveis.

## Instalacao

1. Coloque `leonne_judicial` na pasta de resources.
2. Em `config.lua`, ajuste `LawyerPermission` para a permissao de advogado usada pela base.
3. Configure `DiscordWebhook` e `LawyerRoleId`.
4. Adicione `ensure leonne_judicial` ao `server.cfg` depois de iniciar `vrp` e antes de `ensure qb-tablet`.
5. Instale o app Judicial na Loja do tablet.

## Comandos

- `/processo ajuda`
- `/processo criar Parte envolvida | Tipo de processo | Resumo dos fatos`
- `/processos`

Somente jogadores com a permissao configurada no servidor podem criar e consultar processos. Os registros ficam em `processos.json` dentro do recurso. O webhook e o ID do cargo devem ser mantidos privados.

O tablet consulta o recurso judicial por exports do lado do servidor. Se ele não estiver iniciado, o app informa que o sistema está indisponível.
