#!/usr/bin/env bash
# Patch react-data-grid to remove useEffectEvent from imports and add polyfill

set -eux

RDG_DIR="node_modules/react-data-grid"

if [ -f "${RDG_DIR}/lib/index.js" ]; then
    echo "Patching react-data-grid lib/index.js to add useEffectEvent polyfill..."

    # First, remove useEffectEvent from the React import
    # Original: import { createContext, memo, useCallback, useContext, useEffect, useEffectEvent, useImperativeHandle, useLayoutEffect, useMemo, useRef, useState } from "react";
    # Target:   import { createContext, memo, useCallback, useContext, useEffect, useImperativeHandle, useLayoutEffect, useMemo, useRef, useState } from "react";
    sed -i 's/, useEffectEvent,/, /g' "${RDG_DIR}/lib/index.js"
    sed -i 's/, useEffectEvent / /g' "${RDG_DIR}/lib/index.js"

    # Create a temporary file with the polyfill
    cat > /tmp/polyfill.js << 'EOF'

// Polyfill for useEffectEvent (React experimental API)
function useEffectEvent(fn) {
  const ref = useRef(fn);
  useLayoutEffect(() => {
    ref.current = fn;
  });
  return useCallback((...args) => ref.current(...args), []);
}
EOF

    # Get the first 3 lines (imports)
    head -n 3 "${RDG_DIR}/lib/index.js" > "${RDG_DIR}/lib/index.js.tmp"

    # Append the polyfill
    cat /tmp/polyfill.js >> "${RDG_DIR}/lib/index.js.tmp"

    # Append the rest of the file (skip first 3 lines)
    tail -n +4 "${RDG_DIR}/lib/index.js" >> "${RDG_DIR}/lib/index.js.tmp"

    # Replace the original file
    mv "${RDG_DIR}/lib/index.js.tmp" "${RDG_DIR}/lib/index.js"

    # Clean up
    rm -f /tmp/polyfill.js

    echo "react-data-grid lib/index.js patched successfully"
else
    echo "react-data-grid not found at ${RDG_DIR}/lib/index.js, skipping patch"
fi
