#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para exibir cabeçalho
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Função para verificar limites
check_limit() {
    local valor=$1
    local limite=$2
    if (( $(echo "$valor > $limite" | bc -l) )); then
        echo -e "${RED}[ALERTA]${NC}"
    else
        echo -e "${GREEN}[OK]${NC}"
    fi
}

print_header "INFORMAÇÕES DO SISTEMA"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "SO: $(lsb_release -d | cut -f2)"
echo "Uptime: $(uptime -p)"
echo "Data/Hora: $(date '+%d/%m/%Y %H:%M:%S')"
echo ""


print_header "USO DE MEMÓRIA RAM"
total_mem=$(free -h | awk '/^Mem/ {print $2}')
used_mem=$(free -h | awk '/^Mem/ {print $3}')
percent_mem=$(free | awk '/^Mem/ {printf "%.2f", ($3/$2)*100}')

echo "Total: $total_mem"
echo "Usada: $used_mem"
echo "Percentual: $percent_mem% $(check_limit ${percent_mem%.*} 80)"
echo ""


print_header "USO DE DISCO"
df -h | grep -v "tmpfs\|loop\|snap" | tail -n +2 | while read line; do
    filesystem=$(echo $line | awk '{print $1}')
    size=$(echo $line | awk '{print $2}')
    used=$(echo $line | awk '{print $3}')
    percent=$(echo $line | awk '{print $5}' | sed 's/%//')
    
    echo "Partição: $filesystem"
    echo "  Tamanho: $size | Usado: $used | Percentual: ${percent}% $(check_limit $percent 80)"
done
echo ""


print_header "INFORMAÇÕES DE REDE"

# Endereço IP
echo "Interfaces de Rede:"
ip addr show | grep "^[0-9]:" | while read line; do
    iface=$(echo $line | awk '{print $2}' | sed 's/:$//')
    ip=$(ip addr show $iface | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    if [ ! -z "$ip" ]; then
        echo "  $iface: $ip"
    fi
done
echo ""

# Estatísticas de interface
echo "Estatísticas de Interface:"
ip -s link show | grep -E "^[0-9]+:|RX|TX" | paste - - | while read rx; do
    iface=$(echo "$rx" | grep "^[0-9]:" | awk '{print $2}' | sed 's/:$//')
    if [ ! -z "$iface" ]; then
        echo "  Interface: $iface"
        ip -s link show "$iface" | grep -A1 "RX" | tail -1 | awk '{print "    RX: "$1" bytes, "$3" pacotes"}'
        ip -s link show "$iface" | grep -A1 "TX" | tail -1 | awk '{print "    TX: "$1" bytes, "$3" pacotes"}'
    fi
done
echo ""

# DNS
echo "Servidor DNS:"
cat /etc/resolv.conf | grep "^nameserver" | head -3 | while read line; do
    echo "  $line"
done
echo ""

echo "Teste DNS (google.com):"
nslookup google.com 2>/dev/null || echo "Falha no teste DNS"

echo ""

# ========== TOP 5 PROCESSOS POR CPU ==========
print_header "TOP 5 PROCESSOS - USO DE CPU"
ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "%-8s %-6s %-6s %-20s\n", $1, $2, $3, $11}'
echo ""

# ========== TOP 5 PROCESSOS POR MEMÓRIA ==========
print_header "TOP 5 PROCESSOS - USO DE MEMÓRIA"
ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "%-8s %-6s %-6s %-20s\n", $1, $2, $4, $11}'
echo ""

# ========== CARGA DO SISTEMA ==========
print_header "CARGA DO SISTEMA"
load=$(cat /proc/loadavg)
echo "Carga: $load"
cores=$(nproc)
echo "Cores: $cores"
echo ""
