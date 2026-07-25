const state = {
  project: null,
  status: null,
};

const $ = (id) => document.getElementById(id);

function projectId() {
  return state.project?.id || 'cailiao';
}

async function api(path, body) {
  const options = body ? {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify(body),
  } : {};
  const res = await fetch(path, options);
  const data = await res.json();
  if (!res.ok || data.ok === false) throw new Error(data.error || res.statusText);
  return data;
}

function shortHash(hash) {
  return hash ? `${hash.slice(0, 8)}…` : '-';
}

function renderStatus(data) {
  state.status = data;
  state.project = data.projects[0];
  const p = state.project || {};
  $('projectName').textContent = p.name || '未配置项目';
  $('projectMeta').textContent = `${p.github || ''} · ${p.windows_repo || ''}`;
  $('headCommit').textContent = shortHash(p.head);
  $('dirtyState').textContent = p.dirty ? '有改动' : '干净';
  $('runnerState').textContent = p.runner_ready ? 'ready' : '未就绪';
  $('reportState').textContent = p.report_file?.exists ? `${p.report_file.size} bytes` : '未生成';
  $('diffBox').textContent = (p.diff_stat || []).join('\n') || '无未提交 diff';
  renderStages(data.stages?.stages || []);
  renderEvents(data.state?.events || []);
  if (!$('taskText').value.trim()) $('taskText').value = defaultTaskText(p, data.stages || {});
}

function renderStages(stages) {
  $('stageList').innerHTML = stages.map((stage) => `
    <div class="stage ${stage.status}">
      <span class="dot"></span>
      <div>
        <div class="label"><span>${escapeHtml(stage.name)}</span><small>${escapeHtml(stage.status)}</small></div>
        <p class="hint">${escapeHtml(stage.note || stage.branch || '')}</p>
      </div>
    </div>
  `).join('');
}

function renderEvents(events) {
  $('eventList').innerHTML = events.slice().reverse().slice(0, 25).map((event) => `
    <div class="event ${event.status}">
      <span class="dot"></span>
      <div>
        <div class="label"><span>${escapeHtml(event.action)}</span><small>${escapeHtml(event.status)}</small></div>
        <p class="hint">${escapeHtml(event.at)} · ${escapeHtml(event.summary || '')}${event.log ? ` · ${escapeHtml(event.log)}` : ''}</p>
      </div>
    </div>
  `).join('') || '<p class="hint">暂无事件。</p>';
}

function renderGates(result) {
  const items = result.results || [];
  $('gateList').innerHTML = items.map((item) => `
    <div class="gate ${item.ok ? 'pass' : 'fail'}">
      <span class="dot"></span>
      <div>
        <div class="label"><span>${escapeHtml((item.args || []).join(' '))}</span><small>${item.ok ? 'pass' : 'fail'}</small></div>
        <p class="hint">exit=${escapeHtml(item.code)} · ${escapeHtml(item.duration_sec)}s</p>
        <pre>${escapeHtml([item.stdout, item.stderr].filter(Boolean).join('\n') || '无输出')}</pre>
      </div>
    </div>
  `).join('');
}

function defaultTaskText(project, stages) {
  const stage = stages.current_stage || 'unknown';
  return `你是隔离环境里的 Claude Code。请严格执行本任务；Claude 只在隔离工作区修改文件，Codex 负责测试、审查、GitHub commit/push。不要运行 Git，不要 push，不要读取凭据。

目标项目：${project.github || ''}
当前阶段：${stage}
工作目录：${project.wsl_repo || ''}

请先阅读 README.md、docs/ROADMAP.md、CODEX_HANDOFF.json。

任务：
根据当前阶段提出并实现一个最小可验收切片；如上下文不足，写明需要 Codex 提供什么。

完成后把交付报告写入：${project.report_file?.path || '/home/kiro/kiro-work/work/CLAUDE_TO_CODEX.md'}
报告包含：修改文件、实现能力、未实现内容、建议 Codex 执行的测试、已知风险。`;
}

function escapeHtml(text) {
  return String(text ?? '').replace(/[&<>"']/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}

async function refresh() {
  renderStatus(await api('/api/status'));
}

async function runAction(action, extra = {}) {
  const result = await api('/api/action', {project_id: projectId(), action, ...extra});
  await refresh();
  return result;
}

document.querySelectorAll('.nav').forEach((button) => {
  button.addEventListener('click', () => {
    document.querySelectorAll('.nav').forEach((b) => b.classList.toggle('active', b === button));
    document.querySelectorAll('.view').forEach((view) => view.classList.toggle('active', view.id === button.dataset.view));
  });
});

$('refreshBtn').addEventListener('click', refresh);
$('fetchBtn').addEventListener('click', () => runAction('fetch').catch((err) => alert(err.message)));
$('remoteBtn').addEventListener('click', async () => {
  try {
    const result = await runAction('remote_main');
    $('diffBox').textContent = result.stdout || result.stderr || '无输出';
  } catch (err) {
    alert(err.message);
  }
});
$('diffBtn').addEventListener('click', async () => {
  try {
    const result = await runAction('diff_stat');
    $('diffBox').textContent = result.stdout || result.stderr || '无输出';
  } catch (err) {
    alert(err.message);
  }
});
$('writeTaskBtn').addEventListener('click', async () => {
  try {
    const result = await runAction('write_task', {task: $('taskText').value});
    alert(`已写入 ${result.path} (${result.bytes} bytes)`);
  } catch (err) {
    alert(err.message);
  }
});
$('readReportBtn').addEventListener('click', async () => {
  try {
    const result = await api(`/api/report?project=${encodeURIComponent(projectId())}`);
    $('reportBox').textContent = result.content || result.stderr || '无报告';
  } catch (err) {
    $('reportBox').textContent = err.message;
  }
});
$('runGatesBtn').addEventListener('click', async () => {
  $('gateList').innerHTML = '<p class="hint">门禁运行中...</p>';
  try {
    renderGates(await runAction('run_gates'));
  } catch (err) {
    $('gateList').innerHTML = `<p class="hint">${escapeHtml(err.message)}</p>`;
  }
});

refresh().catch((err) => {
  document.body.innerHTML = `<pre>控制台启动失败：${escapeHtml(err.message)}</pre>`;
});
