#!/bin/bash
# Script para limpeza de logs antigos do mirror_sync_fitadigital
# Remove logs mais antigos que X dias (padrão: 7 dias)

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
DAYS_TO_KEEP="${1:-7}"  # Padrão: 7 dias, pode ser alterado via parâmetro

# Função para log
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Verifica se o diretório de logs existe
if [ ! -d "$LOG_DIR" ]; then
    log_message "ERRO: Diretório de logs não encontrado: $LOG_DIR"
    exit 1
fi

log_message "=== Limpeza de Logs Antigos ==="
log_message "Diretório: $LOG_DIR"
log_message "Mantendo logs dos últimos $DAYS_TO_KEEP dias"

# Conta arquivos antes da limpeza
FILES_BEFORE=$(find "$LOG_DIR" -name "mirror_sync_*.log" -type f | wc -l)
FILES_TO_DELETE=$(find "$LOG_DIR" -name "mirror_sync_*.log" -type f -mtime +$DAYS_TO_KEEP | wc -l)

log_message "Arquivos de log encontrados: $FILES_BEFORE"
log_message "Arquivos a serem removidos: $FILES_TO_DELETE"

# Remove arquivos de log mais antigos
if [ $FILES_TO_DELETE -gt 0 ]; then
    log_message "Removendo logs antigos..."
    find "$LOG_DIR" -name "mirror_sync_*.log" -type f -mtime +$DAYS_TO_KEEP -delete
    
    # Verifica se a remoção foi bem-sucedida
    FILES_AFTER=$(find "$LOG_DIR" -name "mirror_sync_*.log" -type f | wc -l)
    REMOVED_COUNT=$((FILES_BEFORE - FILES_AFTER))
    
    log_message "Logs removidos com sucesso: $REMOVED_COUNT"
    log_message "Logs restantes: $FILES_AFTER"
else
    log_message "Nenhum log antigo encontrado para remoção"
fi

# Lista logs restantes
log_message "Logs restantes:"
find "$LOG_DIR" -name "mirror_sync_*.log" -type f -exec ls -lh {} \; | while read line; do
    log_message "  $line"
done

log_message "=== Limpeza Concluída ===" 