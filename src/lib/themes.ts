/** 主题定义与轮询辅助（与 index.css 中 data-theme 覆盖块一一对应） */

export interface ThemeDef {
  id: string;
  name: string;
  dark: boolean;
}

/** 全部主题（顺序即左下角轮询切换顺序） */
export const THEMES: ThemeDef[] = [
  { id: 'graphite', name: '石墨灰（浅色）', dark: false },
  { id: 'charcoal', name: '炭黑（深色）', dark: true },
  { id: 'violet-night', name: '暗夜紫', dark: true },
  { id: 'ink-green', name: '墨绿', dark: true },
  { id: 'amber-night', name: '琥珀暖夜', dark: true },
  { id: 'tech-blue', name: '科技蓝', dark: true },
];

export const DEFAULT_THEME = 'charcoal';

/** 兼容旧值（light/dark/system），解析为主题定义；system 按系统偏好；未知值归一为默认主题 */
export function resolveTheme(
  raw: string | undefined,
  systemPrefersDark: boolean,
): ThemeDef {
  if (raw) {
    const hit = THEMES.find((t) => t.id === raw);
    if (hit) return hit;
    if (raw === 'light') return THEMES[0];
    if (raw === 'dark') return THEMES[1];
    // 跟随系统：下拉框「跟随系统」落库值就是 system，必须按系统偏好解析，
    // 否则落到下方「未知值→默认深色」分支，选了跟没选一样（写死 charcoal）
    if (raw === 'system') return systemPrefersDark ? THEMES[1] : THEMES[0];
    // 未知主题值归一为默认主题，避免外部脏数据落库后 UI 走兜底分支不一致
    return THEMES.find((t) => t.id === DEFAULT_THEME) ?? THEMES[1];
  }
  return systemPrefersDark ? THEMES[1] : THEMES[0];
}

/** 计算下一个轮询主题（旧值先归一化；未知值先归一为默认主题，避免 findIndex=-1 跳位） */
export function nextTheme(raw: string | undefined): ThemeDef {
  let cur = raw ?? '';
  if (cur === 'light') cur = 'graphite';
  if (cur === 'dark' || cur === 'system' || !cur) cur = 'charcoal';
  if (!THEMES.some((t) => t.id === cur)) cur = DEFAULT_THEME;
  const idx = THEMES.findIndex((t) => t.id === cur);
  return THEMES[(idx + 1) % THEMES.length];
}
