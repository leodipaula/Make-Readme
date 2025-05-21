# 🧠 Make-Readme

Gere arquivos `README.md` automaticamente com ajuda de IA! Este projeto usa a [API da Hugging Face](https://huggingface.co) para gerar readmes com base em descrições simples de seus repositórios.

---

## 📦 Requisitos

- [Rust](https://www.rust-lang.org/) instalado
- Uma conta e token válido da [Hugging Face](https://huggingface.co) que só precisa ser do tipo Read
- PowerShell

---

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

## ✅ Uso

Depois de abrir um novo terminal:

```powershell
Make-Readme "C:\caminho\para\seu\repositorio"
```
O script irá gerar (ou sobrescrever) um README.md com base nas informações do repositório.

## 🛠️ Estrutura

- `Make-Readme.ps1`: Lê o repositório e gera o prompt
- `gerador_readme/`: Projeto Rust que chama a API da Hugging Face
- `setup.ps1`: Script de configuração do ambiente

## 🧪 Exemplo

```powershell
Make-Readme "C:\Users\leodipaula\Projetos\Java\LojaGames"
```

## 🤝 Contribuição

Sinta-se à vontade para forkar e mandar PR ou abrir uma issue sobre correções, melhorias ou novas funcionalidades.  
