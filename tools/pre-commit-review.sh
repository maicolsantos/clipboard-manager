#!/bin/zsh
# Swift Quality & Security Pre-Commit Reviewer for Clips
# Enforces zero regressions on bugs, memory leaks, security, and tests.
set -euo pipefail

here=${0:A:h}
repo_root=${here:h}
cd "$repo_root"

echo "🔍 [Swift Auditor] Iniciando revisão pré-commit..."

# 1. Static Security & Memory Leak Pattern Checks
echo "1️⃣  Verificando padrões de código, memory leaks e segurança..."
leak_found=0

# Check for [unowned self] in closures (use [weak self] instead)
if git grep -n "\[unowned self\]" -- 'Sources/**/*.swift' >/dev/null 2>&1; then
  echo "⚠️  [LEAK/CRASH RISK] Encontrado '[unowned self]'. Prefira '[weak self]' para evitar crashes ou memory leaks."
  git grep -n "\[unowned self\]" -- 'Sources/**/*.swift'
  leak_found=1
fi

# Check for Timer without [weak self]
if git grep -En "Timer\.(scheduledTimer|Timer).*\{" -- 'Sources/**/*.swift' | grep -v "weak self" >/dev/null 2>&1; then
  echo "⚠️  [LEAK RISK] Encontrado Timer sem '[weak self]'. Timers de repetição retêm self indefinidamente."
  git grep -En "Timer\.(scheduledTimer|Timer).*\{" -- 'Sources/**/*.swift'
  leak_found=1
fi

# Check for raw print statements that might leak passwords or secrets
if git grep -i -E "print\([^)]*\b(password|secret|bearer|apiKey)\b" -- 'Sources/**/*.swift' ':!Sources/Clips/SelfTest.swift' >/dev/null 2>&1; then
  echo "⚠️  [SECURITY RISK] Encontrado print de dados potencialmente sensíveis."
  git grep -i -E "print\([^)]*\b(password|secret|bearer|apiKey)\b" -- 'Sources/**/*.swift' ':!Sources/Clips/SelfTest.swift'
  leak_found=1
fi

if [[ $leak_found -eq 0 ]]; then
  echo "✅ Verificações estáticas de segurança e memory leak: PASS"
else
  echo "❌ Verificações estáticas falharam. Corrija os pontos acima antes de commitar."
  exit 1
fi

# 2. Automated Unit Tests
echo "2️⃣  Executando testes unitários (swift test)..."
if swift test --scratch-path ~/Library/Developer/Clips/test-build > /tmp/clips-swift-test.log 2>&1; then
  echo "✅ Testes unitários (ClipsKitTests): PASS"
else
  echo "❌ Testes unitários falharam! Log:"
  cat /tmp/clips-swift-test.log | tail -n 25
  exit 1
fi

# 3. Application In-App Self-Test
echo "3️⃣  Executando self-test do app (tools/selftest.sh)..."
if ./tools/selftest.sh > /tmp/clips-selftest.log 2>&1; then
  check_count=$(grep -c "^PASS" /tmp/clips-selftest.log || true)
  echo "✅ Self-test funcional ($check_count verificações): PASS"
else
  echo "❌ Self-test funcional falhou! Log:"
  cat /tmp/clips-selftest.log | tail -n 25
  exit 1
fi

echo "🚀 [Swift Auditor] Todos os checks de qualidade, segurança e testes foram APROVADOS!"
exit 0
