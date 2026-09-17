---
name: bugs_happydom_raf_focus
description: happy-dom テスト環境で requestAnimationFrame ベースの focus() が発火せず activeElement アサーションが落ちる
metadata: 
  node_type: memory
  type: reference
  originSessionId: 199aa3a7-0af5-4d8c-8509-a38e471834c6
---

Desktop vitest は `environment: "happy-dom"` (vite.config.ts、perf 理由で jsdom から移行)。

**罠**: コンポーネントが `window.requestAnimationFrame(() => ref.current?.focus())` で
フィードバック行等にフォーカスを移すと、happy-dom では rAF が waitFor のポーリング内で
確実に発火せず `expect(document.activeElement).toBe(el)` が `<body>` のまま落ちる。
jsdom 時代は通っていたテストが happy-dom 移行後に壊れるパターン。

**修正**: rAF をやめて `useEffect(() => { if (state) ref.current?.focus(); }, [state])` で
描画後フォーカスに置き換える。jsdom/happy-dom 両対応かつ React idiomatic。
実例: `desktop/src/components/decision/PriorityQueuePanel.tsx` の feedback フォーカス。

jsdom が必須なテスト (canvas/cytoscape 等) はファイル先頭に `@vitest-environment jsdom` docblock。

関連: [[bugs_vitest_reactquery_rejection]] [[desktop_test_patterns]]
