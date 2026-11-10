// app/static/graficas.js
const PALETA = ["#0F6E56", "#5DCAA5", "#378ADD", "#BA7517", "#888780", "#D4537E", "#7F77DD"];

function periodosDe(anios) {
  if (!anios.length) return [];
  const min = anios[0];
  const max = anios[anios.length - 1];
  const lista = [{ texto: "Todo (" + min + "–" + max + ")", desde: min, hasta: max }];
  for (let d = Math.floor(min / 10) * 10; d <= max; d += 10) {
    const a = Math.max(d, min);
    const b = Math.min(d + 9, max);
    lista.push({ texto: a + "–" + b, desde: a, hasta: b });
  }
  return lista;
}

function dibujar(lienzo, g, tipo, desde, hasta) {
  let cats = g.categorias;
  let series = g.series;

  if (g.periodo) {
    const idx = [];
    cats.forEach(function (a, i) { if (a >= desde && a <= hasta) idx.push(i); });
    cats = idx.map(function (i) { return g.categorias[i]; });
    series = g.series.map(function (s) {
      return Object.assign({}, s, { valores: idx.map(function (i) { return s.valores[i]; }) });
    });
  }

  const config = { responsive: true, displaylogo: false };
  const base = {
    margin: { l: 70, r: 20, t: 10, b: 50 },
    paper_bgcolor: "white",
    plot_bgcolor: "white",
    font: { family: "system-ui, sans-serif" },
    showlegend: true,
    legend: { orientation: "h", y: -0.2 },
  };

  // Dona y torta: reparto del total entre categorías
  if (tipo === "dona" || tipo === "torta") {
    const totales = cats.map(function (_, i) {
      return series.reduce(function (s, x) { return s + x.valores[i]; }, 0);
    });
    const traza = {
      type: "pie", labels: cats, values: totales, sort: false,
      hole: tipo === "dona" ? 0.5 : 0,
      marker: { colors: PALETA }, textinfo: "percent",
    };
    Plotly.react(lienzo, [traza], Object.assign({}, base, { legend: { orientation: "v" } }), config);
    return;
  }

  const horizontal = tipo === "horizontales";
  const muchos = cats.length > 30;

  const trazas = series.map(function (s) {
    const comun = { name: s.nombre };
    if (tipo === "barras" || tipo === "apiladas" || horizontal) {
      return Object.assign(comun, {
        type: "bar",
        x: horizontal ? s.valores : cats,
        y: horizontal ? cats : s.valores,
        orientation: horizontal ? "h" : "v",
        marker: { color: s.color },
      });
    }
    if (tipo === "area") {
      return Object.assign(comun, {
        type: "scatter", mode: "lines", x: cats, y: s.valores,
        stackgroup: "uno", line: { color: s.color }, fillcolor: s.color + "88",
      });
    }
    return Object.assign(comun, {
      type: "scatter",
      mode: tipo === "puntos" ? "markers" : (muchos ? "lines" : "lines+markers"),
      x: cats, y: s.valores,
      line: { color: s.color },
      marker: { color: s.color, size: muchos ? 5 : 8 },
    });
  });

  const ejeCat = {
    title: g.eje_x,
    type: g.categorico ? "category" : "linear",
    dtick: (!g.categorico && cats.length <= 15) ? 1 : undefined,
    automargin: true,
  };
  const ejeVal = { title: g.eje_y, tickformat: ",d", gridcolor: "#e6ebe8" };

  const layout = Object.assign({}, base, {
    barmode: tipo === "apiladas" ? "stack" : "group",
    showlegend: series.length > 1,
  });

  if (horizontal) {
    layout.xaxis = ejeVal;
    layout.yaxis = { type: "category", autorange: "reversed", automargin: true };
  } else {
    layout.xaxis = ejeCat;
    layout.yaxis = ejeVal;
  }

  Plotly.react(lienzo, trazas, layout, config);
}

function iniciarGraficas(lista) {
  lista.forEach(function (g) {
    const caja = document.getElementById("g-" + g.id);
    if (!caja) return;
    const lienzo = caja.querySelector(".lienzo");
    const selT = caja.querySelector(".sel-tipo");
    const selP = caja.querySelector(".sel-periodo");

    g.tipos.forEach(function (t) { selT.add(new Option(t[1], t[0])); });
    selT.value = g.tipo_inicial;

    let periodos = [];
    if (selP) {
      periodos = periodosDe(g.categorias);
      periodos.forEach(function (p, i) { selP.add(new Option(p.texto, i)); });
    }

    function refrescar() {
      const p = selP ? periodos[selP.value] : {};
      dibujar(lienzo, g, selT.value, p.desde, p.hasta);
    }

    selT.addEventListener("change", refrescar);
    if (selP) selP.addEventListener("change", refrescar);
    refrescar();
  });
}