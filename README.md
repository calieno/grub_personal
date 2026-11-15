# GRUB Personalizado - Dual-Boot Arch Linux & Windows

Configuração personalizada do **GRUB2** para **Dual-Boot (Arch Linux + Windows 11/10)** utilizando o tema **Vimix** ([grub2-themes](https://github.com/vinceliuice/grub2-themes.git)), com visual minimalista de 2 opções e atalho via **Barra de Espaço** para opções avançadas.

---

## 🚀 Características

1. **Tela Inicial Minimalista:**
   - Exibe **exclusivamente** os dois sistemas operacionais na tela inicial:
     - 🐧 **Arch Linux** (com ícone oficial do Arch)
     - 🪟 **Windows Boot Manager** (com ícone oficial do Windows)
   - Sem entradas duplicadas ou opções secundárias poluindo o menu principal.

2. **Menu Avançado via Barra de Espaço:**
   - Ao pressionar a **barra de espaço** a qualquer momento na inicialização, o GRUB carrega instantaneamente um menu avançado completo:
     - 🛠️ **Arch Linux (Kernel LTS - Modo de Recuperação)**
     - 🪟 **Windows (Modo de Segurança / Recuperação)**
     - ⚙️ **UEFI Firmware Settings (Setup BIOS)**
     - 📸 **Arch Linux snapshots (Timeshift / Btrfs)**
     - ↩️ **<- Voltar ao menu principal [Esc / Espaço]**

3. **Lembrar Último Sistema Iniciado:**
   - Configurado com `GRUB_DEFAULT=saved` e `GRUB_SAVEDEFAULT=true`. O GRUB lembra qual sistema foi utilizado por último e o seleciona automaticamente após o tempo limite (timeout de 5 segundos).

4. **Instalação Totalmente Automatizada:**
   - Script shell interativo/autônomo que detecta automaticamente os UUIDs das partições, instala o tema e compila o GRUB.

---

## 📁 Estrutura do Repositório

```text
grub_personal/
├── config/
│   ├── grub                # Arquivo /etc/default/grub com temas e variáveis otimizadas
│   ├── 10_linux            # Script 10_linux com títulos limpos (sem duplicações)
│   ├── 15_windows          # Entrada do Windows posicionada como segunda opção
│   ├── 40_custom           # Gatilho oculto para a Barra de Espaço
│   ├── grub_advanced.cfg   # Menu de opções avançadas (BIOS, Snapshots, Recuperação)
│   ├── theme.txt           # Layout Vimix com altura travada para exatamente 2 itens (92px)
│   └── theme_advanced.txt  # Layout Vimix completo para o menu de ferramentas
├── install.sh              # Script de instalação e configuração automatizada
└── README.md               # Documentação detalhada
```

---

## 🛠️ Instalação Rápida

Clone o repositório e execute o script de instalação como root:

```bash
git clone https://github.com/calieno/grub_personal.git
cd grub_personal
chmod +x install.sh
sudo ./install.sh
```

O script cuidará de:
- Detectar a partição EFI do Windows (`bootmgfw.efi`).
- Detectar a partição raiz (Btrfs/Ext4) do Arch Linux.
- Baixar e aplicar o tema Vimix (1080p).
- Configurar os arquivos no `/etc/default/grub` e `/etc/grub.d/`.
- Configurar o menu avançado em `/boot/grub/grub_advanced.cfg`.
- Compilar e validar a sintaxe com `grub-mkconfig` e `grub-script-check`.

---

## 🛡️ Ativar Modo de Segurança Permanente no Windows

Para que a opção de modo de segurança do menu avançado inicialize diretamente no Modo de Segurança do Windows sem intervenção manual:

1. Inicie o Windows normalmente.
2. Abra o **Prompt de Comando como Administrador**.
3. Crie uma entrada de boot duplicada:
   ```cmd
   bcdedit /copy {current} /d "Windows (Modo de Seguranca)"
   ```
   *(Copie o código GUID gerado entre chaves `{...}`).*
4. Ative o Safe Mode para essa entrada:
   ```cmd
   bcdedit /set {SEU-GUID-AQUI} safeboot minimal
   ```

---

## ⌨️ Comandos Úteis do GRUB

- **Enter:** Inicia o sistema selecionado.
- **Barra de Espaço:** Alterna para o menu de opções avançadas (e vice-versa).
- **Esc:** Retorna do menu avançado para o menu principal.
- **c:** Abre o terminal de comandos do GRUB (digite `fwsetup` para entrar na BIOS).
- **e:** Edita os parâmetros de inicialização da entrada selecionada.
