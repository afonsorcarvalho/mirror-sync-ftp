# Mirror Sync - Instalação via Crontab

Este documento descreve como usar os scripts de instalação e gerenciamento do `mirror_sync_fitadigital.py` via crontab.

## Arquivos Criados

- `run_mirror_sync.sh` - Script wrapper que gerencia o lock e executa o mirror_sync
- `install_crontab.sh` - Script de instalação para configurar o crontab
- `uninstall_crontab.sh` - Script de desinstalação para remover do crontab
- `README_CRONTAB.md` - Esta documentação

## Como Funciona

### Sistema de Lock

O sistema de lock foi movido do código Python para o script wrapper `run_mirror_sync.sh`. Isso permite:

1. **Controle externo**: O lock é gerenciado pelo shell, não pelo Python
2. **Execução única**: Apenas uma instância pode rodar por vez
3. **Limpeza automática**: Locks órfãos são removidos automaticamente
4. **Logs detalhados**: Todas as operações são logadas

### Script Wrapper

O `run_mirror_sync.sh` faz:

1. Verifica se já existe uma instância rodando
2. Cria um lock com o PID do processo
3. Ativa o ambiente virtual (se existir)
4. Executa o `mirror_sync_fitadigital.py`
5. Remove o lock automaticamente ao finalizar
6. Registra todas as operações em logs

## Instalação

### 1. Configurar o Crontab

Execute o script de instalação:

```bash
# Executar a cada 30 minutos (padrão)
./install_crontab.sh

# Executar a cada 15 minutos
./install_crontab.sh -m 15

# Executar a cada 2 horas
./install_crontab.sh -h 2

# Executar diariamente à meia-noite
./install_crontab.sh -d 1

# Executar a cada 12 horas e 30 minutos
./install_crontab.sh -h 12 -m 30
```

### 2. Verificar Instalação

```bash
# Ver o crontab atual
crontab -l

# Ver logs do wrapper
tail -f logs/mirror_sync_wrapper.log

# Ver logs do mirror_sync
tail -f logs/mirror_sync_YYYYMMDD.log
```

## Desinstalação

Para remover a configuração do crontab:

```bash
./uninstall_crontab.sh
```

O script irá:
1. Mostrar a entrada atual no crontab
2. Pedir confirmação
3. Fazer backup do crontab
4. Remover a entrada
5. Oferecer para remover locks órfãos

## Monitoramento

### Logs do Wrapper

O arquivo `logs/mirror_sync_wrapper.log` contém:
- Timestamps de início e fim
- Status do lock
- Ativação/desativação do ambiente virtual
- Códigos de saída

### Logs do Mirror Sync

O arquivo `logs/mirror_sync_YYYYMMDD.log` contém:
- Logs detalhados do processo de sincronização
- Erros e avisos
- Informações de cada host configurado

### Verificar Status

```bash
# Ver se há processo rodando
ps aux | grep mirror_sync

# Verificar lock
ls -la /tmp/mirror_sync.lock

# Ver logs em tempo real
tail -f logs/mirror_sync_wrapper.log
```

## Solução de Problemas

### Lock Órfão

Se o processo for interrompido abruptamente, pode ficar um lock órfão:

```bash
# Remover lock órfão manualmente
rm -f /tmp/mirror_sync.lock

# Ou usar o script de desinstalação
./uninstall_crontab.sh
```

### Erro de Permissão

Se o script não for executável:

```bash
chmod +x run_mirror_sync.sh
chmod +x install_crontab.sh
chmod +x uninstall_crontab.sh
```

### Ambiente Virtual

Se você usar um ambiente virtual, certifique-se de que está no diretório `venv/` dentro do projeto.

## Estrutura de Arquivos

```
mirror-sync-ftp/
├── mirror_sync_fitadigital.py    # Script principal (sem locks)
├── run_mirror_sync.sh            # Wrapper com controle de lock
├── install_crontab.sh            # Instalação no crontab
├── uninstall_crontab.sh          # Remoção do crontab
├── config.yml                    # Configuração dos hosts
├── logs/                         # Diretório de logs
│   ├── mirror_sync_wrapper.log   # Logs do wrapper
│   └── mirror_sync_YYYYMMDD.log  # Logs do mirror_sync
└── README_CRONTAB.md             # Esta documentação
```

## Exemplo de Uso Completo

```bash
# 1. Instalar para rodar a cada 30 minutos
./install_crontab.sh

# 2. Verificar se foi instalado
crontab -l

# 3. Monitorar execução
tail -f logs/mirror_sync_wrapper.log

# 4. Alterar frequência para a cada hora
./uninstall_crontab.sh
./install_crontab.sh -h 1

# 5. Remover completamente
./uninstall_crontab.sh
```

## Notas Importantes

- O script wrapper gerencia automaticamente o ambiente virtual se existir
- Locks órfãos são detectados e removidos automaticamente
- Todos os logs são preservados para auditoria
- O sistema é robusto contra execuções simultâneas
- A desinstalação faz backup automático do crontab
