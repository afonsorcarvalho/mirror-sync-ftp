# Mirror Sync FTP

Script Python para espelhamento de diretórios remotos usando wget via FTP.

## Requisitos

- Python 3.6+
- wget
- PyYAML

## Instalação

Existem duas formas de instalar as dependências:

### 1. Usando Ambiente Virtual (Recomendado)

```bash
# Instalar requisitos do sistema
sudo apt install python3-venv python3-full

# Criar e ativar ambiente virtual
cd /home/fitadigital
python3 -m venv venv
source venv/bin/activate

# Instalar dependências
pip install pyyaml
```

### 2. Usando Pacotes do Sistema

```bash
sudo apt install python3-yaml
```

## Configuração

1. Edite o arquivo `config.yml` com suas configurações:

```yaml
hosts:
  - name: "nome_do_host"
    host: "ftp.exemplo.com"
    username: "seu_usuario"
    password: "sua_senha"
    remote_dir: "/caminho/remoto"
    local_dir: "/caminho/local"
    recursive: true
    exclude:  # opcional
      - "*.tmp"
      - "*.log"
```

## Segurança

- As senhas FTP são armazenadas no arquivo `config.yml`. Certifique-se de:
  - Definir permissões restritas no arquivo: `chmod 600 config.yml`
  - Não compartilhar ou commitar o arquivo com senhas
  - Considerar usar variáveis de ambiente para senhas em produção

## Uso

### Execução Manual

Se estiver usando ambiente virtual:
```bash
# Ativar o ambiente virtual
source /home/fitadigital/venv/bin/activate

# Executar o script
python3 mirror_sync_fitadigital.py
```

Se estiver usando pacotes do sistema:
```bash
python3 mirror_sync_fitadigital.py
```

### Configuração do Cron

O sistema utiliza dois scripts no crontab:

1. **mirror_sync_fitadigital.py**: Executa o espelhamento FTP
2. **clean_logs.sh**: Realiza a limpeza automática dos logs

Para configurar, adicione ao crontab (`crontab -e`):

```bash
# Mirror Sync FitaDigital - Executa a cada minuto
* * * * * /usr/bin/python3 /home/fitadigital/fitadigital/mirror_sync_fitadigital.py

# Limpeza de logs - Executa todo dia à meia-noite
0 0 * * * /home/fitadigital/fitadigital/clean_logs.sh
```

## Logs

Os logs são salvos no diretório `logs/` com o formato `mirror_sync_YYYYMMDD.log`
- Por segurança, as senhas são mascaradas nos logs
- Logs são mantidos por 2 dias e automaticamente removidos pelo clean_logs.sh
- A limpeza é registrada no log do dia atual

## Estrutura de Diretórios

```
.
├── config.yml
├── mirror_sync_fitadigital.py
├── clean_logs.sh
├── logs/
│   └── mirror_sync_YYYYMMDD.log
└── README.md
```

## Scripts

### mirror_sync_fitadigital.py
- Script principal que realiza o espelhamento via FTP
- Executa a cada minuto via cron
- Possui controle de timeout e instância única
- Mascara senhas nos logs

### clean_logs.sh
- Script de limpeza automática de logs
- Remove logs mais antigos que 2 dias
- Executa diariamente à meia-noite
- Registra a atividade de limpeza no log atual 