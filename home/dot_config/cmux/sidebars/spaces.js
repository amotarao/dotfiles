// spaces: two-section sidebar.
//   spaces  - "all" plus one row per repository (worktrees folded in) with
//             the most urgent agent state glyph, tap to jump.
//   workspaces - coding-agent sessions plus agent-less workspaces of the
//             selected space (or every space, grouped by space, under "all"),
//             tap to jump to the terminal.

const [showAll, setShowAll] = signal(false);

const STATE = {
  needs_input: { glyph: "!", color: "#FF9F0A", rank: 0 },
  working: { glyph: "◐", color: "#0A84FF", rank: 1 },
  idle: { glyph: "○", color: "#E5C07B", rank: 2 },
  ended: { glyph: "·", color: "#7f7f7f88", rank: 3 },
};
const NONE = { glyph: "·", color: "#7f7f7f88", rank: 9 };
const stateOf = (status) => STATE[status] ?? NONE;

// The most urgent live agent decides the workspace glyph.
function wsState(w) {
  let best = NONE;
  for (const a of w.agents ?? []) {
    const s = stateOf(a.status);
    if (s.rank < best.rank) best = s;
  }
  return best;
}

const dirTail = (d) => {
  const parts = String(d ?? "").split("/").filter((p) => p.length > 0);
  return parts.length ? parts[parts.length - 1] : "";
};

function sectionHeader(label, trailing) {
  return HStack({ spacing: 6 }, [
    Text(label).font(12).weight("semibold").monospaced().color("secondary")
      .lineLimit(1).truncation("tail"),
    Spacer(),
    ...(trailing ? [trailing.layoutPriority(2)] : []),
  ]).paddingHorizontal(8).paddingVertical(4);
}

// Fixed-width, right-aligned trailing columns so numbers line up across rows.
function countColumn(textFn) {
  return Text(textFn)
    .font(10).monospaced().color("tertiary").lineLimit(1)
    .frame({ width: 26, alignment: "trailing" })
    .layoutPriority(2);
}

// "• {unread}" sits just left of the count column and is empty when read.
function unreadBadge(countFn) {
  return Text(() => (countFn() > 0 ? "• " + countFn() : ""))
    .font(10).monospaced().color("#FF9F0A").lineLimit(1)
    .layoutPriority(2);
}

// ---- spaces ---------------------------------------------------------------
// A space is a repository: workspaces are bucketed by directory, with
// worktrees under .local/worktree/ folded into their main checkout.

// Directory below ~/works/ (e.g. "org/repo"); custom sidebars cannot run git.
const worksPath = (key) => {
  const i = key.indexOf("/works/");
  return i >= 0 ? key.slice(i + "/works/".length) : "";
};

// owner/repo from a GitHub PR url, used for spaces outside ~/works/.
const repoFromPr = (url) => {
  const m = String(url ?? "").match(/github\.com\/([^/]+\/[^/]+)\/pull\//);
  return m ? m[1] : "";
};

const spaceKey = (dir) => String(dir ?? "").split("/.local/worktree/")[0].replace(/\/+$/, "");
const spaceOf = (w) => spaceKey(w.directory) || "(no dir)";

const spaces = computed(() => {
  const map = new Map();
  for (const w of data.workspaces() ?? []) {
    const key = spaceOf(w);
    let sp = map.get(key);
    if (!sp) {
      sp = { key, name: dirTail(key) || key, members: [], selected: false, unread: 0, state: NONE };
      map.set(key, sp);
    }
    sp.members.push(w);
    sp.unread += w.unread ?? 0;
    if (w.selected) sp.selected = true;
    const st = wsState(w);
    if (st.rank < sp.state.rank) sp.state = st;
  }
  for (const sp of map.values()) {
    // Tap target: the selected workspace if it lives here, else the most
    // recently active one.
    const pick = sp.members.find((w) => w.selected)
      ?? [...sp.members].sort((x, y) => (y.latestAt ?? 0) - (x.latestAt ?? 0))[0];
    sp.target = pick.id;
    sp.origin = worksPath(sp.key)
      || sp.members.map((w) => repoFromPr(w.pr?.url)).find((r) => r) || "";
  }
  return [...map.values()];
});

function spaceRow(sp) {
  return HStack({ spacing: 8 }, [
    Text(() => sp().state.glyph)
      .font(11).monospaced()
      .color(() => sp().state.color)
      .frame({ width: 12 }),
    VStack({ spacing: 1 }, [
      Text(() => sp().name)
        .font(12).monospaced()
        .weight(() => (sp().selected ? "bold" : "regular"))
        .color(() => (sp().selected ? "primary" : "secondary"))
        .lineLimit(1).truncation("tail")
        .frame({ maxWidth: "infinity", alignment: "leading" }),
      Text(() => sp().origin)
        .font(11).monospaced()
        .color(() => (sp().selected ? "#C678DD" : "tertiary"))
        .lineLimit(1).truncation("middle")
        .frame({ maxWidth: "infinity", alignment: "leading" }),
    ]),
    unreadBadge(() => sp().unread),
    countColumn(() => (sp().members.length > 1 ? String(sp().members.length) : "")),
  ])
    .paddingHorizontal(8).paddingVertical(3)
    .background(() => (sp().selected && !showAll() ? "#7f7f7f2e" : null))
    .hoverBackground("#7f7f7f1c")
    .frame({ maxWidth: "infinity" })
    .onTap(() => {
      setShowAll(false);
      cmux("workspace.select", { workspace_id: sp().target });
    });
}

function allRow() {
  const state = () => {
    let best = NONE;
    for (const sp of spaces()) if (sp.state.rank < best.rank) best = sp.state;
    return best;
  };
  return HStack({ spacing: 8 }, [
    Text(() => state().glyph)
      .font(11).monospaced()
      .color(() => state().color)
      .frame({ width: 12 }),
    Text("すべて")
      .font(12).monospaced()
      .weight(() => (showAll() ? "bold" : "regular"))
      .color(() => (showAll() ? "primary" : "secondary"))
      .lineLimit(1)
      .frame({ maxWidth: "infinity", alignment: "leading" }),
    unreadBadge(() => data.unreadTotal() ?? 0),
    countColumn(() => String(data.workspaceCount() ?? 0)),
  ])
    .paddingHorizontal(8).paddingVertical(3)
    .background(() => (showAll() ? "#7f7f7f2e" : null))
    .hoverBackground("#7f7f7f1c")
    .frame({ maxWidth: "infinity" })
    .onTap(() => setShowAll(true));
}

// ---- workspaces -----------------------------------------------------------

// Agents are scoped to the space of the selected workspace.
const currentSpace = computed(() => {
  const sel = (data.workspaces() ?? []).find((w) => w.selected);
  return sel ? spaceOf(sel) : null;
});

// Flat in a single space; under "all", one header per space.
const agentEntries = computed(() => {
  const out = [];
  const all = showAll();
  const cur = currentSpace();
  for (const sp of spaces()) {
    if (!all && sp.key !== cur) continue;
    const rows = [];
    for (const w of sp.members) {
      const live = (w.agents ?? []).filter((a) => a.status !== "ended");
      // Workspaces without a live agent still get a plain row, sorted last.
      if (live.length === 0) {
        rows.push({ key: "w:" + w.id, kind: "workspace", ws: w, rank: NONE.rank });
        continue;
      }
      for (const a of live) {
        rows.push({ key: "a:" + w.id + ":" + a.id, kind: "agent", ws: w, agent: a, rank: stateOf(a.status).rank });
      }
    }
    if (rows.length === 0) continue;
    rows.sort((x, y) => x.rank - y.rank);
    if (all) out.push({ key: "h:" + sp.key, kind: "header", label: sp.name, target: sp.target });
    out.push(...rows);
  }
  return out;
});

function jump(entry) {
  cmux("workspace.select", { workspace_id: entry.ws.id });
  if (entry.agent?.surfaceId) cmux("surface.focus", { surface_id: entry.agent.surfaceId });
}

function agentHeaderRow(e) {
  return Text(() => e().label)
    .font(10).monospaced().color("tertiary")
    .lineLimit(1).truncation("tail")
    .paddingHorizontal(8).paddingTop(4)
    .frame({ maxWidth: "infinity", alignment: "leading" })
    .onTap(() => cmux("workspace.select", { workspace_id: e().target }));
}

function agentRow(e) {
  const a = () => e().agent;
  return HStack({ spacing: 8 }, [
    Text(() => stateOf(a().status).glyph)
      .font(11).monospaced()
      .color(() => stateOf(a().status).color)
      .frame({ width: 12 }),
    VStack({ spacing: 1 }, [
      Text(() => e().ws.title || a().title || dirTail(a().directory) || "untitled")
        .font(12).monospaced()
        .weight(() => (e().ws.selected ? "bold" : "regular"))
        .color(() => (e().ws.selected ? "primary" : "secondary"))
        .lineLimit(1).truncation("tail")
        .frame({ maxWidth: "infinity", alignment: "leading" }),
      Text(() => [a().kind || a().name, a().status === "idle" ? "" : a().status.replace("_", " ")]
        .filter((s) => s).join(" · "))
        .font(11).monospaced().color("tertiary")
        .lineLimit(1)
        .frame({ maxWidth: "infinity", alignment: "leading" }),
    ]),
  ])
    .paddingHorizontal(8).paddingVertical(3)
    .background(() => (e().ws.selected ? "#7f7f7f2e" : null))
    .hoverBackground("#7f7f7f1c")
    .frame({ maxWidth: "infinity" })
    .onTap(() => jump(e()));
}

function workspaceRow(e) {
  return HStack({ spacing: 8 }, [
    Text(NONE.glyph)
      .font(11).monospaced()
      .color(NONE.color)
      .frame({ width: 12 }),
    VStack({ spacing: 1 }, [
      Text(() => e().ws.title || dirTail(e().ws.directory) || "untitled")
        .font(12).monospaced()
        .weight(() => (e().ws.selected ? "bold" : "regular"))
        .color(() => (e().ws.selected ? "primary" : "secondary"))
        .lineLimit(1).truncation("tail")
        .frame({ maxWidth: "infinity", alignment: "leading" }),
      Text("no agent")
        .font(11).monospaced().color("tertiary")
        .lineLimit(1)
        .frame({ maxWidth: "infinity", alignment: "leading" }),
    ]),
  ])
    .paddingHorizontal(8).paddingVertical(3)
    .background(() => (e().ws.selected ? "#7f7f7f2e" : null))
    .hoverBackground("#7f7f7f1c")
    .frame({ maxWidth: "infinity" })
    .onTap(() => jump(e()));
}

// ---- layout ---------------------------------------------------------------

sidebar(() =>
  VStack({ spacing: 4 }, [
    sectionHeader("Spaces"),
    allRow(),
    ForEach({ items: spaces, key: (sp) => sp.key }, spaceRow),
    Divider().paddingVertical(6),
    sectionHeader("Workspaces"),
    ForEach(
      { items: agentEntries, key: (e) => e.key },
      (e) => {
        const kind = e().kind;
        if (kind === "header") return agentHeaderRow(e);
        if (kind === "workspace") return workspaceRow(e);
        return agentRow(e);
      }
    ),
    Text(() => (agentEntries().length === 0 ? "no workspaces" : ""))
      .font(11).monospaced().color("tertiary").paddingHorizontal(8),
    Spacer(),
  ]).paddingHorizontal(4)
)
