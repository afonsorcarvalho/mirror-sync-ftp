#!/bin/bash
# Script wrapper para executar mirror_sync_fitadigital.py com controle de lock via arquivo.
# Este script garante que apenas uma instância do mirror_sync esteja rodando por vez.

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/mirror_sync_fitadigital.py"
LOCK_FILE="/tmp/mirror_sync.lock"
LOG_DIR="$SCRIPT_DIR/logs"

# Cria diretório de logs se não existir
mkdir -p "$LOG_DIR"

# Função para log
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_DIR/mirror_sync_wrapper.log"
}

# Função para limpeza ao sair
cleanup() {
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
        log_message "Lock removido: $LOCK_FILE"
    fi
}

# Configura trap para limpeza automática
trap cleanup EXIT INT TERM

# Verifica se já existe uma instância rodando
if [ -f "$LOCK_FILE" ]; then
    # Verifica se o processo ainda está rodando
    if [ -f "$LOCK_FILE" ] && kill -0 "$(cat "$LOCK_FILE" 2>/dev/null)" 2>/dev/null; then
        log_message "ERRO: Outra instância do mirror_sync já está em execução (PID: $(cat "$LOCK_FILE"))"
        exit 1
    else
        # Processo não existe mais, remove o lock órfão
        log_message "AVISO: Removendo lock órfão de processo inexistente"
        rm -f "$LOCK_FILE"
    fi
fi

# Cria o lock com o PID atual
echo $$ > "$LOCK_FILE"
log_message "Lock criado: $LOCK_FILE (PID: $$)"

# Verifica se o script Python existe
if [ ! -f "$PYTHON_SCRIPT" ]; then
    log_message "ERRO: Script Python não encontrado: $PYTHON_SCRIPT"
    exit 1
fi

# Verifica se existe ambiente virtual
VENV_PATH="$SCRIPT_DIR/venv"
if [ -d "$VENV_PATH" ]; then
    log_message "Ativando ambiente virtual: $VENV_PATH"
    source "$VENV_PATH/bin/activate"
fi

# Executa o script Python
log_message "Iniciando execução do mirror_sync_fitadigital.py"
python3 "$PYTHON_SCRIPT"
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    log_message "Execução concluída com sucesso"
else
    log_message "Execução falhou com código de saída: $EXIT_CODE"
fi

# Desativa o ambiente virtual se foi ativado
if [ -d "$VENV_PATH" ] && [ -n "$VIRTUAL_ENV" ]; then
    deactivate
    log_message "Ambiente virtual desativado"
fi

log_message "Script wrapper finalizado"
exit $EXIT_CODE
