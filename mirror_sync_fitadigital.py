#!/usr/bin/env python3
"""
Script para espelhamento de diretórios usando wget via FTP.
Lê configurações do arquivo config.yml e executa o espelhamento para cada host configurado.

Modos de operação:
- verbose: Ativa logs detalhados do wget (--debug --verbose) e mostra saída em nível DEBUG
- debug: Sempre loga a saída completa do wget em nível INFO, independente do verbose
- Ambos podem ser usados simultaneamente para máxima verbosidade
"""

import yaml
import subprocess
import os
import logging
import sys
from datetime import datetime
from pathlib import Path
import urllib.parse

# Configuração do logging
log_dir = Path(__file__).parent / "logs"
log_dir.mkdir(exist_ok=True)
log_file = log_dir / f"mirror_sync_{datetime.now().strftime('%Y%m%d')}.log"

# Configuração do logging com nível DEBUG quando verbose estiver ativo
def setup_logging(verbose=False):
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )


def load_config():
    """Carrega a configuração do arquivo config.yml"""
    config_path = Path(__file__).parent / "config.yml"
    try:
        with open(config_path, 'r') as file:
            return yaml.safe_load(file)
    except Exception as e:
        logging.error(f"Erro ao carregar arquivo de configuração: {e}")
        return None

def mirror_directory(host_config):
    """
    Executa o wget para espelhar o diretório especificado via FTP
    
    Args:
        host_config (dict): Configuração do host a ser espelhado
    """
    name = host_config['name']
    host = host_config['host']
    username = host_config['username']
    password = host_config['password']
    remote_dir = host_config['remote_dir']
    local_dir = host_config['local_dir']
    recursive = host_config.get('recursive', True)
    exclude = host_config.get('exclude', [])
    verbose = host_config.get('verbose', False)
    debug = host_config.get('debug', False)

    # Cria o diretório local se não existir
    Path(local_dir).mkdir(parents=True, exist_ok=True)

    # Monta o comando wget
    wget_cmd = [
        'wget',
        '--mirror',
        '--no-host-directories',
        '--ftp-user=' + username,
        '--ftp-password=' + password,
        '--no-parent',
        f'--directory-prefix={local_dir}',
        '--timeout=60',  # Timeout de conexão de 60 segundos
        '--tries=2',     # Número máximo de tentativas
        '--read-timeout=30',  # Timeout de leitura de 30 segundos
        '--reject-regex', '\.tmp$|\.log$|\.REC$'  # Rejeita arquivos .tmp, .log e .REC
    ]

    # Adiciona opções de verbose se solicitado
    if verbose:
        wget_cmd.extend(['--debug', '--verbose'])
        logging.debug(f"Modo verbose ativado para {name}")
    elif debug:
        # Modo debug força pelo menos --verbose para ter saída
        wget_cmd.append('--verbose')
        logging.info(f"Modo debug ativado para {name} - saída completa será logada")
    else:
        wget_cmd.append('--no-verbose')

    # Adiciona opções para exclusão de diretórios
    if exclude:
        # Junta todos os padrões com vírgula
        exclude_patterns = ','.join(exclude)
        wget_cmd.extend(['--exclude-directories', exclude_patterns])
        logging.debug(f"Diretórios excluídos para {name}: {exclude_patterns}")

    if not recursive:
        wget_cmd.append('--no-recursive')
        logging.debug(f"Modo não-recursivo ativado para {name}")

    # URL completa FTP
    safe_url = f"ftp://{username}@{host}/{remote_dir.lstrip('/')}"
    full_url = f"ftp://{username}:{password}@{host}/{remote_dir.lstrip('/')}"
    
    wget_cmd.append(full_url)

    try:
        logging.info(f"Iniciando espelhamento FTP para {name}")
        logging.info(f"Conectando a: {safe_url}")  # Log seguro sem senha
        
        if verbose or debug:
            logging.debug(f"Comando wget completo: {' '.join(wget_cmd).replace(password, '********')}")
        
        result = subprocess.run(
            wget_cmd,
            capture_output=True,
            text=True,
            timeout=300  # Timeout global de 5 minutos para todo o processo
        )

        if result.returncode == 0:
            logging.info(f"Espelhamento concluído com sucesso para {name}")
            if debug:
                # Modo debug sempre mostra saída completa
                logging.info(f"[DEBUG] Saída do wget para {name}:")
                if result.stdout.strip():
                    logging.info(f"[DEBUG] {result.stdout}")
                else:
                    logging.info(f"[DEBUG] (Saída vazia - wget executou silenciosamente)")
                    logging.info(f"[DEBUG] Comando executado: {' '.join(wget_cmd).replace(password, '********')}")
            elif verbose:
                logging.debug(f"Saída do wget: {result.stdout}")
        else:
            # Filtra a saída de erro para remover possíveis senhas
            error_output = result.stderr.replace(password, '********')
            logging.error(f"Erro ao espelhar {name}: {error_output}")
            if debug:
                # Modo debug sempre mostra saída completa mesmo em caso de erro
                logging.info(f"[DEBUG] Saída do wget (erro) para {name}:")
                if result.stdout.strip():
                    logging.info(f"[DEBUG] STDOUT: {result.stdout}")
                else:
                    logging.info(f"[DEBUG] STDOUT: (vazio)")
                logging.info(f"[DEBUG] STDERR: {result.stderr.replace(password, '********')}")
                logging.info(f"[DEBUG] Comando executado: {' '.join(wget_cmd).replace(password, '********')}")
            elif verbose:
                logging.debug(f"Saída completa do wget: {result.stdout}")

    except subprocess.TimeoutExpired:
        logging.error(f"Timeout atingido ao espelhar {name} após 5 minutos")
    except Exception as e:
        logging.error(f"Erro durante o espelhamento de {name}: {str(e).replace(password, '********')}")

def main():
    """Função principal que coordena o espelhamento de todos os hosts"""
    # Primeiro configura o logging básico para capturar erros iniciais
    setup_logging(False)  # Configuração básica inicial
    
    config = load_config()
    if not config:
        logging.error("Não foi possível carregar a configuração. Encerrando.")
        return

    # Reconfigura o logging baseado no modo verbose/debug global
    global_verbose = config.get('verbose', False)
    global_debug = config.get('debug', False)
    setup_logging(global_verbose or global_debug)
    
    logging.info("Iniciando processo de espelhamento via FTP")
    
    if global_verbose:
        logging.debug("Modo verbose global ativado")
    if global_debug:
        logging.info("[DEBUG] Modo debug global ativado - saídas completas serão logadas")

    for host in config.get('hosts', []):
        mirror_directory(host)

    logging.info("Processo de espelhamento concluído")

if __name__ == "__main__":
    main() 