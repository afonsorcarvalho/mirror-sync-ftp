#!/bin/bash

# Remove arquivos de log mais antigos que 2 dias
find /home/fitadigital/fitadigital/logs -name "mirror_sync_*.log" -type f -mtime +2 -delete

# Registra a limpeza no log atual
echo "$(date '+%Y-%m-%d %H:%M:%S') - Logs mais antigos que 2 dias foram removidos" >> "/home/fitadigital/fitadigital/logs/mirror_sync_$(date '+%Y%m%d').log" 