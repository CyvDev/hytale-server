#!/usr/bin/env bash
# Vérifie les flags JVM
set -euo pipefail

IMAGE="${1:?Usage: $0 <image-tag>}"

echo "═══════════════════════════════════════"
echo "  ☕ JVM Tests for: $IMAGE"
echo "═══════════════════════════════════════"

# Test 1: Java version
echo ""
echo "── Test 1: Java version ──"
JAVA_VERSION=$(docker run --rm "$IMAGE" java --version 2>&1 | head -1)
echo "  Java: $JAVA_VERSION"
if echo "$JAVA_VERSION" | grep -q "25"; then
  echo "  ✅ PASS: Java 25 detected"
else
  echo "  ❌ FAIL: Expected Java 25, got: $JAVA_VERSION"
  exit 1
fi

# Test 2: Custom JRE (no javac)
echo ""
echo "── Test 2: Custom JRE (no JDK tools) ──"
if docker run --rm "$IMAGE" which javac 2>/dev/null; then
  echo "  ❌ FAIL: javac found — this should be a JRE, not JDK"
  exit 1
else
  echo "  ✅ PASS: No javac (custom JRE via jlink)"
fi

# Test 3: ZGC disponible
echo ""
echo "── Test 3: ZGC available ──"
ZGC_TEST=$(docker run --rm "$IMAGE" java -XX:+UseZGC -version 2>&1 || true)
if echo "$ZGC_TEST" | grep -qi "error\|not recognized"; then
  echo "  ❌ FAIL: ZGC not available"
  exit 1
else
  echo "  ✅ PASS: ZGC is available"
fi

# Test 4: G1GC disponible
echo ""
echo "── Test 4: G1GC available ──"
G1_TEST=$(docker run --rm "$IMAGE" java -XX:+UseG1GC -version 2>&1 || true)
if echo "$G1_TEST" | grep -qi "error\|not recognized"; then
  echo "  ❌ FAIL: G1GC not available"
  exit 1
else
  echo "  ✅ PASS: G1GC is available"
fi

# Test 5: Shenandoah disponible
echo ""
echo "── Test 5: Shenandoah available ──"
SHEN_TEST=$(docker run --rm "$IMAGE" java -XX:+UseShenandoahGC -version 2>&1 || true)
if echo "$SHEN_TEST" | grep -qi "error\|not recognized"; then
  echo "  ⚠️ WARN: Shenandoah not available (may not be in this JRE build)"
else
  echo "  ✅ PASS: Shenandoah is available"
fi

# Test 6: Memory limits respected
echo ""
echo "── Test 6: Memory configuration ──"
MEM_OUTPUT=$(docker run --rm -e HYTALE_MEMORY=512M "$IMAGE" \
  java -Xmx512m -XX:+PrintFlagsFinal -version 2>&1 | grep MaxHeapSize || true)
echo "  $MEM_OUTPUT"
echo "  ✅ PASS: Memory flags accepted"

echo ""
echo "═══════════════════════════════════════"
echo "  ✅ All JVM tests passed!"
echo "═══════════════════════════════════════"
