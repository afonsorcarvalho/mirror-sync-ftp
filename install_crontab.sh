#!/bin/bash
# Script de instalação para configurar o mirror_sync_fitadigital.py no crontab.
# Este script adiciona uma entrada no crontab para executar o mirror_sync em intervalos regulares.

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER_SCRIPT="$SCRIPT_DIR/run_mirror_sync.sh"
CRON_ENTRY_ID="#mirror_sync_fitadigital"

# Função para log
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Função para exibir uso
show_usage() {
    echo "Uso: $0 [OPÇÕES]"
    echo ""
    echo "Opções:"
    echo "  -m MINUTOS    Intervalo em minutos (padrão: 30)"
    echo "  -h HORAS      Intervalo em horas (padrão: 0, ignora minutos)"
    echo "  -d DIAS       Intervalo em dias (padrão: 0, ignora horas e minutos)"
    echo "  --help        Exibe esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 -m 15          # A cada 15 minutos"
    echo "  $0 -h 2           # A cada 2 horas"
    echo "  $0 -d 1           # Diariamente à meia-noite"
    echo "  $0 -h 12 -m 30    # A cada 12 horas e 30 minutos"
    echo ""
    echo "Nota: Se não especificar nenhum parâmetro, será usado 30 minutos por padrão."
}

# Função para validar entrada
validate_interval() {
    if ! [[ "$1" =~ ^[0-9]+$ ]] || [ "$1" -lt 0 ]; then
        echo "ERRO: '$1' não é um número válido (deve ser um inteiro positivo)"
        exit 1
    fi
}

# Valores padrão
MINUTES=30
HOURS=0
DAYS=0

# Processa argumentos da linha de comando
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--minutes)
            validate_interval "$2"
            MINUTES="$2"
            shift 2
            ;;
        -h|--hours)
            validate_interval "$2"
            HOURS="$2"
            MINUTES=0  # Reset minutos quando horas são especificadas
            shift 2
            ;;
        -d|--days)
            validate_interval "$2"
            DAYS="$2"
            HOURS=0    # Reset horas quando dias são especificados
            MINUTES=0  # Reset minutos quando dias são especificados
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "ERRO: Opção desconhecida '$1'"
            show_usage
            exit 1
            ;;
    esac
done

log_message "=== Instalação do Mirror Sync no Crontab ==="

# Verifica se o script wrapper existe
if [ ! -f "$WRAPPER_SCRIPT" ]; then
    log_message "ERRO: Script wrapper não encontrado: $WRAPPER_SCRIPT"
    exit 1
fi

# Verifica se o script wrapper é executável
if [ ! -x "$WRAPPER_SCRIPT" ]; then
    log_message "ERRO: Script wrapper não é executável. Executando chmod +x..."
    chmod +x "$WRAPPER_SCRIPT"
    if [ $? -ne 0 ]; then
        log_message "ERRO: Falha ao tornar o script executável"
        exit 1
    fi
fi

# Monta a entrada do crontab
if [ $DAYS -gt 0 ]; then
    # Execução diária
    CRON_SCHEDULE="0 0 */$DAYS * *"
    SCHEDULE_DESC="a cada $DAYS dia(s)"
elif [ $HOURS -gt 0 ]; then
    # Execução por hora
    if [ $MINUTES -gt 0 ]; then
        CRON_SCHEDULE="$MINUTES */$HOURS * * *"
        SCHEDULE_DESC="a cada $HOURS hora(s) e $MINUTES minuto(s)"
    else
        CRON_SCHEDULE="0 */$HOURS * * *"
        SCHEDULE_DESC="a cada $HOURS hora(s)"
    fi
else
    # Execução por minuto
    CRON_SCHEDULE="*/$MINUTES * * * *"
    SCHEDULE_DESC="a cada $MINUTES minuto(s)"
fi

# Entrada completa do crontab
CRON_ENTRY="$CRON_SCHEDULE $WRAPPER_SCRIPT $CRON_ENTRY_ID"

log_message "Configuração:"
log_message "  - Script: $WRAPPER_SCRIPT"
log_message "  - Agendamento: $SCHEDULE_DESC"
log_message "  - Entrada crontab: $CRON_ENTRY"

# Verifica se já existe uma entrada no crontab
log_message "Verificando se já existe entrada no crontab..."

# Backup do crontab atual
TEMP_CRON="/tmp/crontab_backup_$(date +%Y%m%d_%H%M%S)"
crontab -l > "$TEMP_CRON" 2>/dev/null || touch "$TEMP_CRON"

# Remove entrada existente se houver
grep -v "$CRON_ENTRY_ID" "$TEMP_CRON" > "$TEMP_CRON.new"
mv "$TEMP_CRON.new" "$TEMP_CRON"

# Adiciona nova entrada
echo "$CRON_ENTRY" >> "$TEMP_CRON"

# Aplica o novo crontab
log_message "Aplicando nova configuração do crontab..."
crontab "$TEMP_CRON"

if [ $? -eq 0 ]; then
    log_message "SUCESSO: Crontab configurado com sucesso!"
    log_message "O mirror_sync será executado $SCHEDULE_DESC"
    
    # Exibe o crontab atual
    log_message ""
    log_message "Crontab atual:"
    crontab -l | grep -A5 -B5 "$CRON_ENTRY_ID" || crontab -l
    
else
    log_message "ERRO: Falha ao aplicar configuração do crontab"
    rm -f "$TEMP_CRON"
    exit 1
fi

# Limpa arquivos temporários
rm -f "$TEMP_CRON"

log_message ""
log_message "=== Instalação Concluída ==="
log_message "Para verificar o status: crontab -l"
log_message "Para remover: ./uninstall_crontab.sh"
log_message "Para ver logs: tail -f $SCRIPT_DIR/logs/mirror_sync_wrapper.log"
