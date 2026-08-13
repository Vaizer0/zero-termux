/* Zero-Termux — shared site behavior: nav, copy, explorers, search, meta */
(function () {
  "use strict";

  var $ = function (sel, ctx) { return (ctx || document).querySelector(sel); };
  var $$ = function (sel, ctx) { return Array.prototype.slice.call((ctx || document).querySelectorAll(sel)); };

  /* =========================================================
   * Navigation (mobile toggle + active link)
   * ========================================================= */
  function initNav() {
    var toggle = $(".nav-toggle");
    var links = $(".nav-links");
    if (toggle && links) {
      toggle.addEventListener("click", function () {
        var open = links.classList.toggle("open");
        toggle.setAttribute("aria-expanded", open ? "true" : "false");
        toggle.setAttribute("aria-label", open ? "Close menu" : "Menu");
      });
      // close the menu after following a link (mobile)
      $$("a", links).forEach(function (a) {
        a.addEventListener("click", function () { links.classList.remove("open"); });
      });
      // Escape closes the menu
      document.addEventListener("keydown", function (e) {
        if (e.key === "Escape") { links.classList.remove("open"); }
      });
    }
    var here = location.pathname.split("/").pop() || "index.html";
    $$(".nav-links a").forEach(function (a) {
      var href = a.getAttribute("href");
      if (href && href.split("#")[0] === here) a.classList.add("active");
    });
  }

  /* =========================================================
   * Copy-to-clipboard with fallback
   * ========================================================= */
  function copyText(txt, btn) {
    var label = btn.getAttribute("data-label") || btn.textContent;
    function done() {
      var old = btn.textContent;
      btn.textContent = "COPIED ✓";
      btn.classList.add("copied");
      btn.setAttribute("aria-live", "polite");
      setTimeout(function () {
        btn.textContent = old;
        btn.classList.remove("copied");
      }, 1600);
    }
    function fail() {
      var old = btn.textContent;
      btn.textContent = "COPY FAILED";
      btn.classList.add("failed");
      setTimeout(function () {
        btn.textContent = old;
        btn.classList.remove("failed");
      }, 1600);
    }
    function fallback() {
      var ta = document.createElement("textarea");
      ta.value = txt;
      ta.setAttribute("readonly", "");
      ta.style.position = "fixed";
      ta.style.top = "0";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.focus();
      ta.select();
      ta.setSelectionRange(0, txt.length);
      var ok = false;
      try { ok = document.execCommand("copy"); } catch (e) {}
      document.body.removeChild(ta);
      ok ? done() : fail();
    }
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(txt).then(done, fallback);
    } else {
      fallback();
    }
  }

  function initCopy() {
    // Static copy buttons: <button class="copy-btn" data-copy="text">
    $$("[data-copy]").forEach(function (btn) {
      if (btn.__zcCopy) return;
      btn.__zcCopy = true;
      btn.addEventListener("click", function () {
        copyText(btn.getAttribute("data-copy"), btn);
      });
    });
    // Copy buttons for <pre><code> blocks. Skip pre blocks that:
    //   - already contain a copy button,
    //   - are inside an explorer wrapper (re-rendered by JS),
    //   - are marked non-copyable (class="no-copy"),
    //   - are paired with an existing static data-copy button in the same
    //     container (avoids double buttons next to the hero install command).
    $$("pre").forEach(function (pre) {
      if (pre.classList.contains("no-copy")) return;
      if ($("[data-explorer]", pre)) return;
      if (pre.querySelector(".copy-btn")) return;
      var host = pre.parentElement;
      if (host && $(".copy-btn[data-copy]", host)) return;
      var btn = document.createElement("button");
      btn.className = "copy-btn";
      btn.textContent = "COPY";
      btn.setAttribute("type", "button");
      btn.setAttribute("aria-label", "Copy code block");
      btn.addEventListener("click", function () {
        copyText(pre.innerText.replace(/\n$/, ""), btn);
      });
      pre.appendChild(btn);
    });
  }

  /* =========================================================
   * Helpers
   * ========================================================= */
  function esc(s) {
    return String(s == null ? "" : s)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;").replace(/'/g, "&#39;");
  }

  function debounce(fn, ms) {
    var t;
    return function () {
      clearTimeout(t);
      var args = arguments;
      t = setTimeout(function () { fn.apply(null, args); }, ms);
    };
  }

  /* Simple term scoring: exact/prefix name hits outrank substring hits. */
  function scoreItem(item, q) {
    var fields = item._haystack || "";
    if (!q) return 0;
    if (item.name === q) return 200;
    if (item.name.indexOf(q) === 0) return 150;
    var idx = fields.indexOf(q);
    if (idx === -1) return 0;
    return idx === 0 ? 120 : 80;
  }

  /* =========================================================
   * Explorers (commands / modules / packages)
   *
   * The page must place the search input, category select and
   * meta line INSIDE the [data-explorer] container so all the
   * controls stay wired to the data set.
   * ========================================================= */
  function renderCommands(list) {
    return list.map(function (c) {
      var ex = (c.examples || []).map(function (e) {
        return '<div class="cmd"><code>zero ' + esc(e.replace(/^zero\s+/, "")) + "</code></div>";
      }).join("");
      return (
        "<details><summary>zero " + esc(c.name) + "</summary><div class='body'>" +
        "<p>" + esc(c.summary) + "</p>" +
        (c.syntax ? "<pre><code>" + esc(c.syntax) + "</code></pre>" : "") +
        (ex ? "<p><strong>Examples</strong></p>" + ex : "") +
        (c.notes ? "<p><em>" + esc(c.notes) + "</em></p>" : "") +
        "</div></details>"
      );
    }).join("");
  }

  function renderModules(list) {
    return list.map(function (m) {
      var tools = m.tools.map(function (t) {
        return (
          '<div class="card tool-card"><h3><span class="mono">' + esc(t.name) + "</span>" +
          (t.category ? '<span class="chip">' + esc(t.category) + "</span>" : "") + "</h3>" +
          "<p>" + esc(t.blurb) + "</p>" +
          '<div class="cmd-row"><span class="cmd">' + esc(t.install) + "</span>" +
          '<button type="button" class="copy-btn inline" data-copy="' + esc(t.install) + '" aria-label="Copy install command">COPY</button></div></div>'
        );
      }).join("");
      return (
        '<section class="mod-group" id="' + esc(m.name) + '" data-name="' + esc(m.name).toLowerCase() + '" data-title="' + esc(m.title).toLowerCase() + '">' +
        '<h2><span class="mono">' + esc(m.name) + "</span> — " + esc(m.title) +
        ' <span class="count">' + m.tools.length + " tool" + (m.tools.length === 1 ? "" : "s") + "</span>" +
        '<button type="button" class="copy-btn inline" data-copy="' + esc(m.install) + '" aria-label="Copy module install command">COPY</button></h2>' +
        "<p>" + esc(m.description) + "</p>" +
        '<div class="grid">' + tools + "</div></section>"
      );
    }).join("");
  }

  function renderPackages(list) {
    var rows = list.map(function (p) {
      return (
        "<tr><td><strong>" + esc(p.name) + "</strong>" +
        '<div class="cmd-row"><span class="cmd">' + esc(p.install) + "</span>" +
        '<button type="button" class="copy-btn inline" data-copy="' + esc(p.install) + '" aria-label="Copy install command">COPY</button></div></td>' +
        '<td class="ver">' + esc(p.version) + "</td>" +
        "<td>" + esc(p.description) + "</td>" +
        '<td class="cat">' + esc(p.category) + "</td></tr>"
      );
    }).join("");
    return (
      "<div class='table-scroll pkg-table'><table><thead><tr>" +
      "<th>Package (install)</th><th>Version</th><th>Description</th><th>Category</th>" +
      "</tr></thead><tbody>" + rows + "</tbody></table></div>"
    );
  }

  function buildHaystack(kind, item) {
    if (kind === "commands") {
      return [item.name, item.summary, item.syntax || "", (item.examples || []).join(" "), (item.args || []).join(" "), item.notes || ""].join(" ").toLowerCase();
    }
    if (kind === "modules") {
      // module-level haystack = name + title only. Matching these shows the
      // whole group; tool-level matches are handled per-tool in apply() so a
      // query like "opencode" shows just that tool, not the entire module.
      return [item.name, item.title].join(" ").toLowerCase();
    }
    return [item.name, item.description, item.category, item.install, item.version].join(" ").toLowerCase();
  }

  function buildToolHaystack(t) {
    return [t.name, t.blurb, t.category, t.install].join(" ").toLowerCase();
  }

  function initExplorer() {
    var root = $("[data-explorer]");
    if (!root) return;
    var kind = root.getAttribute("data-explorer");
    var url = "data/" + kind + ".json";
    var wrap = $(".explorer-wrap", root) || root;
    var input = $('[data-search="' + kind + '"]', root);
    var catSel = $('[data-cat="' + kind + '"]', root);
    var metaEl = $('[data-meta="' + kind + '"]', root);
    var clearBtn = $('[data-clear="' + kind + '"]', root);

    function updateMeta(count, total, empty) {
      if (metaEl) {
        if (empty && count === 0) {
          metaEl.textContent = "No results";
        } else {
          metaEl.textContent = count + " of " + total + " shown";
        }
      }
      if (clearBtn) clearBtn.hidden = !empty && !count;
    }

    fetch(url).then(function (r) { return r.json(); }).then(function (data) {
      var all = data;
      var state = { filter: "", cat: "all" };

      // category options are derived from the data (authoritative)
      if (catSel) {
        var catMap = {};
        all.forEach(function (item) {
          if (kind === "packages") {
            catMap[item.category] = (catMap[item.category] || 0) + 1;
          } else if (kind === "modules") {
            item.tools.forEach(function (t) {
              catMap[t.category] = (catMap[t.category] || 0) + 1;
            });
          }
        });
        Object.keys(catMap).sort().forEach(function (c) {
          var o = document.createElement("option");
          o.value = c;
          o.textContent = c + " (" + catMap[c] + ")";
          catSel.appendChild(o);
        });
      }

      all.forEach(function (item) {
        item._haystack = buildHaystack(kind, item);
        if (kind === "modules") {
          item.tools.forEach(function (t) { t._haystack = buildToolHaystack(t); });
        }
      });

      var totalCount = kind === "modules"
        ? all.reduce(function (n, m) { return n + m.tools.length; }, 0)
        : all.length;

      function apply() {
        var q = state.filter;
        var list, count;

        if (kind === "modules") {
          // Filter at the TOOL level: a query matches individual tools, not
          // whole modules. If the query matches the module itself, the whole
          // group is kept (minus any active category filter). A category
          // filter matches the tool's category, like the Packages explorer.
          list = all.map(function (m) {
            var matchedTools = m.tools.filter(function (t) {
              if (state.cat !== "all" && t.category !== state.cat) return false;
              if (q) {
                var s = scoreItem(t, q);
                if (!s) return false;
                t._score = s;
              } else {
                t._score = 0;
              }
              return true;
            });
            var moduleHits = q ? scoreItem(m, q) : 0;
            if (state.cat !== "all" && matchedTools.length === 0) return null;
            if (q && !moduleHits && matchedTools.length === 0) return null;
            m._score = moduleHits;
            return { m: m, tools: moduleHits
              ? m.tools.filter(function (t) { return state.cat === "all" || t.category === state.cat; })
              : matchedTools, score: moduleHits || 0 };
          }).filter(function (x) { return x; });
          list.sort(function (a, b) { return b.score - a.score; });
          count = list.reduce(function (n, x) { return n + x.tools.length; }, 0);
        } else {
          list = all.filter(function (item) {
            if (q) {
              var s = scoreItem(item, q);
              if (!s) return false;
              item._score = s;
            } else {
              item._score = 0;
            }
            if (kind === "packages" && state.cat !== "all" && item.category !== state.cat) return false;
            return true;
          });
          list.sort(function (a, b) { return (b._score || 0) - (a._score || 0); });
          count = list.length;
        }

        var html;
        if (kind === "commands") html = renderCommands(list);
        else if (kind === "modules") {
          html = list.map(function (x) { return renderModules([{ name: x.m.name, title: x.m.title, description: x.m.description, install: x.m.install, tools: x.tools }]); }).join("");
        }
        else html = renderPackages(list);

        if (count === 0) {
          wrap.innerHTML = "<div class='empty-state'>" +
            "<h3>No results found</h3>" +
            "<p>Nothing matches “" + esc(q) + "”" + (state.cat !== "all" ? " in category “" + esc(state.cat) + "”" : "") + ".</p>" +
            "<p>Try a different term, or <a href='#' data-reset='" + kind + "'>clear the filters</a>.</p></div>";
          updateMeta(0, totalCount, true);
        } else {
          wrap.innerHTML = html;
          updateMeta(count, totalCount, false);
        }
        var reset = $('[data-reset="' + kind + '"]', root);
        if (reset) {
          reset.addEventListener("click", function (e) {
            e.preventDefault();
            if (input) { input.value = ""; state.filter = ""; }
            if (catSel) { catSel.value = "all"; state.cat = "all"; }
            apply();
            if (input) input.focus();
          });
        }
        initCopy();
      }

      function onInput() {
        state.filter = input.value.trim().toLowerCase();
        apply();
      }

      if (input) {
        input.addEventListener("input", debounce(onInput, 100));
        input.addEventListener("keydown", function (e) {
          if (e.key === "Escape") {
            input.value = "";
            state.filter = "";
            apply();
          }
        });
      }
      if (clearBtn) {
        clearBtn.addEventListener("click", function () {
          if (input) { input.value = ""; state.filter = ""; }
          if (catSel) { catSel.value = "all"; state.cat = "all"; }
          apply();
          if (input) input.focus();
        });
      }
      if (catSel) {
        catSel.addEventListener("change", function () {
          state.cat = catSel.value;
          apply();
        });
      }

      apply();
      var initial = $(".explorer-init", root);
      if (initial) initial.remove();
    }).catch(function () {
      wrap.innerHTML = "<p class='warn'>Could not load " + url + ". Regenerate site data: python3 scripts/site/generate-data.py</p>";
    });
  }

  /* =========================================================
   * Global site search (search.html) — searches a generated
   * index (site/data/search.json) of commands, tools, packages,
   * and documentation sections.
   * ========================================================= */
  function initSiteSearch() {
    var host = $("[data-site-search]");
    if (!host) return;
    var input = $("input[type=search]", host);
    var resultsEl = $(".search-results", host);
    var metaEl = $(".search-meta", host);
    if (!input || !resultsEl) return;

    fetch("data/search.json").then(function (r) { return r.json(); }).then(function (index) {
      index.forEach(function (item) {
        item._hay = [item.title, item.kind, item.category || "", item.text || "", item.keywords || "", item.command || ""].join(" ").toLowerCase();
      });

      function run() {
        var q = input.value.trim().toLowerCase();
        if (!q) {
          resultsEl.innerHTML = "<p class='empty-state sm'>Type to search across commands, tools, packages, guides and docs.</p>";
          if (metaEl) metaEl.textContent = "";
          return;
        }
        var hits = index.filter(function (item) {
          return item._hay.indexOf(q) !== -1;
        }).map(function (item) {
          var s = item.title.toLowerCase();
          var sc = s === q ? 100 : (s.indexOf(q) === 0 ? 80 : 40);
          if ((item.command || "").toLowerCase().indexOf(q) !== -1) sc += 30;
          if ((item.keywords || "").toLowerCase().indexOf(q) !== -1) sc += 20;
          return { item: item, score: sc };
        }).sort(function (a, b) { return b.score - a.score; });

        if (hits.length === 0) {
          resultsEl.innerHTML = "<div class='empty-state'><h3>No results for “" + esc(q) + "”</h3>" +
            "<p>Try a tool name, command, package, or topic (e.g. <em>opencode</em>, <em>search</em>, <em>zaproxy</em>, <em>signing</em>).</p></div>";
          if (metaEl) metaEl.textContent = "No results";
          return;
        }

        var groups = {};
        hits.forEach(function (h) { (groups[h.item.kind] = groups[h.item.kind] || []).push(h); });

        var html = "<div class='search-meta'>" + hits.length + " result" + (hits.length === 1 ? "" : "s") + "</div>";
        var kindLabel = {
          command: "Commands",
          tool: "Tools",
          module: "Modules",
          package: "Packages",
          page: "Documentation",
        };
        Object.keys(groups).forEach(function (kind) {
          html += "<section class='search-group'><h2>" + (kindLabel[kind] || kind) + "</h2>";
          groups[kind].forEach(function (h) {
            var it = h.item;
            html += "<a class='search-hit' href='" + esc(it.url) + "'>" +
              "<span class='k'>" + esc(kindLabel[kind] || kind) + "</span>" +
              "<strong>" + esc(it.title) + "</strong>" +
              (it.command ? "<code>" + esc(it.command) + "</code>" : "") +
              "<p>" + esc(it.text) + "</p></a>";
          });
          html += "</section>";
        });
        resultsEl.innerHTML = html;
        if (metaEl) metaEl.textContent = hits.length + " of " + index.length + " indexed";
      }

      input.addEventListener("input", debounce(run, 120));
      input.addEventListener("keydown", function (e) {
        if (e.key === "Escape") { input.value = ""; run(); }
      });
      run();
    }).catch(function () {
      resultsEl.innerHTML = "<p class='warn'>Could not load the search index. Regenerate site data: python3 scripts/site/generate-data.py</p>";
    });
  }

  /* =========================================================
   * Meta stats on landing + footer year
   * ========================================================= */
  function initStats() {
    var host = $("[data-stats]");
    if (!host) return;
    fetch("data/meta.json").then(function (r) { return r.json(); }).then(function (m) {
      var map = { packages: m.package_count, tools: m.tool_count, categories: m.category_count, commands: m.command_count, version: m.version };
      $$("[data-stat]", host).forEach(function (el) {
        var k = el.getAttribute("data-stat");
        if (k in map) el.textContent = map[k];
      });
    }).catch(function () {});
  }

  function initYear() {
    var y = $("[data-year]");
    if (y) y.textContent = new Date().getFullYear();
  }

  document.addEventListener("DOMContentLoaded", function () {
    initNav();
    initCopy();
    initExplorer();
    initSiteSearch();
    initStats();
    initYear();
  });
})();
