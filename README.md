# 🧠 Make-Readme

Gere arquivos `README.md` automaticamente com ajuda de IA! Este projeto usa a [API da Hugging Face](https://huggingface.co) para gerar readmes com base em descrições simples de seus repositórios.

---

## 📦 Requisitos

- [Rust](https://www.rust-lang.org/) instalado
- Uma conta e token válido da [Hugging Face](https://huggingface.co) que só precisa ser do tipo Read

---

## Requisitos do Sistema

- PowerShell 7+ (PowerShell Core)
  - Windows: Já vem instalado no Windows 10/11
  - macOS: `brew install powershell`
  - Linux: [Instruções de instalação](https://learn.microsoft.com/pt-br/powershell/scripting/install/installing-powershell-on-linux)
- Docker Desktop
  - Windows: [Download Docker Desktop](https://www.docker.com/products/docker-desktop/)
  - macOS: `brew install --cask docker`
  - Linux: [Instruções de instalação](https://docs.docker.com/engine/install/)

## 🚀 Setup

1. Clone o projeto:

```bash
git clone https://github.com/leodipaula/make-readme.git
cd make-readme
```

2. Crie um arquivo `.env` na raiz do projeto com sua chave da Hugging Face:

```env
HUGGINGFACE_TOKEN=seu_token_aqui
```

3. Execute o script de setup:

```powershell
.\setup.ps1
```
Ou, no Windows, clique duas vezes em setup.bat.

## Instalação

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/make-readme.git

# Entre no diretório
cd make-readme

# Instale o script (Windows/macOS/Linux)
pwsh ./setup-docker.ps1
```

## ✅ Uso

Depois de abrir um novo terminal:

```powershell
Make-Readme "C:\caminho\para\seu\repositorio"
```
O script irá gerar (ou sobrescrever) um README.md com base nas informações do repositório.

O comando é o mesmo em todas as plataformas:

```powershell
mr .  # Gera README para o diretório atual
# ou
mr /caminho/para/repositorio  # Gera README para um repositório específico
```

## 🐳 Execução via Docker

Além da execução local, você pode usar o Docker para gerar os READMEs sem precisar instalar o Rust:

```powershell
# Gera README para o diretório atual
mdr .

# Ou para um repositório específico
mdr C:\caminho\para\repositorio
```

### Como funciona

1. O script verifica se o Docker está configurado corretamente
2. Constrói a imagem Docker com o ambiente Rust
3. Executa o container passando:
   - Volume montado do repositório
   - Token da Hugging Face
   - Informações do projeto via GitHub API

### Vantagens

- Não precisa instalar Rust localmente
- Funciona em Windows, macOS e Linux
- Mesma experiência do comando local (`mr`)

### Requisitos específicos

- Docker Desktop instalado e rodando
- No Windows: configurado para Linux containers
- Token da Hugging Face em `gerador_readme/.env`

## 🛠️ Estrutura

- `Make-Readme.ps1`: Lê o repositório e gera o prompt
- `gerador_readme/`: Projeto Rust que chama a API da Hugging Face
- `setup.ps1`: Script de configuração do ambiente

## 🧪 Exemplo

```powershell
Make-Readme C:\Users\leodipaula\Projetos\Java\LojaGames
# Ou também pode usar o alias:
mr C:\Users\leodipaula\Projetos\Java\LojaGames
```

## 🤝 Contribuição

Sinta-se à vontade para forkar e mandar PR ou abrir uma issue sobre correções, melhorias ou novas funcionalidades.
