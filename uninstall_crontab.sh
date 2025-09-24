#!/bin/bash
# Script de desinstalação para remover o mirror_sync_fitadigital.py do crontab.
# Este script remove a entrada do crontab que foi criada pelo install_crontab.sh.

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRON_ENTRY_ID="#mirror_sync_fitadigital"

# Função para log
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_message "=== Desinstalação do Mirror Sync do Crontab ==="

# Verifica se existe um crontab
if ! crontab -l >/dev/null 2>&1; then
    log_message "INFO: Nenhum crontab encontrado para o usuário atual"
    exit 0
fi

# Verifica se a entrada existe no crontab
if ! crontab -l | grep -q "$CRON_ENTRY_ID"; then
    log_message "INFO: Entrada do mirror_sync não encontrada no crontab"
    log_message "Nada a ser removido."
    exit 0
fi

log_message "Entrada encontrada no crontab:"
crontab -l | grep "$CRON_ENTRY_ID"

# Confirma a remoção
echo ""
read -p "Deseja realmente remover a entrada do mirror_sync do crontab? (s/N): " -r
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log_message "Operação cancelada pelo usuário"
    exit 0
fi

# Backup do crontab atual
BACKUP_FILE="/tmp/crontab_backup_$(date +%Y%m%d_%H%M%S)"
crontab -l > "$BACKUP_FILE"
log_message "Backup do crontab salvo em: $BACKUP_FILE"

# Remove a entrada do crontab
TEMP_CRON="/tmp/crontab_temp_$(date +%Y%m%d_%H%M%S)"
crontab -l | grep -v "$CRON_ENTRY_ID" > "$TEMP_CRON"

# Aplica o novo crontab
log_message "Removendo entrada do crontab..."
crontab "$TEMP_CRON"

if [ $? -eq 0 ]; then
    log_message "SUCESSO: Entrada do mirror_sync removida do crontab!"
    
    # Exibe o crontab atual
    log_message ""
    log_message "Crontab atual:"
    crontab -l
    
else
    log_message "ERRO: Falha ao remover entrada do crontab"
    log_message "Restaurando backup..."
    crontab "$BACKUP_FILE"
    rm -f "$TEMP_CRON"
    exit 1
fi

# Limpa arquivos temporários
rm -f "$TEMP_CRON"

# Verifica se há locks órfãos
LOCK_FILE="/tmp/mirror_sync.lock"
if [ -f "$LOCK_FILE" ]; then
    log_message ""
    log_message "AVISO: Encontrado arquivo de lock órfão: $LOCK_FILE"
    read -p "Deseja remover o arquivo de lock? (s/N): " -r
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        rm -f "$LOCK_FILE"
        log_message "Arquivo de lock removido"
    else
        log_message "Arquivo de lock mantido"
    fi
fi

log_message ""
log_message "=== Desinstalação Concluída ==="
log_message "Para reinstalar: ./install_crontab.sh"
log_message "Backup salvo em: $BACKUP_FILE"
