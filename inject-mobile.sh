#!/bin/sh
# 在官方 aiwork-server 镜像的 dist/index.html 注入移动端修复 CSS。
# 纯 shell + awk（运行级 debian-slim 无 python）。
set -eu

HTML=/app/dist/index.html
[ -f "$HTML" ] || { echo "index.html not found"; exit 1; }
grep -q 'MOBILE-FIX-INJECTED' "$HTML" && { echo 'already injected'; exit 0; }

cat > /mobile-fix.css <<'CSSEOF'
<style>
/* MOBILE-FIX-INJECTED */
@media (max-width: 767px) {
  /* 1. 顶部操作按钮组：允许换行，不再撑破整页 */
  .mb-5.flex.items-end.justify-between { flex-wrap: wrap !important; }
  .mb-5.flex.items-end.justify-between .flex.items-center.gap-2 {
    flex-wrap: wrap !important; width: 100% !important;
    max-width: 100% !important; overflow: visible !important;
  }
  .mb-5.flex.items-end.justify-between .btn-outline {
    padding-left: .55rem !important; padding-right: .55rem !important; font-size: 12px !important;
  }

  /* 2. 表格在卡片内部横向滚动，不再撑宽整页 */
  .card.overflow-hidden { overflow-x: auto !important; -webkit-overflow-scrolling: touch; }

  /* 3. grid/flex 子项允许收缩，修复环境配置页 464px 撑宽 */
  .grid > *, .gridcard, [class*="grid-cols"] > * { min-width: 0 !important; }
  .card.p-4 { min-width: 0 !important; max-width: 100% !important; }
  .rounded-lg.bg-slate-50, .rounded-lg.bg-zinc-900 { min-width: 0 !important; max-width: 100% !important; }
  input[type="range"] { max-width: 100% !important; }

  /* 4. 通用 flex 行换行 */
  .flex.items-center.gap-2 { flex-wrap: wrap; }

  /* 5. 弹窗（帮助等）：限制最大高度 + 内容可上下滚动，修复"上下滑不了" */
  .fixed.inset-0.z-50 { overflow-y: auto !important; -webkit-overflow-scrolling: touch; align-items: flex-start !important; }
  .fixed.inset-0.z-50 > .card,
  .fixed.inset-0.z-50 .card.relative {
    max-height: calc(100dvh - 2rem) !important;
    overflow-y: auto !important;
    -webkit-overflow-scrolling: touch;
  }

  /* 6. 资源调度页 grid-cols-12 手机上改单列，模型 ID 不再被挤成半宽 */
  .grid.grid-cols-12 { display: flex !important; flex-direction: column !important; }
  .grid.grid-cols-12 > * { width: 100% !important; max-width: 100% !important; }
  .col-span-6, [class*="col-span-"] { width: 100% !important; max-width: 100% !important; }

  /* 7. 积分看板账号/分组下拉浮层定位溢出屏幕左侧，改为左对齐 */
  .absolute.right-0.z-30 { left: 0 !important; right: auto !important; }

  /* 8. API 管理弹窗：Tab 栏 7 个按钮横向滚动（不再挤成重叠文字） */
  .mt-4.flex.items-center.gap-1.border-b { overflow-x: auto !important; flex-wrap: nowrap !important; -webkit-overflow-scrolling: touch; }
  .mt-4.flex.items-center.gap-1.border-b > button { flex: 0 0 auto !important; white-space: nowrap !important; padding-left: .75rem !important; padding-right: .75rem !important; font-size: 13px !important; }
  /* 内容区高度改为手机可用高度（排除弹窗的 max-h-[calc，避免与第9组冲突） */
  [class*="h-[calc(100vh"]:not([class*="max-h-[calc"]) { height: calc(100dvh - 300px) !important; min-height: 200px !important; }

  /* 9. 白名单等二级子弹窗：修复被主弹窗裁切/高度不足看不到内容 */
  /* 主弹窗 body（max-h）在手机上给足高度，内容可滚 */
  [class*="max-h-[calc(100vh"] { max-height: calc(100dvh - 7rem) !important; min-height: 240px !important; height: auto !important; }
  /* 子弹窗内模型列表给足高度 */
  .max-h-72 { max-height: 42vh !important; }
  /* 让后渲染的（二级）弹窗层级更高，避免被主弹窗盖住 */
  .fixed.inset-0.z-50 ~ .fixed.inset-0.z-50 { z-index: 60 !important; }
}
</style>
CSSEOF

awk '
  /<\/head>/ {
    while ((getline line < "/mobile-fix.css") > 0) print line
    close("/mobile-fix.css")
  }
  { print }
' "$HTML" > /tmp/index.new && mv /tmp/index.new "$HTML"

rm -f /mobile-fix.css
grep -q 'MOBILE-FIX-INJECTED' "$HTML" && echo "injected ok" || { echo "injection failed"; exit 1; }
