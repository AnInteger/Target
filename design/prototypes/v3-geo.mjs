import { chromium } from 'playwright';
const b = await chromium.launch({ executablePath: '/home/sun/.cache/ms-playwright/chromium-1237/chrome-linux64/chrome' });
const p = await b.newPage({ viewport: { width: 1280, height: 1000 } });
let fails = 0;
const fail = m => { fails++; console.log('  ✗ ' + m); };
const pass = m => console.log('  ✓ ' + m);

// 1) 日历环居中 + 不溢出格子
console.log('== v3-activity 日历几何 ==');
await p.goto('http://127.0.0.1:8390/prototypes/v3-activity.html', { waitUntil: 'networkidle' });
const cal = await p.evaluate(() => {
  const board = document.querySelectorAll('.phone')[2];
  const days = [...board.querySelectorAll('.cal .grid .day')].filter(d => d.querySelector('.ring'));
  return days.map(d => {
    const dr = d.getBoundingClientRect(), r = d.querySelector('.ring').getBoundingClientRect();
    return {
      dayW: +dr.width.toFixed(1), ringW: +r.width.toFixed(1),
      fits: r.width <= dr.width + 0.5,
      cxOff: +Math.abs((r.left + r.width / 2) - (dr.left + dr.width / 2)).toFixed(1),
    };
  });
});
cal.every(c => c.fits) ? pass(`环均不溢出格子（${cal.length} 格）`) : fail('环溢出格子');
const maxOff = Math.max(...cal.map(c => c.cxOff));
maxOff <= 1 ? pass(`环水平居中偏差 ≤1px（max ${maxOff}）`) : fail(`环未居中 max=${maxOff}`);

// 2) 浮层菜单不越出手机画板
console.log('== 菜单越界检查 ==');
for (const [pg, idx] of [['v3-goals', 3], ['v3-goal-detail', 2], ['v3-milestones', 0]]) {
  await p.goto(`http://127.0.0.1:8390/prototypes/${pg}.html`, { waitUntil: 'networkidle' });
  const r = await p.evaluate(([i]) => {
    const ph = document.querySelectorAll('.phone')[i].getBoundingClientRect();
    const m = document.querySelectorAll('.phone')[i].querySelector('.menu').getBoundingClientRect();
    return { inR: m.right <= ph.right + 0.5, inB: m.bottom <= ph.bottom + 0.5, topOk: m.top >= ph.top };
  }, [idx]);
  r.inR && r.inB && r.topOk ? pass(`${pg} 菜单在画板内`) : fail(`${pg} 菜单越界 ${JSON.stringify(r)}`);
}

// 3) sheet 贴合画板底边且同宽
console.log('== sheet 贴合检查 ==');
for (const [pg, idx] of [['v3-activity', 2], ['v3-milestones', 1], ['v3-record-sheet', 0], ['v3-goal-editor', 0], ['v3-goal-editor', 1]]) {
  await p.goto(`http://127.0.0.1:8390/prototypes/${pg}.html`, { waitUntil: 'networkidle' });
  const r = await p.evaluate(([i]) => {
    const ph = document.querySelectorAll('.phone')[i].getBoundingClientRect();
    const s = document.querySelectorAll('.phone')[i].querySelector('.sheet').getBoundingClientRect();
    return { flush: Math.abs(s.bottom - ph.bottom) <= 1, width: +s.width.toFixed(1), phone: +ph.width.toFixed(1) };
  }, [idx]);
  r.flush && Math.abs(r.width - r.phone) <= 1 ? pass(`${pg}#${idx} sheet 贴底同宽`)
    : fail(`${pg}#${idx} sheet 异常 ${JSON.stringify(r)}`);
}

// 4) 记录钮图标补齐 + 菜单图标去重（本轮修复回归）
console.log('== 修复回归 ==');
await p.goto('http://127.0.0.1:8390/prototypes/v3-goals.html', { waitUntil: 'networkidle' });
const recIcons = await p.evaluate(() =>
  [...document.querySelectorAll('.rec')].filter(r => r.querySelector('svg')).length);
(recIcons === 4) ? pass(`goals 记录钮图标 4/4`) : fail(`goals 记录钮图标 ${recIcons}/4`);
await p.goto('http://127.0.0.1:8390/prototypes/v3-activity.html', { waitUntil: 'networkidle' });
const recIcons2 = await p.evaluate(() =>
  [...document.querySelectorAll('.rec')].filter(r => r.querySelector('svg')).length);
(recIcons2 === 4) ? pass(`activity 记录钮图标 4/4`) : fail(`activity 记录钮图标 ${recIcons2}/4`);
for (const pg of ['v3-goals', 'v3-goal-detail']) {
  await p.goto(`http://127.0.0.1:8390/prototypes/${pg}.html`, { waitUntil: 'networkidle' });
  const dupe = await p.evaluate(() => {
    const btns = [...document.querySelectorAll('.menu button')];
    const rec = btns.find(b => b.textContent.trim().startsWith('记录进展'));
    const edit = btns.find(b => b.textContent.trim() === '编辑');
    return rec.querySelector('svg').innerHTML === edit.querySelector('svg').innerHTML;
  });
  !dupe ? pass(`${pg} 菜单记录/编辑图标已区分`) : fail(`${pg} 菜单图标仍重复`);
}

// 5) 详情时间线节点在同一条竖直线上
console.log('== 时间线轨道对齐 ==');
await p.goto('http://127.0.0.1:8390/prototypes/v3-goal-detail.html', { waitUntil: 'networkidle' });
const railX = await p.evaluate(() => {
  const nodes = [...document.querySelectorAll('.phone')[0].querySelectorAll('.tl .node')];
  const xs = nodes.map(n => n.getBoundingClientRect().left);
  return + (Math.max(...xs) - Math.min(...xs)).toFixed(1);
});
railX <= 1 ? pass(`时间线节点 X 对齐（偏差 ${railX}px）`) : fail(`时间线节点不对齐 ${railX}px`);

await b.close();
console.log(fails === 0 ? '\n=== 几何检查全部通过 ✓ ===' : `\n=== 失败 ${fails} 项 ===`);
process.exit(fails ? 1 : 0);
