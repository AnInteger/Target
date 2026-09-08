// 006 R1 送审前结构化校验（按画板作用域 + 自定义属性级联读取）
// 用法：python3 -m http.server 8390 -d design 后
//       node design/prototypes/v3-check.mjs（断言口径见 reviews.md 006 R1 条目）
import { chromium } from 'playwright';

const BASE = 'http://127.0.0.1:8390/prototypes/';
// [selector, expectedMax, mode, label]  —— max=所有画板中该选择器计数的最大值
const PAGES = {
  'v3-goals.html': {
    phones: 5,
    checks: [
      ['.dock .tabs .tab', 2, 'eq', 'dock 双 tab'],
      ['.dock .tab.on', 1, 'eq', '目标页签选中/板'],
      ['.pcard', 2, 'gte', '置顶大卡×2'],
      ['.lcard .lrow', 1, 'gte', '其他目标列表行'],
      ['.empty .cta', 1, 'eq', '空态 CTA'],
      ['.menu button', 7, 'eq', '管理菜单 7 项'],
      ['.menu button.danger', 1, 'eq', '危险组删除'],
      ['.pinrow', 2, 'gte', '置顶排序行（画板⑤）'],
      ['.pinrow .drag', 2, 'gte', '拖拽手柄'],
      ['.orow .pin', 1, 'gte', '其他目标图钉行'],
      ['.edtop .ok', 1, 'eq', '编辑完成钮'],
    ],
  },
  'v3-activity.html': {
    phones: 4,
    checks: [
      ['.bars .col', 7, 'eq', '柱状图 7 柱'],
      ['.msrow .n', 2, 'eq', '里程碑汇总双计数'],
      ['.frow', 2, 'gte', 'feed 条目'],
      ['.cal .grid .day', 13, 'gte', '日历格'],
      ['.cal .ring .val', 7, 'gte', '日历投入环'],
      ['.cal-day-sum', 1, 'eq', '点选日摘要'],
      ['.empty .t', 1, 'eq', '空周文案'],
    ],
  },
  'v3-goal-detail.html': {
    phones: 3,
    checks: [
      ['.tl', 2, 'gte', '时间线节点'],
      ['.node.n-orange', 1, 'gte', '里程碑达成节点'],
      ['.node.n-blue', 1, 'gte', '普通记录节点'],
      ['.paper .quote', 1, 'gte', '正文引用样式'],
      ['.cta', 1, 'eq', '记录进展 CTA/板'],
      ['.mscard', 1, 'eq', '里程碑卡/板'],
      ['.menu button', 7, 'eq', '⋯ 菜单 7 项'],
    ],
  },
  'v3-milestones.html': {
    phones: 2,
    checks: [
      ['.mrow', 2, 'gte', '接下来行'],
      ['.drow', 1, 'gte', '已达成行'],
      ['.menu button', 3, 'eq', '⋯ 菜单 3 项'],
      ['.sheet .fin', 2, 'eq', '添加 sheet 双输入'],
      ['.gcard', 1, 'eq', '目标卡/板'],
    ],
  },
  'v3-record-sheet.html': {
    phones: 4,
    checks: [
      ['.gs-row', 3, 'gte', '目标切换行（展开态）'],
      ['.meta .mrow', 3, 'eq', '时长/日期/里程碑三行'],
      ['.dur', 7, 'gte', '时长快捷档'],
      ['.editor .t-in', 1, 'eq', '标题输入/板'],
      ['.editor .b-in', 1, 'eq', '正文输入/板'],
      ['.slogon', 1, 'gte', '底部标语'],
    ],
  },
  'v3-goal-editor.html': {
    phones: 4,
    checks: [
      ['.row-btn', 5, 'gte', '属性行（分类/图标/置顶/日期/节奏）'],
      ['.chips .chip', 4, 'gte', '节奏四档 chips'],
      ['.ms-item', 2, 'gte', '里程碑列表项'],
      ['.toggle.on', 1, 'gte', '开关开态'],
      ['.ms-add', 1, 'eq', '添加里程碑行'],
      ['.fnote', 1, 'gte', '分组说明'],
    ],
  },
  'v3-settings.html': {
    phones: 3,
    checks: [
      ['.profile', 1, 'eq', '资料卡/板'],
      ['.seg button', 3, 'eq', '外观三档'],
      ['.row-btn', 2, 'gte', '设置行'],
      ['.alert .acts button', 2, 'eq', '冲突弹层双动作'],
      ['.foot', 1, 'gte', '关于脚注'],
    ],
  },
  'v3-widget.html': {
    phones: 0,
    boards: '.wall',
    boardCount: 2,
    checks: [
      ['.wg.small', 1, 'eq', 'small 组件/板'],
      ['.wg.medium', 1, 'eq', 'medium 组件/板'],
      ['.medium .latest .t', 1, 'eq', '最近记录标题/板'],
      ['.medium .nums .big', 1, 'eq', '今日计数/板'],
    ],
  },
};

const ACC = { light: '#007aff', dark: '#0a84ff' };

let failures = 0;
const fail = (p, m) => { failures++; console.log(`  ✗ [${p}] ${m}`); };
const pass = (p, m) => console.log(`  ✓ [${p}] ${m}`);

const browser = await chromium.launch({
  executablePath: '/home/sun/.cache/ms-playwright/chromium-1237/chrome-linux64/chrome',
});
const page = await browser.newPage({ viewport: { width: 1280, height: 1000 } });
const pageErrors = [];
page.on('pageerror', e => pageErrors.push(String(e)));

for (const [file, cfg] of Object.entries(PAGES)) {
  console.log(`\n== ${file} ==`);
  await page.goto(BASE + file, { waitUntil: 'networkidle' });
  const boardSel = cfg.phones > 0 ? '.phone' : cfg.boards;

  const boards = await page.locator(boardSel).count();
  const wantBoards = cfg.phones > 0 ? cfg.phones : cfg.boardCount;
  boards === wantBoards ? pass(file, `画板 ×${boards}`) : fail(file, `画板数 ${boards} ≠ ${wantBoards}`);

  // 按画板计数取 max
  for (const [sel, n, mode, label] of cfg.checks) {
    const max = await page.evaluate(([bs, s]) => {
      let m = 0;
      document.querySelectorAll(bs).forEach(b => {
        m = Math.max(m, b.querySelectorAll(s).length);
      });
      return m;
    }, [boardSel, sel]);
    const ok = mode === 'eq' ? max === n : max >= n;
    ok ? pass(file, `${label} max=${max}`) : fail(file, `${label} max=${max}（期望 ${mode} ${n}）`);
  }

  // 横向溢出
  const overflow = await page.evaluate((bs) => {
    const bad = [];
    document.querySelectorAll(bs).forEach((b, i) => {
      if (b.scrollWidth > b.clientWidth + 1) bad.push(`board#${i} ${b.scrollWidth}>${b.clientWidth}`);
      b.querySelectorAll('.scroll,.sh-body').forEach(el => {
        if (el.scrollWidth > el.clientWidth + 1)
          bad.push(`board#${i} ${el.className.split(' ')[0]} ${el.scrollWidth}>${el.clientWidth}`);
      });
    });
    return bad;
  }, boardSel);
  overflow.length === 0 ? pass(file, '无横向溢出')
    : overflow.slice(0, 5).forEach(o => fail(file, `横向溢出 ${o}`));

  // 令牌级联：--accent / --milestone 浅深成对解析
  if (cfg.phones > 0) {
    const tokens = await page.evaluate((bs) => {
      const out = [];
      document.querySelectorAll(bs).forEach(b => {
        const cs = getComputedStyle(b);
        out.push({
          dark: b.getAttribute('data-theme') === 'dark',
          accent: cs.getPropertyValue('--accent').trim().toLowerCase(),
          milestone: cs.getPropertyValue('--milestone').trim().toLowerCase(),
          surface: cs.getPropertyValue('--surface').trim().toLowerCase(),
        });
      });
      return out;
    }, boardSel);
    const lights = tokens.filter(t => !t.dark), darks = tokens.filter(t => t.dark);
    (lights.length === 0 || lights.every(t => t.accent === ACC.light))
      ? pass(file, `浅色 --accent=${ACC.light}`) : fail(file, `浅色 --accent 异常：${[...new Set(lights.map(t => t.accent))].join(',')}`);
    (darks.length === 0 || darks.every(t => t.accent === ACC.dark))
      ? pass(file, `深色 --accent=${ACC.dark}`) : fail(file, `深色 --accent 异常：${[...new Set(darks.map(t => t.accent))].join(',')}`);
    const surfOk = tokens.every(t => t.dark ? t.surface === '#1c1c1e' : t.surface === '#ffffff');
    surfOk ? pass(file, 'surface 浅深成对') : fail(file, `surface 异常：${[...new Set(tokens.map(t => t.surface))].join(',')}`);
  }

  // 玻璃（存在才断言）：dock 胶囊 / 菜单 / 小组件
  const glass = await page.evaluate((bs) => {
    const out = [];
    document.querySelectorAll(bs).forEach(b => {
      const el = b.querySelector('.dock .tabs') || b.querySelector('.menu') || b.querySelector('.wg');
      if (el) {
        const cs = getComputedStyle(el);
        out.push(cs.getPropertyValue('backdrop-filter') || cs.getPropertyValue('-webkit-backdrop-filter'));
      }
    });
    return out;
  }, boardSel);
  if (glass.length === 0) pass(file, '玻璃面：本页无（solid sheet，符合设计）');
  else glass.every(g => g.includes('blur'))
    ? pass(file, `玻璃 backdropFilter ×${glass.length} 生效`) 
    : fail(file, `玻璃 backdropFilter 异常：${glass.filter(g => !g.includes('blur')).length}/${glass.length}`);
}

pageErrors.length === 0 ? console.log('\nJS 错误：无') : pageErrors.forEach(e => fail('*', `pageerror ${e}`));
await browser.close();
console.log(failures === 0 ? '\n=== 全部通过 ✓ ===' : `\n=== 失败 ${failures} 项 ===`);
process.exit(failures === 0 ? 0 : 1);
