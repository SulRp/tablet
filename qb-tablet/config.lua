Config = {}
Config.ItemName = 'tablet'
Config.OpenCommand = 'tablet'
Config.AppInfoKey = 'qbTablet' -- Stored on the physical item by ox_inventory.
Config.MetadataKey = Config.AppInfoKey
Config.LaunchCommands = { spotify='som', jobs='jobs' } -- Native resource commands called after closing the tablet.

-- Add each app in its own apps/<folder>/ directory and register it here.
Config.Apps = {
    { id='notes', label='Notas', description='Guarde lembretes neste tablet.', icon='📝', folder='notes', defaultInstalled=true },
    { id='calculator', label='Calculadora', description='Contas rápidas para o dia a dia.', icon='🧮', folder='calculator', defaultInstalled=true },
    { id='contacts', label='Contatos', description='Uma agenda salva no aparelho.', icon='👥', folder='contacts', defaultInstalled=true },
    { id='weather', label='Clima', description='Confira o clima da cidade.', icon='🌤️', folder='weather', defaultInstalled=true },
    { id='garage', label='Garagem', description='Acesse seus veículos.', icon='🚘', folder='garage', defaultInstalled=false },
    { id='homes', label='Casas', description='Veja suas propriedades.', icon='🏠', folder='homes', defaultInstalled=false },
    { id='orgs', label='Organizações', description='Acesse as funções da sua organização.', icon='🏢', folder='orgs', defaultInstalled=false },
    { id='spotify', label='Spotify', description='Abra o player de música do servidor.', icon='🎵', folder='spotify', defaultInstalled=false },
    { id='clockin', label='Bate-ponto', description='Acesse seu registro de serviço.', icon='🕒', folder='clockin', defaultInstalled=false },
    { id='jobs', label='Empregos', description='Veja o painel de empregos do servidor.', icon='💼', folder='jobs', defaultInstalled=false },
    { id='judicial', label='Judicial', description='Registre e acompanhe processos judiciais.', icon='⚖️', folder='judicial', defaultInstalled=false },
    { id='gov', label='GOV', description='Acesse seus dados e serviços públicos.', icon='🏛️', iconImage='apps/gov/icon.svg', folder='gov', defaultInstalled=true }
}
Config.CoreApps = {
    { id='store', label='Loja', description='Instale e remova aplicativos.', icon='▦', core=true },
    { id='settings', label='Ajustes', description='Informações do aparelho.', icon='⚙', core=true }
}



