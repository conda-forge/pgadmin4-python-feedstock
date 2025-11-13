#!/bin/bash
# Patch react-data-grid to remove useEffectEvent usage and add polyfill

set -e

RDG_DIR="node_modules/react-data-grid"

if [ -f "${RDG_DIR}/lib/index.js" ]; then
    echo "Patching react-data-grid lib/index.js to add useEffectEvent polyfill..."

    # Add useEffectEvent polyfill function at the top of the file, after imports
    # Find the line number after the last import statement
    POLYFILL='
// Polyfill for useEffectEvent (React experimental API)
function useEffectEvent(fn) {
  const ref = useRef(fn);
  useLayoutEffect(() => {
    ref.current = fn;
  });
  return useCallback((...args) => ref.current(...args), []);
}
'

    # Insert the polyfill after the imports (after line 3, which is the jsx-runtime import)
    sed -i "4i\\$POLYFILL" "${RDG_DIR}/lib/index.js"

    echo "react-data-grid lib/index.js patched successfully"
else
    echo "react-data-grid not found at ${RDG_DIR}/lib/index.js, skipping patch"
fi
