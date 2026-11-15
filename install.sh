#!/usr/bin/env bash
# ==============================================================================
# Script de Configuração Automatizada do GRUB Dual-Boot (Arch Linux + Windows)
# Tema: Vimix (grub2-themes) com Menu Compacto e Acesso Avançado via Barra de Espaço
# Repositório: https://github.com/calieno/grub_personal.git
# ==============================================================================

set -e

# Cores para mensagens
C_RESET="\033[0m"
C_GREEN="\033[1;32m"
C_BLUE="\033[1;34m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"

log_info() { echo -e "${C_BLUE}[INFO]${C_RESET} $1"; }
log_success() { echo -e "${C_GREEN}[SUCESSO]${C_RESET} $1"; }
log_warn() { echo -e "${C_YELLOW}[AVISO]${C_RESET} $1"; }
log_err() { echo -e "${C_RED}[ERRO]${C_RESET} $1"; }

# 1. Checagem de Root
if [ "$EUID" -ne 0 ]; then
    log_err "Este script precisa ser executado como root (use sudo ./install.sh)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"

log_info "Iniciando a instalação e configuração do GRUB personalizado..."

# 2. Detectar Partição EFI do Windows
log_info "Detectando a partição EFI do Windows..."
WIN_EFI_UUID=""
for dev in $(lsblk -nrpo NAME,FSTYPE | awk '$2=="vfat"{print $1}'); do
    MNT_TEST=$(mktemp -d)
    if mount -o ro "$dev" "$MNT_TEST" 2>/dev/null; then
        if [ -f "$MNT_TEST/EFI/Microsoft/Boot/bootmgfw.efi" ] || [ -f "$MNT_TEST/efi/Microsoft/Boot/bootmgfw.efi" ]; then
            WIN_EFI_UUID=$(lsblk -nro UUID "$dev")
            umount "$MNT_TEST" 2>/dev/null || true
            rm -rf "$MNT_TEST"
            log_success "Partição EFI do Windows encontrada em $dev (UUID: $WIN_EFI_UUID)"
            break
        fi
        umount "$MNT_TEST" 2>/dev/null || true
    fi
    rm -rf "$MNT_TEST"
done

if [ -z "$WIN_EFI_UUID" ]; then
    WIN_EFI_UUID="7A8D-8E62"
    log_warn "Não foi possível auto-detectar o Windows EFI. Usando UUID padrão: $WIN_EFI_UUID"
fi

# 3. Detectar Partições Root e Boot do Arch Linux
ROOT_UUID=$(findmnt -n -o UUID / 2>/dev/null || echo "9d50f516-f04a-4dfa-9669-b4686ce2b777")
log_info "Partição raiz (root) do Linux: UUID=${ROOT_UUID}"

BOOT_MOUNT=$(findmnt -n -o TARGET /boot 2>/dev/null || true)
if [ -n "$BOOT_MOUNT" ]; then
    BOOT_UUID=$(findmnt -n -o UUID /boot 2>/dev/null)
    BOOT_PATH=""
    BOOT_FSTYPE=$(findmnt -n -o FSTYPE /boot 2>/dev/null || echo "vfat")
else
    BOOT_UUID="$ROOT_UUID"
    BOOT_PATH="/@"
    BOOT_FSTYPE="btrfs"
fi
log_info "Partição de boot do Linux: UUID=${BOOT_UUID} (fstype: ${BOOT_FSTYPE}, caminho kernel: '${BOOT_PATH}/')"

# 4. Instalar o Tema Vimix (grub2-themes)
THEME_DIR="/boot/grub/themes/vimix"
if [ ! -f "${THEME_DIR}/background.jpg" ]; then
    log_info "Tema Vimix não encontrado em ${THEME_DIR}. Clonando e instalando..."
    TMP_THEME_DIR=$(mktemp -d)
    git clone --depth 1 https://github.com/vinceliuice/grub2-themes.git "$TMP_THEME_DIR"
    bash "$TMP_THEME_DIR/install.sh" -b -t vimix -s 1080p -i color
    rm -rf "$TMP_THEME_DIR"
    log_success "Tema Vimix instalado com sucesso."
else
    log_info "Tema Vimix já presente em ${THEME_DIR}."
fi

# 5. Aplicar Temas (theme.txt com altura de 2 itens e theme_advanced.txt completo)
log_info "Configurando arquivos de layout do tema Vimix..."
cp "${CONFIG_DIR}/theme.txt" "${THEME_DIR}/theme.txt"
cp "${CONFIG_DIR}/theme_advanced.txt" "${THEME_DIR}/theme_advanced.txt"
chmod 644 "${THEME_DIR}/theme.txt" "${THEME_DIR}/theme_advanced.txt"

# 6. Atualizar /etc/default/grub
log_info "Atualizando /etc/default/grub..."
if [ -f /etc/default/grub ] && [ ! -f /etc/default/grub.orig ]; then
    cp /etc/default/grub /etc/default/grub.orig
fi
cp "${CONFIG_DIR}/grub" /etc/default/grub

# 7. Configurar scripts em /etc/grub.d/
log_info "Atualizando scripts em /etc/grub.d/..."

# 10_linux com títulos limpos e sem submenus duplicados
cp "${CONFIG_DIR}/10_linux" /etc/grub.d/10_linux
chmod 755 /etc/grub.d/10_linux

# 15_windows apontando para o UUID detectado
sed -e "s/{{WIN_EFI_UUID}}/${WIN_EFI_UUID}/g" \
    -e "s/7A8D-8E62/${WIN_EFI_UUID}/g" \
    "${CONFIG_DIR}/15_windows" > /etc/grub.d/15_windows
chmod 755 /etc/grub.d/15_windows

# 40_custom com gatilho para a barra de espaço (com caminhos prefix/grub dinâmicos)
cp "${CONFIG_DIR}/40_custom" /etc/grub.d/40_custom
chmod 755 /etc/grub.d/40_custom

# Desativar scripts secundários do menu principal para manter estritamente apenas 2 entradas visíveis
[ -f /etc/grub.d/15_uki ] && chmod -x /etc/grub.d/15_uki
[ -f /etc/grub.d/30_uefi-firmware ] && chmod -x /etc/grub.d/30_uefi-firmware
[ -f /etc/grub.d/41_snapshots-btrfs ] && chmod -x /etc/grub.d/41_snapshots-btrfs

# 8. Criar /boot/grub/grub_advanced.cfg atualizado com os UUIDs corretos
log_info "Gerando /boot/grub/grub_advanced.cfg..."
sed -e "s/{{WIN_EFI_UUID}}/${WIN_EFI_UUID}/g" \
    -e "s/7A8D-8E62/${WIN_EFI_UUID}/g" \
    -e "s/{{ROOT_UUID}}/${ROOT_UUID}/g" \
    -e "s/9d50f516-f04a-4dfa-9669-b4686ce2b777/${ROOT_UUID}/g" \
    -e "s/{{BOOT_UUID}}/${BOOT_UUID}/g" \
    -e "s|{{BOOT_PATH}}|${BOOT_PATH}|g" \
    "${CONFIG_DIR}/grub_advanced.cfg" > /boot/grub/grub_advanced.cfg
chmod 600 /boot/grub/grub_advanced.cfg

# 9. Compilar e aplicar a configuração no GRUB
log_info "Compilando configuração do GRUB via grub-mkconfig..."
grub-mkconfig -o /boot/grub/grub.cfg

log_info "Validando sintaxe do arquivo gerado..."
grub-script-check /boot/grub/grub.cfg
grub-script-check /boot/grub/grub_advanced.cfg

log_success "=========================================================="
log_success "  Instalação concluída com sucesso!"
log_success "  - Tela Inicial: Apenas Arch Linux e Windows Boot Manager"
log_success "  - Barra de Espaço: Abre o menu avançado com Snapshots, BIOS e Recuperação"
log_success "=========================================================="
